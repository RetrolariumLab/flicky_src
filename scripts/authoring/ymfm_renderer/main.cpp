// Standalone VGM-to-WAV renderer for the subset emitted by Flicky Sound Studio.

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <vector>

#include "ymfm_opn.h"

namespace {

constexpr uint32_t kVgmRate = 44100;

uint32_t read_u32(const std::vector<uint8_t> &data, size_t offset) {
    if (offset + 4 > data.size()) throw std::runtime_error("truncated VGM header");
    return uint32_t(data[offset]) | uint32_t(data[offset + 1]) << 8 |
           uint32_t(data[offset + 2]) << 16 | uint32_t(data[offset + 3]) << 24;
}

void put_u16(std::ofstream &output, uint16_t value) {
    output.put(char(value));
    output.put(char(value >> 8));
}

void put_u32(std::ofstream &output, uint32_t value) {
    output.put(char(value));
    output.put(char(value >> 8));
    output.put(char(value >> 16));
    output.put(char(value >> 24));
}

class Interface : public ymfm::ymfm_interface {};

class Psg {
public:
    void write(uint8_t data) {
        if (data & 0x80) {
            m_latch_channel = (data >> 5) & 3;
            m_latch_volume = (data & 0x10) != 0;
            if (m_latch_volume) {
                m_volume[m_latch_channel] = data & 15;
            } else if (m_latch_channel == 3) {
                m_noise = data & 7;
                m_lfsr = 0x8000;
            } else {
                m_period[m_latch_channel] =
                    (m_period[m_latch_channel] & 0x3F0) | (data & 15);
            }
        } else if (m_latch_volume) {
            m_volume[m_latch_channel] = data & 15;
        } else if (m_latch_channel == 3) {
            m_noise = data & 7;
            m_lfsr = 0x8000;
        } else {
            m_period[m_latch_channel] =
                (m_period[m_latch_channel] & 15) | ((data & 0x3F) << 4);
        }
    }

    int32_t generate(uint32_t chip_clock, uint32_t sample_rate) {
        m_clock_fraction += double(chip_clock) / (16.0 * sample_rate);
        while (m_clock_fraction >= 1.0) {
            m_clock_fraction -= 1.0;
            clock();
        }
        int32_t mixed = 0;
        for (int channel = 0; channel < 3; ++channel)
            if (m_tone_output[channel]) mixed += amplitude(m_volume[channel]);
        if (m_lfsr & 1) mixed += amplitude(m_volume[3]);
        return mixed;
    }

private:
    static int32_t amplitude(uint8_t attenuation) {
        static constexpr int16_t levels[16] = {
            4096, 3254, 2585, 2053, 1631, 1295, 1029, 817,
            649, 516, 410, 326, 259, 206, 164, 0,
        };
        return levels[attenuation & 15];
    }

    void clock() {
        for (int channel = 0; channel < 3; ++channel) {
            uint16_t period = std::max<uint16_t>(1, m_period[channel]);
            if (++m_counter[channel] >= period) {
                m_counter[channel] = 0;
                m_tone_output[channel] = !m_tone_output[channel];
            }
        }
        uint16_t noise_period = (m_noise & 3) == 3
            ? std::max<uint16_t>(1, m_period[2])
            : uint16_t(16 << (m_noise & 3));
        if (++m_noise_counter >= noise_period) {
            m_noise_counter = 0;
            uint16_t feedback = (m_noise & 4)
                ? ((m_lfsr ^ (m_lfsr >> 3)) & 1)
                : (m_lfsr & 1);
            m_lfsr = uint16_t((m_lfsr >> 1) | (feedback << 15));
        }
    }

    std::array<uint16_t, 3> m_period{{1, 1, 1}};
    std::array<uint16_t, 3> m_counter{{0, 0, 0}};
    std::array<bool, 3> m_tone_output{{false, false, false}};
    std::array<uint8_t, 4> m_volume{{15, 15, 15, 15}};
    uint8_t m_latch_channel = 0;
    bool m_latch_volume = false;
    uint8_t m_noise = 0;
    uint16_t m_lfsr = 0x8000;
    uint16_t m_noise_counter = 0;
    double m_clock_fraction = 0.0;
};

class Renderer {
public:
    Renderer(uint32_t ym_clock, uint32_t psg_clock)
        : m_chip(m_interface), m_ym_clock(ym_clock), m_psg_clock(psg_clock),
          m_output_rate(m_chip.sample_rate(ym_clock)) {
        if (!ym_clock || !m_output_rate) throw std::runtime_error("VGM has no YM2612 clock");
        m_chip.reset();
        for (int count = 0; count < 64; ++count) m_chip.generate(&m_chip_output);
    }

    void ym_write(uint8_t port, uint8_t address, uint8_t value) {
        m_chip.write(port ? 2 : 0, address);
        m_chip.write(port ? 3 : 1, value);
    }

    void psg_write(uint8_t value) { m_psg.write(value); }

    void wait(uint32_t vgm_samples) {
        m_vgm_position += vgm_samples;
        uint64_t target = m_vgm_position * m_output_rate / kVgmRate;
        while (m_frames < target) {
            m_chip.generate(&m_chip_output);
            int32_t psg = m_psg.generate(m_psg_clock, m_output_rate);
            m_pcm.push_back(m_chip_output.data[0] + psg);
            m_pcm.push_back(m_chip_output.data[1] + psg);
            ++m_frames;
        }
    }

    uint32_t output_rate() const { return m_output_rate; }
    const std::vector<int32_t> &pcm() const { return m_pcm; }

private:
    Interface m_interface;
    ymfm::ym2612 m_chip;
    ymfm::ym2612::output_data m_chip_output{};
    Psg m_psg;
    uint32_t m_ym_clock;
    uint32_t m_psg_clock;
    uint32_t m_output_rate;
    uint64_t m_vgm_position = 0;
    uint64_t m_frames = 0;
    std::vector<int32_t> m_pcm;
};

std::vector<uint8_t> read_file(const std::string &path) {
    std::ifstream input(path, std::ios::binary);
    if (!input) throw std::runtime_error("cannot open input VGM");
    return std::vector<uint8_t>(std::istreambuf_iterator<char>(input), {});
}

void write_wav(const std::string &path, uint32_t rate, const std::vector<int32_t> &source) {
    int64_t peak = 1;
    for (int32_t value : source) peak = std::max<int64_t>(peak, std::abs(int64_t(value)));
    std::vector<int16_t> pcm;
    pcm.reserve(source.size());
    for (int32_t value : source) pcm.push_back(int16_t(int64_t(value) * 28000 / peak));

    std::ofstream output(path, std::ios::binary);
    if (!output) throw std::runtime_error("cannot create output WAV");
    output.write("RIFF", 4);
    put_u32(output, 36 + uint32_t(pcm.size() * 2));
    output.write("WAVEfmt ", 8);
    put_u32(output, 16);
    put_u16(output, 1);
    put_u16(output, 2);
    put_u32(output, rate);
    put_u32(output, rate * 4);
    put_u16(output, 4);
    put_u16(output, 16);
    output.write("data", 4);
    put_u32(output, uint32_t(pcm.size() * 2));
    output.write(reinterpret_cast<const char *>(pcm.data()), std::streamsize(pcm.size() * 2));
    if (!output) throw std::runtime_error("failed while writing WAV");
}

void render_vgm(const std::vector<uint8_t> &data, Renderer &renderer) {
    if (data.size() < 0x100 || std::string(data.begin(), data.begin() + 4) != "Vgm ")
        throw std::runtime_error("input is not an uncompressed VGM file");
    uint32_t version = read_u32(data, 8);
    size_t cursor = version >= 0x150 ? 0x34 + read_u32(data, 0x34) : 0x40;
    while (cursor < data.size()) {
        uint8_t command = data[cursor++];
        if (command == 0x50) {
            if (cursor >= data.size()) throw std::runtime_error("truncated PSG write");
            renderer.psg_write(data[cursor++]);
        } else if (command == 0x52 || command == 0x53) {
            if (cursor + 2 > data.size()) throw std::runtime_error("truncated YM2612 write");
            uint8_t address = data[cursor++], value = data[cursor++];
            renderer.ym_write(command - 0x52, address, value);
        } else if (command == 0x61) {
            if (cursor + 2 > data.size()) throw std::runtime_error("truncated wait");
            uint32_t samples = data[cursor] | uint32_t(data[cursor + 1]) << 8;
            cursor += 2;
            renderer.wait(samples);
        } else if (command == 0x62) {
            renderer.wait(735);
        } else if (command == 0x63) {
            renderer.wait(882);
        } else if (command >= 0x70 && command <= 0x7F) {
            renderer.wait((command & 15) + 1);
        } else if (command == 0x66) {
            return;
        } else {
            throw std::runtime_error("unsupported VGM command " + std::to_string(command));
        }
    }
    throw std::runtime_error("VGM stream has no end command");
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3) {
        std::cerr << "usage: ymfm_renderer <input.vgm> <output.wav>\n";
        return 1;
    }
    try {
        std::vector<uint8_t> data = read_file(argv[1]);
        if (data.size() < 0x30) throw std::runtime_error("truncated VGM file");
        Renderer renderer(read_u32(data, 0x2C), read_u32(data, 0x0C));
        render_vgm(data, renderer);
        write_wav(argv[2], renderer.output_rate(), renderer.pcm());
        std::cout << "[OK] rendered " << renderer.pcm().size() / 2 << " stereo frames at "
                  << renderer.output_rate() << " Hz\n";
        return 0;
    } catch (const std::exception &error) {
        std::cerr << "[ERROR] " << error.what() << "\n";
        return 2;
    }
}
