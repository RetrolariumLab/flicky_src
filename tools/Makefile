# Makefile for building decompressor tools

CC = gcc
CFLAGS = -O2 -Wall
LDFLAGS =

TARGETS = nemesis_dec.exe enigma_dec.exe

all: $(TARGETS)

nemesis_dec.exe: nemesis_dec.c
	$(CC) $(CFLAGS) -DTEST_MAIN -o $@ $< $(LDFLAGS)

enigma_dec.exe: enigma_dec.c
	$(CC) $(CFLAGS) -DTEST_MAIN -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGETS)

.PHONY: all clean
