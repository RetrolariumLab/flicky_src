# Work RAM Fields

Every RAM address the 68000 side touches is named in `src/memory/ram.inc` and
referenced by symbol everywhere else; `make lint` rejects a raw address outside
that file. This page is the same list grouped by what it is for.

Addresses are the values the source uses. The Mega Drive mirrors work RAM
throughout `$FF0000`-`$FFFFFF`, so `$FFC000` and `$FF0000+$C000` are the same
byte.


## Z80 sound RAM

| Symbol | Address |
| --- | --- |
| `Z80_RAM` | `$A00000` |
| `Z80_CommandBlock` | `$A01C04` |
| `Z80_MusicCommand` | `$A01C09` |
| `Z80_SFXSlot0` | `$A01C0A` |
| `Z80_SFXSlot1` | `$A01C0B` |
| `Z80_SFXSlot2` | `$A01C0C` |
| `Z80_PauseFlag` | `$A01C10` |
| `Z80_YM2612` | `$A04000` |


## Object array

Thirty-two 64-byte object slots start at `Ram_ObjectSlots`. A
slot's fields are reached as offsets from `a0`, so only the slot bases and the
few fields other code reads directly are named here. The player lives in slot
17 at `$FFC440`.

| Symbol | Address |
| --- | --- |
| `M68K_RAM` | `$FF0000` |
| `Ram_ObjectSlots` | `$FFC000` |
| `Ram_Object01` | `$FFC040` |
| `Ram_Object01_State` | `$FFC07C` |
| `Ram_BonusChickSlots` | `$FFC080` |
| `Ram_PopupSlots` | `$FFC0C0` |
| `Ram_TitleStaticSlots` | `$FFC140` |
| `Ram_SpawnerSlots` | `$FFC200` |
| `Ram_ProjectileSlots` | `$FFC380` |
| `Ram_EnemySlot0_GridPos` | `$FFC3BE` |
| `Ram_EnemySlot1` | `$FFC3C0` |
| `Ram_EnigmaBuffer` | `$FFC3E0` |
| `Ram_EnemySlot1_GridPos` | `$FFC3FE` |
| `Ram_EnemySlot2` | `$FFC400` |
| `Ram_EnemySlot2_GridPos` | `$FFC43E` |
| `Ram_PlayerObject` | `$FFC440` |
| `Ram_PlayerScreenX` | `$FFC460` |
| `Ram_PlayerVelocityY` | `$FFC46C` |
| `Ram_PlayerWorldX` | `$FFC470` |
| `Ram_PlayerState` | `$FFC47C` |
| `Ram_PlayerGridPos` | `$FFC47E` |
| `Ram_ChickSlots` | `$FFC480` |
| `Ram_BonusPlayerObject` | `$FFC580` |
| `Ram_BonusPlayerWorldX` | `$FFC5B0` |
| `Ram_BonusTigerSlots` | `$FFC5C0` |
| `Ram_BonusSeesawSlots` | `$FFC640` |
| `Ram_EnemySlot3` | `$FFC680` |
| `Ram_EnemySlot3_GridPos` | `$FFC6BE` |
| `Ram_EnemySlot4` | `$FFC6C0` |
| `Ram_EnemySlot4_GridPos` | `$FFC6FE` |
| `Ram_EnemySlot5` | `$FFC700` |
| `Ram_EnemySlot5_GridPos` | `$FFC73E` |
| `Ram_TigerRespawnSlot` | `$FFC740` |
| `Ram_IggyRespawnSlot` | `$FFC7C0` |


## Collision map

A 32-column grid of one byte per cell. The low nibble is the
tile type; bits 5, 6 and 7 are the special flags `Collision_SetSpecialTiles`
writes.

| Symbol | Address |
| --- | --- |
| `Ram_CollisionMap` | `$FFC800` |
| `Ram_CollisionMapRow1` | `$FFC840` |
| `Ram_CollisionMapBonusRow` | `$FFCAA0` |
| `Ram_CollisionMapLastRow` | `$FFCB20` |
| `Ram_CollisionMapEnd` | `$FFCB40` |


## Score

| Symbol | Address |
| --- | --- |
| `Ram_HighScore` | `$FFCC00` |


## Gameplay state

| Symbol | Address |
| --- | --- |
| `Ram_SpriteTableCursor` | `$FFD000` |
| `Ram_SpriteLinkCounter` | `$FFD002` |
| `Ram_CameraVelocityX` | `$FFD004` |
| `Ram_CameraVelocityY` | `$FFD008` |
| `Ram_PaletteDirty` | `$FFD00C` |
| `Ram_LeadingDigitSeen` | `$FFD00D` |
| `Ram_PlayerTrailX` | `$FFD00E` |
| `Ram_PlayerTrailY` | `$FFD012` |
| `Ram_PlayerTrailXLast` | `$FFD1FE` |
| `Ram_PlayerTrailYLast` | `$FFD202` |
| `Ram_PlayerTrailXShift` | `$FFD206` |
| `Ram_PlayerTrailYShift` | `$FFD20A` |
| `Ram_PlayerTrailFlags` | `$FFD20E` |
| `Ram_PlayerTrailFlagsLast` | `$FFD24D` |
| `Ram_BonusRoundFlag` | `$FFD24E` |
| `Ram_RoundEndingFlag` | `$FFD24F` |
| `Ram_HeldItemObject` | `$FFD250` |
| `Ram_UIAnimState` | `$FFD254` |
| `Ram_ArrowAnimState` | `$FFD258` |
| `Ram_ExitDoorY` | `$FFD25C` |
| `Ram_ExitDoorLeftX` | `$FFD25E` |
| `Ram_ExitDoorRightX` | `$FFD260` |
| `Ram_ScoreDelta` | `$FFD262` |
| `Ram_RoundMinutes` | `$FFD266` |
| `Ram_RoundSeconds` | `$FFD267` |
| `Ram_TimeBonus` | `$FFD268` |
| `Ram_ActiveEnemyCount` | `$FFD26C` |
| `Ram_PlayerHitFlag` | `$FFD26D` |
| `Ram_TigerJumpVelX` | `$FFD26E` |
| `Ram_TigerJumpVelY` | `$FFD272` |
| `Ram_TigerJumpSpeed` | `$FFD276` |
| `Ram_ChickChainCount` | `$FFD27A` |
| `Ram_CutsceneFlag` | `$FFD27B` |
| `Ram_IggySpeed` | `$FFD27C` |
| `Ram_BlinkTimer` | `$FFD280` |
| `Ram_RoundClearFlag` | `$FFD281` |
| `Ram_BonusChickDelayPtr` | `$FFD282` |
| `Ram_BonusChickVelocityPtr` | `$FFD286` |
| `Ram_BonusChickTrajPtr` | `$FFD28A` |
| `Ram_BonusCaughtCount` | `$FFD28E` |
| `Ram_BonusCaughtBCD` | `$FFD28F` |
| `Ram_BonusScore` | `$FFD290` |
| `Ram_SpawnerDelay` | `$FFD294` |
| `Ram_TigerSpeed` | `$FFD296` |
| `Ram_ShowLeadingZeros` | `$FFD29A` |
| `Ram_CreditsLine` | `$FFD29C` |
| `Ram_CreditsScrollTimer` | `$FFD29D` |
| `Ram_EndingState` | `$FFD29E` |
| `Ram_GameState` | `$FFD2A0` |
| `Ram_SoundCooldown` | `$FFD2A2` |
| `Ram_SoundBusyFlag` | `$FFD2A4` |
| `Ram_DemoModeFlag` | `$FFD2A5` |
| `Ram_BonusState` | `$FFD2A6` |
| `Ram_DemoInputByte` | `$FFD2A8` |
| `Ram_DemoStreamPtr` | `$FFD2AA` |
| `Ram_DemoHoldFrames` | `$FFD2AC` |


## Level appearance and progress

| Symbol | Address |
| --- | --- |
| `Ram_GroundTilePtr` | `$FFD800` |
| `Ram_BackgroundTilePtr` | `$FFD804` |
| `Ram_UpperGroundPtr` | `$FFD808` |
| `Ram_LowerGroundPtr` | `$FFD80C` |
| `Ram_BgObject3Ptr` | `$FFD810` |
| `Ram_BgObject4Ptr` | `$FFD814` |
| `Ram_BgObject5Ptr` | `$FFD818` |
| `Ram_BgObject0Ptr` | `$FFD81C` |
| `Ram_BgObject1Ptr` | `$FFD820` |
| `Ram_BgObject2Ptr` | `$FFD824` |
| `Ram_ThrowableMappingPtr` | `$FFD828` |
| `Ram_RoundNumber` | `$FFD82C` |
| `Ram_PlayerStartX` | `$FFD82E` |
| `Ram_PlayerStartY` | `$FFD82F` |
| `Ram_EntryArrowPos` | `$FFD830` |
| `Ram_BackgroundObject1Pos` | `$FFD832` |
| `Ram_WindowGirlGridX` | `$FFD834` |
| `Ram_WindowGirlGridY` | `$FFD835` |
| `Ram_Score` | `$FFD87E` |
| `Ram_Lives` | `$FFD882` |
| `Ram_ChicksRemaining` | `$FFD883` |
| `Ram_TextTileBase` | `$FFD884` |
| `Ram_RestoreEnemiesFlag` | `$FFD886` |
| `Ram_ExtraLifeFlags` | `$FFD887` |
| `Ram_RoundTime` | `$FFD888` |
| `Ram_BonusAwardCount` | `$FFD88C` |
| `Ram_ExitReachedFlag` | `$FFD88D` |
| `Ram_FontBankFlag` | `$FFD88E` |
| `Ram_SkipBonusFlag` | `$FFD88F` |
| `Ram_DemoIndex` | `$FFD890` |


## Buffers

| Symbol | Address |
| --- | --- |
| `Ram_EnemyBackup` | `$FFDE00` |
| `Ram_DecompCodeTable` | `$FFE630` |
| `Ram_RandomCount` | `$FFE632` |
| `Ram_RandomDivisor` | `$FFE634` |


## Sprite and palette buffers

| Symbol | Address |
| --- | --- |
| `Ram_SpriteTable` | `$FFF550` |
| `Ram_Palette` | `$FFF7E0` |
| `Ram_PaletteEntry2` | `$FFF7E4` |
| `Ram_PaletteEntry3` | `$FFF7E6` |
| `Ram_LevelPalette` | `$FFF800` |
| `Ram_BonusPaletteEntry` | `$FFF82E` |
| `Ram_TitlePaletteSlot` | `$FFF840` |
| `Ram_AccentPaletteSlot` | `$FFF858` |
| `Ram_PaletteBackup` | `$FFF860` |


## RAM-resident jump table

`Sys_LoadFuncTable` builds this block at boot by writing
one `jmp <target>` every six bytes, taking the targets from `Sys_FuncTable` in
`src/data/bank0.s`. Calling through it is how the game reaches the routines in
the first 64 KiB after the code has been copied to RAM.

| Symbol | Address |
| --- | --- |
| `EXT` | `$FFFA70` |
| `HBLANK` | `$FFFA76` |
| `VBLANK` | `$FFFA7C` |
| `Ram_VBlankVector` | `$FFFA7E` |
| `j_Nem_Decomp` | `$FFFA82` |
| `j_Nem_DecompSetup` | `$FFFA8E` |
| `j_Gfx_CopyToCRAM` | `$FFFAC4` |
| `j_Gfx_CopyToVRAM` | `$FFFACA` |
| `j_Gfx_FillVRAMZero` | `$FFFAD6` |
| `j_Gfx_ApplyPaletteMask` | `$FFFB0C` |
| `j_Input_ProcessJoypads` | `$FFFB12` |
| `j_LoadZ80Driver` | `$FFFB30` |
| `j_Sound_RequestZ80Bus` | `$FFFB36` |
| `j_ReleaseZ80Bus` | `$FFFB3C` |
| `j_Sound_CopyToZ80RAM` | `$FFFB54` |
| `j_Sound_QueueToBuffer` | `$FFFB66` |
| `j_Sound_QueueSFX` | `$FFFB6C` |
| `j_Gfx_SetTileWriteAddr` | `$FFFB8A` |
| `j_Gfx_FadePalette` | `$FFFBA8` |
| `j_Sys_InitGameState` | `$FFFBB4` |
| `j_Gfx_LoadPaletteCompact` | `$FFFBBA` |


## System state

| Symbol | Address |
| --- | --- |
| `Ram_VDPRegisters` | `$FFFF70` |
| `Ram_VDPMode2` | `$FFFF71` |
| `Ram_ButtonStates` | `$FFFF83` |
| `Ram_ButtonRepeatFlag` | `$FFFF86` |
| `Ram_ButtonRepeatEnable` | `$FFFF87` |
| `Ram_Joypad` | `$FFFF8E` |
| `Ram_FrameCounter` | `$FFFF92` |
| `Ram_VBlankRequest` | `$FFFF96` |
| `Ram_VBlankMode` | `$FFFF98` |
| `Ram_SoundQueueCount` | `$FFFFA2` |
| `Ram_CameraY` | `$FFFFA4` |
| `Ram_CameraX` | `$FFFFA8` |
| `Ram_FadeLevel` | `$FFFFAC` |
| `Ram_DMACommandLow` | `$FFFFAE` |
| `Ram_PaletteMaskHigh` | `$FFFFB8` |
| `Ram_PaletteMaskLow` | `$FFFFBC` |
| `Ram_NextGameMode` | `$FFFFC0` |
| `Ram_GameModeSpare1` | `$FFFFC2` |
| `Ram_GameModeSpare2` | `$FFFFC4` |
| `Ram_Z80BusHeld` | `$FFFFC8` |
| `Ram_RandomSeed` | `$FFFFCA` |
| `Ram_VDPPlaneAddrs` | `$FFFFD8` |
| `Ram_HScrollAddr` | `$FFFFDA` |
| `Ram_TilemapRowStride` | `$FFFFE2` |
| `Ram_TilemapGradientBase` | `$FFFFE4` |
| `Ram_InitFlag` | `$FFFFFC` |

## Fields with an observed encoding

Six of these are asserted by name in `scenarios/runtime_scenarios.json` and
checked against replays of the two recorded movies, so their contents are
observed rather than inferred. Three carry an encoding worth stating here;
[`runtime_evidence.md`](runtime_evidence.md) has the full tables and the values
each scenario saw.

| Symbol | Encoding |
| --- | --- |
| `Ram_NextGameMode` | Byte offset into `Sys_GameModeTable`, whose entries are `bra.w`, so it steps by four: `$04` `Title_Update`, `$24` `Game_MainLoop`, `$2C` `Bonus_MainLoop`, `$34` `Ending_MainLoop`, `$44` `Sys_ModeSegaScreen` |
| `Ram_GameState` | The same, one level down, into `Game_StateTable` under `andi.w #$7FFC`. Bit 15 latches that the state's entry code has run, so play reads `$0000` and the round-complete screen `$8004` |
| `Ram_RoundNumber` | The round twice over: high byte the BCD the HUD prints, low byte the plain index the code counts with. Round 26 is `$261A`; `Demo_Init` writes the pair from `Demo_RoundDisplayTable` and `Demo_RoundIndexTable` |

`Ram_InitFlag` is the useful landmark when reading a state dump by hand: the
boot code writes the ASCII `init` there, which makes it the cheapest check that
a reader has the byte order right.
