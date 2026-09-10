FROM ubuntu:22.04 AS builder

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        g++-mingw-w64-i686 \
    && update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . /src
RUN i686-w64-mingw32-g++ -std=c++14 -O2 -static -static-libgcc -static-libstdc++ \
    -Wl,--no-insert-timestamp \
    -Ithird_party/ymfm/src \
    scripts/authoring/ymfm_renderer/main.cpp \
    third_party/ymfm/src/ymfm_opn.cpp \
    third_party/ymfm/src/ymfm_ssg.cpp \
    third_party/ymfm/src/ymfm_adpcm.cpp \
    -o /ymfm_renderer.exe

FROM scratch AS artifact
COPY --from=builder /ymfm_renderer.exe /ymfm_renderer.exe
