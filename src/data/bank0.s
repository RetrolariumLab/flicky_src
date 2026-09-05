; First Z80 driver image, function table, Japanese 1bpp font.
; ROM $001316-$00FFFF.

z80_part1:      binclude "data/sound/data_z80_part1.bin"
z80_part1_End:
func_table:     dc.w    $39
                dc.w    Int_UnusedHandler
                dc.w    Int_UnusedHandler
                dc.w    Int_UnusedHandler
                dc.w    Nem_Decomp
                dc.w    Nem_Decomp_To_RAM
                dc.w    Nem_DecompSetup
                dc.w    Nem_DecompToRAM
                dc.w    Nem_GetCodeWord
                dc.w    Nem_GetBits
                dc.w    Nem_GetBitsShift
                dc.w    Nem_PCD_InlineData
                dc.w    Nem_BitShift
                dc.w    Nem_FlushBits
                dc.w    Eni_Decompress
                dc.w    Gfx_CopyToCRAM
                dc.w    Gfx_CopyToVRAM
                dc.w    Gfx_InitTilemapGradient
                dc.w    Gfx_FillVRAMZero
                dc.w    Gfx_FillVRAMValue
                dc.w    DMA_WaitComplete
                dc.w    DMA_FillVRAMSetup
                dc.w    loc_900
                dc.w    DMA_CopyCheck
                dc.w    DMA_ToCRAM
                dc.w    DMA_ToVRAMCheck
                dc.w    Gfx_VBlankScrollUpdate
                dc.w    Gfx_ApplyPaletteMask
                dc.w    Input_ProcessJoypads
                dc.w    InitJoypads
                dc.w    SetInitialVDPRegs
                dc.w    Gfx_WriteVDPRegs
                dc.w    Gfx_ClearSpriteArea
                dc.w    LoadZ80Driver
                dc.w    Sound_RequestZ80Bus
                dc.w    ReleaseZ80Bus
                dc.w    RequestZ80Bus
                dc.w    Sound_ReleaseZ80Check
                dc.w    Sound_ResetZ80
                dc.w    Sound_CopyToZ80RAM
                dc.w    Sound_ClearZ80RAM
                dc.w    Sound_SendZ80Command
                dc.w    Sound_QueueToBuffer
                dc.w    Sound_QueueSFX
                dc.w    Sys_WaitVBlank
                dc.w    RandomNumber
                dc.w    Gfx_WriteTilemapBlock
                dc.w    Gfx_FillTilemapArea
                dc.w    Gfx_SetTileWriteAddr
                dc.w    Gfx_SetVRAMWriteAddr
                dc.w    Gfx_TileToVDPCmd
                dc.w    loc_F2A
                dc.w    Sound_CheckPlaying
                dc.w    Gfx_FadePalette
                dc.w    Gfx_BackupPalette
                dc.w    Sys_InitGameState
                dc.w    Gfx_LoadPaletteCompact
                dc.w    Gfx_DecompEnigmaTilemap
                dc.w    Gfx_LoadFullTilemap
Jap1BPPTiles:   binclude "data/artunc/data_Jap1BPPTiles.bin"
Jap1BPPTiles_End:
empty_block_1:  ; dc.b [$D6F6]$FF
                org     $10000
; Main game entry point after Sega screen
