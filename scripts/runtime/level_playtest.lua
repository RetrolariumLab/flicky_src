-- Boot the editable ROM directly into a selected Flicky round.

local function setting(name, minimum, maximum)
    local value = tonumber(os.getenv(name) or "")
    if value == nil or value < minimum or value > maximum then
        error(name .. " must be in range " .. minimum .. ".." .. maximum)
    end
    return value
end

local round = setting("FLICKY_PLAYTEST_ROUND", 1, 48)
local exit_when_ready = os.getenv("FLICKY_PLAYTEST_EXIT") == "1"
local result_path = os.getenv("FLICKY_PLAYTEST_RESULT")
local bcd_round = math.floor(round / 10) * 16 + (round % 10)
local round_word = bcd_round * 256 + round

local ram = {
    lives = 0xFFD882,
    game_state = 0xFFD2A0,
    round_number = 0xFFD82C,
    skip_bonus = 0xFFD88F,
    next_game_mode = 0xFFFFC0,
}

local function write_result(status, frame)
    if result_path == nil or result_path == "" then
        return
    end
    local result = assert(io.open(result_path, "w"))
    result:write(string.format(
        "status=%s round=%d round_word=%04X mode=%02X game_state=%04X lives=%d frame=%d\n",
        status,
        round,
        memory.readword(ram.round_number),
        memory.readword(ram.next_game_mode),
        memory.readword(ram.game_state),
        memory.readbyte(ram.lives),
        frame
    ))
    result:close()
end

local selected = false
local ready = false
local last_frame = 0
for frame = 1, 1200 do
    last_frame = frame
    local mode = memory.readword(ram.next_game_mode)
    if not selected then
        if mode == 0x44 then
            -- The global boot and tile upload are complete; skip the Sega timer.
            memory.writeword(ram.next_game_mode, 0)
        elseif mode == 0x04
                and memory.readword(ram.round_number) == 0x0101
                and memory.readbyte(ram.lives) == 3
                and memory.readbyte(ram.skip_bonus) == 1 then
            -- Title_Init has finished establishing the regular new-game defaults.
            memory.writeword(ram.round_number, round_word)
            memory.writebyte(ram.lives, 3)
            memory.writebyte(ram.skip_bonus, 1)
            memory.writeword(ram.next_game_mode, 0x18)
            selected = true
        end
    elseif mode == 0x24 then
        ready = memory.readword(ram.round_number) == round_word
        if ready then
            write_result("ready", frame)
            break
        end
    end
    gens.frameadvance()
end

if not ready then
    write_result("timeout", last_frame)
    if exit_when_ready then
        os.exit(1)
    end
    error("Flicky playtest did not reach the selected round")
end

if exit_when_ready then
    os.exit(0)
end
