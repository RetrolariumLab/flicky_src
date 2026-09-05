; Trailing data tables and the ROM tail.
; ROM $01A196-$01FFFF.

Level_BackgroundTileData0: dc.b    $22, 0  ; was: byte_1A196
Level_BackgroundTileData1: dc.b    $22, 1  ; was: byte_1A198
Level_BackgroundTileData2: dc.b    $22, 2  ; was: byte_1A19A
Level_BackgroundTileData3: dc.b    $22, 3  ; was: byte_1A19C
Level_BackgroundTileData4: dc.b    $22, 4  ; was: byte_1A19E
Level_BackgroundTileData5: dc.b    0, 0  ; was: byte_1A1A0
Level_UpperGroundData0: dc.w    $222B, $222C, $222D, $222E, $222F, $2230, $2231, $2232  ; was: word_1A1A2
Level_UpperGroundData1: dc.w    $2233, $2234, $2235, $2236, $2237, $2238, $2239, $223A  ; was: word_1A1B2
Level_UpperGroundData2: dc.w    $223B, $223C, $223D, $223E, $223F, $2240, $2241, $2242  ; was: word_1A1C2
Level_UpperGroundData3: dc.w    $2243, $2244, $2245, $2246, $2247, $2248, $2249, $224A  ; was: word_1A1D2
Level_UpperGroundData4: dc.w    $224B, $224C, $224D, $224E, $224F, $2250, $2251, $2252  ; was: word_1A1E2
Level_UpperGroundData5: dc.w    $2253, $2205, $2205, $2205, $2254, $2255, $2256, $2257  ; was: word_1A1F2
Level_LowerGroundData0: dc.w    $2258, $2258, $2258, $2258, $2258, $2258, $2258, $2258  ; was: word_1A202
Level_LowerGroundData1: dc.w    $2259, $225A, $225B, $225C, $225D, $225E, $225F, $2260  ; was: word_1A212
Level_LowerGroundData2: dc.w    $2261, $2262, $2263, $2264, $2265, $2240, $2241, $2266  ; was: word_1A222
Level_LowerGroundData3: dc.w    $2267, $2268, $2269, $226A, $226B, $226C, $226D, $226E  ; was: word_1A232
Level_LowerGroundData4: dc.w    $226F, $2270, $2271, $2272, $2273, $2274, $2275, $2276  ; was: word_1A242
Level_LowerGroundData5: dc.w    $2277, $2277, $2277, $2277, $2278, $2279, $227A, $227B  ; was: word_1A252
UI_EntryArrowData0: dc.w    $29E, $29F, $2A0  ; was: word_1A262
UI_EntryArrowData2: dc.w    $2A1, $2A2, $2A3  ; was: word_1A268
UI_EntryArrowData1: dc.w    $2A4, $2A5, $2A6  ; was: word_1A26E
Level_BgObject0Data: dc.w    $62A7, $62A8, $62A9, $62AA, $62AB, $62AC, $62AD, $62AE, $62AF  ; was: word_1A274
Level_BgObject2Data: dc.w    $62B0, $62B1, $62B2, $62B3, $62B4, $62B5  ; was: word_1A286
Level_BgObject1Data: dc.w    $629A, $629B, $629C, $629D  ; was: word_1A292
Level_BgObject3Data0: dc.w    $627C, $627D, $627E, $627F, $6280, $6281  ; was: word_1A29A
Level_BgObject3Data1: dc.w    $6282, $6283, $6284, $6285, $6286, $6287  ; was: word_1A2A6
Level_BgObject3Data2: dc.w    $6288, $6289, $628A, $628B, $628C, $628D  ; was: word_1A2B2
Level_BgObject3Data3: dc.w    $628E, $628F, $6290, $6291, $6292, $6293  ; was: word_1A2BE
Level_BgObject3Data4: dc.w    $6294, $6295, $6296, $6297, $6298, $6299  ; was: word_1A2CA
Level_GroundTileData0: dc.w    $2200, $2215, $2216, $2217, $2218, $2217, $2216, $2217  ; was: word_1A2D6
Level_GroundTileData1: dc.w    $2201, $2219, $221A, $221B, $221C, $221B, $221A, $221B  ; was: word_1A2E6
Level_GroundTileData2: dc.w    $2202, $221D, $221E, $221F, $2220, $221F, $221E, $221F  ; was: word_1A2F6
Level_GroundTileData3: dc.w    $2203, $2221, $2222, $2223, $2224, $2223, $2222, $2223  ; was: word_1A306
Level_GroundTileData4: dc.w    $2204, $2225, $2226, $2227, $2228, $2227, $2226, $2227  ; was: word_1A316
Level_GroundTileData5: dc.w    $2205, $2229, $2205, $2205, $222A, $2205, $2205, $2205  ; was: word_1A326
Ending_GraphicsMap1: dc.w    $2B6, $2B7, $2B8, $2B9, $2BA, $2BB, $2BC, $2BD  ; was: word_1A336
                dc.w    $2BE, $2BF, $2C0, $2C1, $2C2, $2C3, $2C4
Ending_GraphicsMap0: dc.w    $2C5, $2C6, $2C7, $205, $2C8, $2C9, $2CA, $2CB  ; was: word_1A354
                dc.w    $2CC, $2CD, $2CE, $2CF, $2D0, $2D1, $2D2, $2D3
Ending_GraphicsMap2: dc.w    $205, $205, $2D4, $2D5, $2D6, $2D7, $2D8, $2D9  ; was: word_1A374
                dc.w    $2DA, $2DB, $2DC, $2DD, $2DE, $205, $205
Level_BgObject5Data1: dc.w    $2DF, $2E0, $2E1, $205, $2E2, $2E3, $2E4, $205  ; was: word_1A392
                dc.w    $2E5, $2E6, $2E7, $205, $205, $205, $205, $205
Level_BgObject5Data2: dc.w    $2E8, $2E9, $2EA, $205, $2EB, $2EC, $2ED, $205  ; was: word_1A3B2
                dc.w    $2EE, $2EF, $2F0, $205, $205, $205, $205, $205
Level_BgObject4Data2: dc.w    $2F1, $2F2, $2F3, $2F4, $2F5, $2F6, $2F7, $2F8  ; was: word_1A3D2
                dc.w    $2F9, $2FA, $205, $205, $205, $205, $205
Level_BgObject5Data3: dc.w    $2FB, $2FC, $2FD, $2FE, $2FF, $300, $301, $302  ; was: word_1A3F0
                dc.w    $303, $304, $305, $306, $307, $308, $309, $30A
Level_BgObject4Data4: dc.w    $30B, $30C, $30D, $30E, $30F, $310, $311, $312  ; was: word_1A410
                dc.w    $313, $314, $315, $316, $317, $318, $319
Level_BgObject5Data4: dc.w    $31A, $31B, $31C, $31D, $31E, $31F, $320, $321  ; was: word_1A42E
                dc.w    $322, $323, $324, $325, $326, $327, $328, $329
Level_BgObject4Data3: dc.w    $32A, $32A, $32A, 0, 0, 0, $32A, $32A  ; was: word_1A44E
                dc.w    $32A, $32A, $32A, $32A, $32A, $32A, 0
UI_TimerData1:  dc.w    $632B, $632C, $632D, $632E, $632F, $6330, $6331, $6332, $6333  ; was: word_1A46C
UI_TimerData2:  dc.w    $6334, $6335, $6336, $6337, $6335, $6338, $6339, $6335, $633A  ; was: word_1A47E
UI_TimerData0:  dc.w    $633B, $6205, $633C, $633D, $6205, $633E, $633F, $6205, $6340  ; was: word_1A490
UI_CatCountReverseData3: dc.w    $6341, $6205, $6342, $6343, $6205, $6344, $6345, $6205, $6346  ; was: word_1A4A2
Level_DrawCatDoorData: dc.w    $347, $348, $349, $34A, $34B, $34C, $34D, $34E, $34F, $351, $4350  ; was: word_1A4B4
UI_Draw1UPAndHILabelsData0: dc.w    $8352, $8353, $8354, $8353  ; was: word_1A4CA
UI_Draw1UPAndHILabelsData1: dc.w    $8355, $8356, $8353, 0, 0, $2A, $F8, 0, 0, $300, $F8  ; was: word_1A4D2
Chick_ThrownAnim0Data0: dc.w    4, $F804, $6456, $F8F8  ; was: word_1A4E8
Chick_ThrownAnim0Data3: dc.w    4, $F804, $7456, $F8F8  ; was: word_1A4F0
Chick_ThrownAnim0Data1: dc.w    4, $F401, $6458, $FCFC  ; was: word_1A4F8
Chick_ThrownAnim0Data5: dc.w    4, $F401, $6C58, $FCFC  ; was: word_1A500
Chick_ThrownAnim0Data2: dc.w    4, $F401, $7458, $FCFC  ; was: word_1A508
Chick_ThrownAnim0Data4: dc.w    4, $F401, $7C58, $FCFC  ; was: word_1A510
Chick_ThrownAnim1Data0: dc.w    4, $F804, $645A, $F8F8  ; was: word_1A518
Chick_ThrownAnim1Data3: dc.w    4, $F804, $745A, $F8F8  ; was: word_1A520
Chick_ThrownAnim1Data1: dc.w    4, $F401, $645C, $FCFC  ; was: word_1A528
Chick_ThrownAnim1Data5: dc.w    4, $F401, $6C5C, $FCFC  ; was: word_1A530
Chick_ThrownAnim1Data2: dc.w    4, $F401, $745C, $FCFC  ; was: word_1A538
Chick_ThrownAnim1Data4: dc.w    4, $F401, $7C5C, $FCFC  ; was: word_1A540
Chick_ThrownAnim2Data0: dc.w    4, $F804, $645E, $F8F8  ; was: word_1A548
Chick_ThrownAnim2Data3: dc.w    4, $F804, $745E, $F8F8  ; was: word_1A550
Chick_ThrownAnim2Data1: dc.w    4, $F401, $6460, $FCFC  ; was: word_1A558
Chick_ThrownAnim2Data5: dc.w    4, $F401, $6C60, $FCFC  ; was: word_1A560
Chick_ThrownAnim2Data2: dc.w    4, $F401, $7460, $FCFC  ; was: word_1A568
Chick_ThrownAnim2Data4: dc.w    4, $F401, $7C60, $FCFC  ; was: word_1A570
Chick_ThrownAnim3Data0: dc.w    4, $F804, $6462, $F8F8  ; was: word_1A578
Chick_ThrownAnim3Data3: dc.w    4, $F804, $7462, $F8F8  ; was: word_1A580
Chick_ThrownAnim3Data1: dc.w    4, $F401, $6464, $FCFC  ; was: word_1A588
Chick_ThrownAnim3Data5: dc.w    4, $F401, $6C64, $FCFC  ; was: word_1A590
Chick_ThrownAnim3Data2: dc.w    4, $F401, $7464, $FCFC  ; was: word_1A598
Chick_ThrownAnim3Data4: dc.w    4, $F401, $7C64, $FCFC  ; was: word_1A5A0
Chick_ThrownAnim4Data0: dc.w    4, $F804, $6466, $F8F8  ; was: word_1A5A8
Chick_ThrownAnim4Data3: dc.w    4, $F804, $7466, $F8F8  ; was: word_1A5B0
Chick_ThrownAnim4Data1: dc.w    4, $F401, $6468, $FCFC  ; was: word_1A5B8
Chick_ThrownAnim4Data5: dc.w    4, $F401, $6C68, $FCFC  ; was: word_1A5C0
Chick_ThrownAnim4Data2: dc.w    4, $F401, $7468, $FCFC  ; was: word_1A5C8
Chick_ThrownAnim4Data4: dc.w    4, $F401, $7C68, $FCFC  ; was: word_1A5D0
Chick_ThrownAnim5Data0: dc.w    4, $F804, $646A, $F8F8  ; was: word_1A5D8
Chick_ThrownAnim5Data3: dc.w    4, $F804, $746A, $F8F8  ; was: word_1A5E0
Chick_ThrownAnim5Data1: dc.w    4, $F401, $646C, $FCFC  ; was: word_1A5E8
Chick_ThrownAnim5Data5: dc.w    4, $F401, $6C6C, $FCFC  ; was: word_1A5F0
Chick_ThrownAnim5Data2: dc.w    4, $F401, $746C, $FCFC  ; was: word_1A5F8
Chick_ThrownAnim5Data4: dc.w    4, $F401, $7C6C, $FCFC  ; was: word_1A600
Chick_ThrownAnim6Data0: dc.w    4, $F804, $646E, $F8F8  ; was: word_1A608
Chick_ThrownAnim6Data3: dc.w    4, $F804, $746E, $F8F8  ; was: word_1A610
Chick_ThrownAnim6Data1: dc.w    4, $F401, $6470, $FCFC  ; was: word_1A618
Chick_ThrownAnim6Data5: dc.w    4, $F401, $6C70, $FCFC  ; was: word_1A620
Chick_ThrownAnim6Data2: dc.w    4, $F401, $7470, $FCFC  ; was: word_1A628
Chick_ThrownAnim6Data4: dc.w    4, $F401, $7C70, $FCFC  ; was: word_1A630
Chick_ThrownAnim7Data0: dc.w    4, $F804, $6472, $F8F8  ; was: word_1A638
Chick_ThrownAnim7Data3: dc.w    4, $F804, $7472, $F8F8  ; was: word_1A640
Chick_ThrownAnim7Data1: dc.w    4, $F401, $6474, $FCFC  ; was: word_1A648
Chick_ThrownAnim7Data5: dc.w    4, $F401, $6C74, $FCFC  ; was: word_1A650
Chick_ThrownAnim7Data2: dc.w    4, $F401, $7474, $FCFC  ; was: word_1A658
Chick_ThrownAnim7Data4: dc.w    4, $F401, $7C74, $FCFC  ; was: word_1A660
Chick_ThrownAnim8Data0: dc.w    4, $F804, $6476, $F8F8  ; was: word_1A668
Chick_ThrownAnim8Data3: dc.w    4, $F804, $7476, $F8F8  ; was: word_1A670
Chick_ThrownAnim8Data1: dc.w    4, $F401, $6478, $FCFC  ; was: word_1A678
Chick_ThrownAnim8Data5: dc.w    4, $F401, $6C78, $FCFC  ; was: word_1A680
Chick_ThrownAnim8Data2: dc.w    4, $F401, $7478, $FCFC  ; was: word_1A688
Chick_ThrownAnim8Data4: dc.w    4, $F401, $7C78, $FCFC  ; was: word_1A690
Chick_ThrownAnim9Data0: dc.w    4, $F804, $647A, $F8F8  ; was: word_1A698
Chick_ThrownAnim9Data3: dc.w    4, $F804, $747A, $F8F8  ; was: word_1A6A0
Chick_ThrownAnim9Data1: dc.w    4, $F401, $647C, $FCFC  ; was: word_1A6A8
Chick_ThrownAnim9Data5: dc.w    4, $F401, $6C7C, $FCFC  ; was: word_1A6B0
Chick_ThrownAnim9Data2: dc.w    4, $F401, $747C, $FCFC  ; was: word_1A6B8
Chick_ThrownAnim9Data4: dc.w    4, $F401, $7C7C, $FCFC  ; was: word_1A6C0
Chick_ThrownAnim10Data0: dc.w    4, $F804, $647E, $F8F8  ; was: word_1A6C8
Chick_ThrownAnim10Data3: dc.w    4, $F804, $747E, $F8F8  ; was: word_1A6D0
Chick_ThrownAnim10Data1: dc.w    4, $F401, $6480, $FCFC  ; was: word_1A6D8
Chick_ThrownAnim10Data5: dc.w    4, $F401, $6C80, $FCFC  ; was: word_1A6E0
Chick_ThrownAnim10Data2: dc.w    4, $F401, $7480, $FCFC  ; was: word_1A6E8
Chick_ThrownAnim10Data4: dc.w    4, $F401, $7C80, $FCFC  ; was: word_1A6F0
Chick_ThrownAnim11Data0: dc.w    4, $F804, $6482, $F8F8  ; was: word_1A6F8
Chick_ThrownAnim11Data3: dc.w    4, $F804, $7482, $F8F8  ; was: word_1A700
Chick_ThrownAnim11Data1: dc.w    4, $F401, $6484, $FCFC  ; was: word_1A708
Chick_ThrownAnim11Data5: dc.w    4, $F401, $6C84, $FCFC  ; was: word_1A710
Chick_ThrownAnim11Data2: dc.w    4, $F401, $7484, $FCFC  ; was: word_1A718
Chick_ThrownAnim11Data4: dc.w    4, $F401, $7C84, $FCFC  ; was: word_1A720
Chick_ThrownAnim12Data0: dc.w    4, $F804, $6486, $F8F8  ; was: word_1A728
Chick_ThrownAnim12Data3: dc.w    4, $F804, $7486, $F8F8  ; was: word_1A730
Chick_ThrownAnim12Data1: dc.w    4, $F401, $6488, $FCFC  ; was: word_1A738
Chick_ThrownAnim12Data5: dc.w    4, $F401, $6C88, $FCFC  ; was: word_1A740
Chick_ThrownAnim12Data2: dc.w    4, $F401, $7488, $FCFC  ; was: word_1A748
Chick_ThrownAnim12Data4: dc.w    4, $F401, $7C88, $FCFC  ; was: word_1A750
Chick_ThrownAnim13Data0: dc.w    4, $F804, $648A, $F8F8  ; was: word_1A758
Chick_ThrownAnim13Data3: dc.w    4, $F804, $748A, $F8F8  ; was: word_1A760
Chick_ThrownAnim13Data1: dc.w    4, $F401, $648C, $FCFC  ; was: word_1A768
Chick_ThrownAnim13Data5: dc.w    4, $F401, $6C8C, $FCFC  ; was: word_1A770
Chick_ThrownAnim13Data2: dc.w    4, $F401, $748C, $FCFC  ; was: word_1A778
Chick_ThrownAnim13Data4: dc.w    4, $F401, $7C8C, $FCFC  ; was: word_1A780
Chick_ThrownAnim14Data0: dc.w    4, $F804, $648E, $F8F8  ; was: word_1A788
Chick_ThrownAnim14Data3: dc.w    4, $F804, $748E, $F8F8  ; was: word_1A790
Chick_ThrownAnim14Data1: dc.w    4, $F401, $6490, $FCFC  ; was: word_1A798
Chick_ThrownAnim14Data5: dc.w    4, $F401, $6C90, $FCFC  ; was: word_1A7A0
Chick_ThrownAnim14Data2: dc.w    4, $F401, $7490, $FCFC  ; was: word_1A7A8
Chick_ThrownAnim14Data4: dc.w    4, $F401, $7C90, $FCFC  ; was: word_1A7B0
Cat_WalkFrame0: dc.w    3, $F005, $4436, $F8F8  ; was: word_1A7B8
Cat_WalkFrame1: dc.w    3, $F005, $443A, $F8F8  ; was: word_1A7C0
Cat_WalkFrame2: dc.w    3, $F005, $4C36, $F8F8  ; was: word_1A7C8
Cat_WalkFrame3: dc.w    3, $F005, $4C3A, $F8F8  ; was: word_1A7D0
Cat_IdleFrame0: dc.w    6, $F005, $443E, $F8F8  ; was: word_1A7D8
Cat_IdleFrame1: dc.w    6, $F005, $4442, $F8F8  ; was: word_1A7E0
Cat_CarriedFrame0: dc.w    6, $F005, $4446, $F8F8  ; was: word_1A7E8
Cat_CarriedFrame1: dc.w    6, $F005, $444A, $F8F8  ; was: word_1A7F0
Cat_CarriedFrame2: dc.w    6, $F005, $444E, $F8F8  ; was: word_1A7F8
Cat_StunnedFrame0: dc.w    6, $F001, $4452, $FCFC  ; was: word_1A800
Cat_StunnedFrame1: dc.w    6, $F001, $4454, $FCFC  ; was: word_1A808
Cat_StunnedFrame2: dc.w    6, $F001, $4C52, $FCFC  ; was: word_1A810
Cat_WalkAltFrame0: dc.w    3, $F005, $4492, $F8F8  ; was: word_1A818
Cat_WalkAltFrame1: dc.w    3, $F005, $4496, $F8F8  ; was: word_1A820
Cat_WalkAltFrame2: dc.w    3, $F005, $4C92, $F8F8  ; was: word_1A828
Cat_WalkAltFrame3: dc.w    3, $F005, $4C96, $F8F8  ; was: word_1A830
Cat_IdleAltFrame0: dc.w    6, $F005, $449A, $F8F8  ; was: word_1A838
Cat_IdleAltFrame1: dc.w    6, $F005, $449E, $F8F8  ; was: word_1A840
Cat_CarriedAltFrame0: dc.w    6, $F005, $44A2, $F8F8  ; was: word_1A848
Cat_CarriedAltFrame1: dc.w    6, $F005, $44A6, $F8F8  ; was: word_1A850
Cat_CarriedAltFrame2: dc.w    6, $F005, $44AA, $F8F8  ; was: word_1A858
Cat_StunnedAltFrame0: dc.w    6, $F001, $44AE, $FCFC  ; was: word_1A860
Cat_StunnedAltFrame1: dc.w    6, $F001, $44B0, $FCFC  ; was: word_1A868
Cat_StunnedAltFrame2: dc.w    6, $F001, $4CAE, $FCFC  ; was: word_1A870
Player_DeathFrame0: dc.w    $FF, $F005, $4400, $F8F8  ; was: word_1A878
Player_DeathFrame1: dc.w    $FF, $F005, $4404, $F8F8  ; was: word_1A880
Player_DeathFrame2: dc.b    0, $FF, $F0, 5, $44, 8, $F8, $F8  ; was: byte_1A888
Player_DeathFrame3: dc.w    $FF, $F005, $440C, $F8F8  ; was: word_1A890
Guide_CharacterMap6: dc.w    0, $E806, $4410, $F8F8  ; was: word_1A898
Player_UpdateAnim_BrakingData: dc.w    1, $F005, $4416, $F8F8  ; was: word_1A8A0
Guide_CharacterMap11: dc.b    0, 0  ; was: byte_1A8A8
                dc.w    $E806, $441A, $F8F8
Player_WalkFrame1: dc.b    0, 0  ; was: byte_1A8B0
                dc.w    $E806, $4420, $F8F8
Player_FlyFrame0: dc.b    0, 1  ; was: byte_1A8B8
                dc.w    $F005, $4426, $F8F8
Player_FlyFrame1: dc.b    0, 1  ; was: byte_1A8C0
                dc.w    $F005, $442A, $F8F8
Player_BrakeFrame0: dc.b    0, 2  ; was: byte_1A8C8
                dc.w    $F005, $442E, $F8F8
Guide_CharacterMap8: dc.w    2, $F005, $4432, $F8F8  ; was: word_1A8D0
StarBonus_SpinFrame0: dc.w    7, $F800, $4B2, $FCFC  ; was: word_1A8D8
StarBonus_SpinFrame1: dc.w    7, $F800, $4B3, $FCFC  ; was: word_1A8E0
StarBonus_SpinFrame2: dc.w    7, $F800, $4B4, $FCFC  ; was: word_1A8E8
StarBonus_SpinFrame3: dc.w    7, $F800, $686, $FCFC  ; was: word_1A8F0
Lizard_WaitFrame0: dc.w    8, $F005, $44B5, $F8F8  ; was: word_1A8F8
Lizard_WaitFrame1: dc.w    8, $F005, $44B9, $F8F8  ; was: word_1A900
Lizard_WaitFrame2: dc.w    8, $F005, $44BD, $F8F8  ; was: word_1A908
Lizard_WaitFrame3: dc.w    8, $F005, $44C1, $F8F8  ; was: word_1A910
Lizard_StateLocateData: dc.w    $105, $E802, $44C5, $FCFC, $F001, $44C8, $F404  ; was: word_1A918
Lizard_RunFrame1: dc.w    $205, $E802, $44CA, $FCFC, $F001, $44CD, $F404, $F000, $44CF, $4F4  ; was: word_1A926
Lizard_RunFrame2: dc.w    $205, $E802, $44D0, $FCFC, $F000, $44D3, $4F4, $F800, $44D4, $F404  ; was: word_1A93A
Lizard_RunFrame3: dc.w    $105, $E806, $44D5, $FCF4, $F800, $44DB, $F404  ; was: word_1A94E
Lizard_RunFrame4: dc.w    $205, $E802, $44DC, $FCFC, $F001, $44DF, $4F4, $F800, $44E1, $F404  ; was: word_1A95C
Lizard_StateJump_SelectFrameData0: dc.w    $112, $EB06, $44E2, $FCF4, $FB00, $44E8, $F404  ; was: word_1A970
Lizard_StateJump_SelectFrameData1: dc.w    $212, $EB05, $44E9, $FCF4, $F301, $44ED, $F404, $FB00, $44EF, $FCFC  ; was: word_1A97E
Lizard_JumpFrame0: dc.w    $FF, $E806, $44F0, $F8F8  ; was: word_1A992
Guide_CharacterMap10: dc.w    $2FF, $EE05, $44F6, $FAF6, $F600, $44FA, $F206, $FE00, $44FB, $FAFE  ; was: word_1A99A
Lizard_JumpFrame2: dc.w    $FF, $F409, $44FC, $F4F4  ; was: word_1A9AE
Lizard_JumpFrame3: dc.w    $2FF, $E802, $4502, $FAFE, $F000, $54FA, $F206, $F001, $54F8, $2F6  ; was: word_1A9B6
Lizard_JumpFrame4: dc.w    $FF, $EB06, $54F0, $F8F8  ; was: word_1A9CA
Lizard_JumpFrame5: dc.w    $2FF, $E802, $4D02, $FEFA, $F001, $5CF8, $F602, $F000, $5CFA, $6F2  ; was: word_1A9D2
Lizard_JumpFrame6: dc.w    $FF, $F409, $4CFC, $F4F4  ; was: word_1A9E6
Lizard_JumpFrame7: dc.w    $2FF, $EE05, $4CF6, $F6FA, $F600, $4CFA, $6F2, $FE00, $4CFB, $FEFA  ; was: word_1A9EE
Lizard_StunnedFrame0: dc.w    5, $E806, $4505, $F8F8  ; was: word_1AA02
Lizard_StunnedFrame1: dc.w    5, $E806, $44F0, $F8F8  ; was: word_1AA0A
Lizard_StunnedFrame2: dc.w    5, $E806, $4D05, $F8F8  ; was: word_1AA12
BonusCat_InnerFrame0: dc.w    $205, $DC02, $44CA, $FCFC, $E401, $44CD, $F404, $E400, $44CF, $4F4  ; was: word_1AA1A
BonusCat_InnerFrame1: dc.w    $205, $DE02, $44CA, $FCFC, $E601, $44CD, $F404, $E600, $44CF, $4F4  ; was: word_1AA2E
BonusCat_InnerFrame2: dc.w    $205, $E402, $44CA, $FCFC, $EC01, $44CD, $F404, $EC00, $44CF, $4F4  ; was: word_1AA42
BonusCat_InnerFrame3: dc.w    $205, $E802, $44D0, $FCFC, $F000, $44D3, $4F4, $F800, $44D4, $F404  ; was: word_1AA56
BonusCat_InnerFrame4: dc.w    $205, $EA02, $44D0, $FCFC, $F200, $44D3, $4F4, $FA00, $44D4, $F404  ; was: word_1AA6A
Lizard_DeathFrame0: dc.w    $FF, $F800, $450B, $FCFC  ; was: word_1AA7E
Lizard_DeathFrame1: dc.w    $FF, $F800, $450C, $FCFC  ; was: word_1AA86
Lizard_DeathFrame2: dc.w    $FF, $F800, $450D, $FCFC  ; was: word_1AA8E
BonusCat_OuterFrame0: dc.w    $110, $F008, $650E, $F0F8, $F808, $6511, $F8F0  ; was: word_1AA96
BonusCat_OuterFrame1: dc.w    $110, $F008, $6514, $F0F8, $F808, $6517, $F8F0  ; was: word_1AAA4
BonusCat_OuterFrame2: dc.w    $10, $F00D, $651A, $F0F0  ; was: word_1AAB2
BonusCat_OuterFrame3: dc.w    $110, $F008, $6D14, $F8F0, $F808, $6D17, $F0F8  ; was: word_1AABA
BonusCat_OuterFrame4: dc.w    $110, $F008, $6D0E, $F8F0, $F808, $6D11, $F0F8  ; was: word_1AAC8
Obj_BonusHeldChick_UpdateData0: dc.w    $111, $F004, $522, $F8F8, $F800, $524, $F800  ; was: word_1AAD6
Obj_BonusHeldChick_UpdateData1: dc.w    $11, $F005, $525, $F8F8  ; was: word_1AAE4
Spawner_AppearFrame0: dc.w    0, $F300, $529, $FDFB  ; was: word_1AAEC
Spawner_AppearFrame1: dc.w    0, $F300, $52A, $FDFB  ; was: word_1AAF4
Spawner_AppearFrame2: dc.w    0, $F300, $52B, $FDFB  ; was: word_1AAFC
Spawner_AppearFrame3: dc.w    0, $F300, $52B, $FDFB  ; was: word_1AB04
Spawner_AppearFrame4: dc.w    0, $F300, $52C, $FDFB  ; was: word_1AB0C
Spawner_AppearFrame5: dc.w    0, $F300, $52D, $FDFB  ; was: word_1AB14
Spawner_AppearFrame6: dc.w    0, $F300, $52E, $FDFB  ; was: word_1AB1C
ChickCountPopup_Map0: dc.w    $FF, $F808, $640, $F4F4  ; was: word_1AB24
ScorePopup_Map0: dc.b    0, $FF, $F8, 8, 6, $43, $F4, $F4  ; was: byte_1AB2C
ChickCountPopup_Map2: dc.w    $FF, $F808, $646, $F4F4  ; was: word_1AB34
ScorePopup_Map1: dc.w    $FF, $F808, $649, $F4F4  ; was: word_1AB3C
ChickCountPopup_Map4: dc.w    $FF, $F808, $64C, $F4F4  ; was: word_1AB44
ScorePopup_Map2: dc.w    $FF, $F808, $64F, $F4F4  ; was: word_1AB4C
ChickCountPopup_Map5: dc.w    $FF, $F808, $652, $F2F6  ; was: word_1AB54
ChickCountPopup_Map6: dc.w    $FF, $F808, $655, $F2F6  ; was: word_1AB5C
BonusScorePopup_Map8: dc.w    $FF, $F808, $658, $F2F6  ; was: word_1AB64
ChickCountPopup_Map7: dc.w    $FF, $F808, $65B, $F2F6  ; was: word_1AB6C
Snake_StateSpawnData: dc.w    9, $F001, $465E, $FCFC  ; was: word_1AB74
Snake_RightFrame0: dc.w    $A, $F804, $4660, $F8F8  ; was: word_1AB7C
Snake_RightFrame1: dc.w    $A, $F804, $4662, $F8F8  ; was: word_1AB84
Snake_RightFrame2: dc.w    $A, $F804, $4664, $F8F8  ; was: word_1AB8C
Snake_LeftFrame0: dc.w    $B, 4, $4666, $F8F8  ; was: word_1AB94
Snake_LeftFrame1: dc.w    $B, 4, $4668, $F8F8  ; was: word_1AB9C
Snake_LeftFrame2: dc.w    $B, 4, $466A, $F8F8  ; was: word_1ABA4
Snake_UpFrame0: dc.w    $C, $F801, $466C, $F800  ; was: word_1ABAC
Snake_UpFrame1: dc.w    $C, $F801, $466E, $F800  ; was: word_1ABB4
Snake_DownFrame0: dc.w    $D, $F801, $566C, $F800  ; was: word_1ABBC
Snake_DownFrame1: dc.w    $D, $F801, $566E, $F800  ; was: word_1ABC4
Snake_MoveRight_TurnUpData: dc.w    $1FF, $F001, $4670, $F800, $F800, $4672, $F008  ; was: word_1ABCC
Snake_MoveUp_TurnRightData: dc.w    $1FF, 4, $4673, $F000, $800, $4675, $F800  ; was: word_1ABDA
Snake_MoveLeft_TurnDownData: dc.w    $1FF, 4, $4676, $F0, $800, $5E70, $F8  ; was: word_1ABE8
Snake_MoveDown_TurnRightData: dc.w    $1FF, $F001, $4678, $F8, $F800, $5E73, $8F0  ; was: word_1ABF6
Snake_MoveRight_TurnDownData: dc.w    $1FF, $F804, $467A, $F8F8, 0, $467C, $F8  ; was: word_1AC04
Snake_MoveUp_StartTurnData: dc.w    $1FF, $F801, $467D, $F8, 0, $467F, $F800  ; was: word_1AC12
Snake_MoveLeft_TurnUpData: dc.w    $1FF, $F801, $5E7B, $F800, 0, $5E7A, $F8  ; was: word_1AC20
Snake_MoveUp_TurnLeftData: dc.w    $1FF, $F804, $4680, $F8F8  ; was: word_1AC2E
                dc.w    0, $5E7D, $F800
Snake_TurnAFrame0: dc.w    $E, $F801, $4682, $FCFC  ; was: word_1AC3C
Snake_TurnAFrame1: dc.w    $E, $F801, $4E82, $FCFC  ; was: word_1AC44
Snake_MoveRight_StartTurnData: dc.w    9, $F001, $4684, $FCFC  ; was: word_1AC4C
Snake_TurnBFrame0: dc.w    $E, $F801, $5682, $FCFC  ; was: word_1AC54
Snake_TurnBFrame1: dc.w    $E, $F801, $5E82, $FCFC  ; was: word_1AC5C
Snake_MoveLeft_StartTurnData: dc.w    $F, 1, $5684, $FCFC  ; was: word_1AC64
Snake_SpawnFrame0: dc.w    $1FF, $F604, $467A, $F6FA, $FE00, $467C, $FEFA  ; was: word_1AC6C
Snake_SpawnFrame1: dc.w    $1FF, $F001, $467D, $FCFC, $F800, $467F, $F404  ; was: word_1AC7A
Snake_SpawnFrame2: dc.w    $1FF, $F001, $5E7B, $FCFC, $F800, $5E7A, $4F4  ; was: word_1AC88
Snake_SpawnFrame3: dc.w    $1FF, $F304, $4680, $FBF5, $FB00, $5E7D, $FBFD  ; was: word_1AC96
Obj_GameOverTextData: dc.w    $8FF  ; was: word_1ACA4
                dc.w    0, $8047, $F8
                dc.w    0, $8041, $8F0
                dc.w    0, $804D, $10E8
                dc.w    0, $8045, $18E0
                dc.w    0, $8020, $20D8
                dc.w    0, $804F, $28D0
                dc.w    0, $8056, $30C8
                dc.w    0, $8045, $38C0
                dc.w    0, $8052, $40B8
Obj_TitleCursorData: dc.w    $DFF  ; was: word_1ACDC
                dc.w    0, $8050, $C830
                dc.w    0, $8055, $D028
                dc.w    0, $8053, $D820
                dc.w    0, $8048, $E018
                dc.w    4, $8053, $F000
                dc.w    0, $8041, $F8
                dc.w    0, $8052, $8F0
                dc.w    0, $8054, $10E8
                dc.w    0, $8042, $20D8
                dc.w    0, $8055, $28D0
                dc.w    0, $8054, $30C8
                dc.w    0, $8054, $38C0
                dc.w    0, $804F, $40B8
                dc.w    0, $804E, $48B0
Obj_TimeOverTextData: dc.w    $4FF  ; was: word_1AD32
                dc.w    0, $8050, $F8
                dc.w    0, $8041, $8F0
                dc.w    0, $8055, $10E8
                dc.w    0, $8053, $18E0
                dc.w    0, $8045, $20D8
Title_StaticMap0: dc.w    $FF, $E00B, $6740, $F4F4  ; was: word_1AD52
Title_StaticMap1: dc.w    $FF, $E80A, $674C, $F4F4  ; was: word_1AD5A
Title_StaticMap2: dc.w    $FF, $E806, $6755, $F8F8  ; was: word_1AD62
Title_StaticMap3: dc.w    $FF, $E80A, $675B, $F4F4  ; was: word_1AD6A
Title_StaticMap4: dc.w    $FF, $E80A, $6764, $F4F4  ; was: word_1AD72
Title_StaticMap5: dc.w    $FF, $E00B, $676D, $F4F4  ; was: word_1AD7A
ExitDoor_OpenFrame0: dc.w    $FF, $E806, $4687, $F8F8  ; was: word_1AD82
ExitDoor_OpenFrame1: dc.w    $FF, $E806, $468D, $F8F8  ; was: word_1AD8A
Level_DataPointers: dc.w    Level_Data0-Sys_GameEntryPoint  ; was: off_1AD92
                dc.w    Level_Data1-Sys_GameEntryPoint
                dc.w    Level_Data1-Sys_GameEntryPoint
                dc.w    Level_Data2-Sys_GameEntryPoint
                dc.w    Level_Data3-Sys_GameEntryPoint
                dc.w    Level_Data4-Sys_GameEntryPoint
                dc.w    Level_Data4-Sys_GameEntryPoint
                dc.w    Level_Data5-Sys_GameEntryPoint
                dc.w    Level_Data6-Sys_GameEntryPoint
                dc.w    Level_Data7-Sys_GameEntryPoint
                dc.w    Level_Data7-Sys_GameEntryPoint
                dc.w    Level_Data8-Sys_GameEntryPoint
                dc.w    Level_Data9-Sys_GameEntryPoint
                dc.w    Level_Data10-Sys_GameEntryPoint
                dc.w    Level_Data10-Sys_GameEntryPoint
                dc.w    Level_Data11-Sys_GameEntryPoint
                dc.w    Level_Data12-Sys_GameEntryPoint
                dc.w    Level_Data13-Sys_GameEntryPoint
                dc.w    Level_Data13-Sys_GameEntryPoint
                dc.w    Level_Data14-Sys_GameEntryPoint
                dc.w    Level_Data15-Sys_GameEntryPoint
                dc.w    Level_Data16-Sys_GameEntryPoint
                dc.w    Level_Data16-Sys_GameEntryPoint
                dc.w    Level_Data17-Sys_GameEntryPoint
                dc.w    Level_Data18-Sys_GameEntryPoint
                dc.w    Level_Data19-Sys_GameEntryPoint
                dc.w    Level_Data19-Sys_GameEntryPoint
                dc.w    Level_Data20-Sys_GameEntryPoint
                dc.w    Level_Data21-Sys_GameEntryPoint
                dc.w    Level_Data22-Sys_GameEntryPoint
                dc.w    Level_Data22-Sys_GameEntryPoint
                dc.w    Level_Data23-Sys_GameEntryPoint
                dc.w    Level_Data24-Sys_GameEntryPoint
                dc.w    Level_Data25-Sys_GameEntryPoint
                dc.w    Level_Data25-Sys_GameEntryPoint
                dc.w    Level_Data26-Sys_GameEntryPoint
                dc.w    Level_Data27-Sys_GameEntryPoint
                dc.w    Level_Data28-Sys_GameEntryPoint
                dc.w    Level_Data28-Sys_GameEntryPoint
                dc.w    Level_Data29-Sys_GameEntryPoint
                dc.w    Level_Data30-Sys_GameEntryPoint
                dc.w    Level_Data31-Sys_GameEntryPoint
                dc.w    Level_Data31-Sys_GameEntryPoint
                dc.w    Level_Data32-Sys_GameEntryPoint
                dc.w    Level_Data33-Sys_GameEntryPoint
                dc.w    Level_Data34-Sys_GameEntryPoint
                dc.w    Level_Data34-Sys_GameEntryPoint
                dc.w    Level_Data35-Sys_GameEntryPoint
Level_Data0:    dc.b    $40, $86, $14, $86, $4A, $8C, $4A, $86, $14, $86  ; was: byte_1ADF2
                dc.b    $4A, $8C, $4A, $86, $14, $86, $4A, $8C, $4A, $86
                dc.b    $14, $86, 0, $F, $17, $F, $B, $F, 5, $13
                dc.b    3, 8, $1E, 6, $1E, $C, $1E, $12, 0, $12
                dc.b    0, $C, 0, 6, $E, $F, $10, $F, 1, 7
                dc.b    3, 0, $B, 6, $B, $C, $B, $12, $13, $12
                dc.b    $13, $C, $13, 6, 6, $F, $F, $13, $15, $1F
                dc.b    $12, $1F, $C, $C, 9, $12, 9, 0
Level_Data1:    dc.b    $7F, $44, $9A, $7F, $24, $8D, 6, $8D, $7F, $24  ; was: byte_1AE40
                dc.b    $9A, $7F, 0, $F, 5, 7, 6, $16, $12, 6
                dc.b    $10, 4, 9, $A, 9, $16, $18, $16, $1C, $A
                dc.b    0, 1, $E, $A, 9, 7, 9, $D, 9, $13
                dc.b    $17, $13, $17, $D, $17, 7, 6, 0, 6, 6
                dc.b    $A, 0, $15, $F, $16, $19, $A, $17, 3, 0
Level_Data2:    dc.b    $7F, $41, $8D, 6, $8D, $7F, $21, $8D, 6, $8D  ; was: byte_1AE7C
                dc.b    $7F, $21, $8D, 6, $8D, $7F, 0, $F, $17, $1B
                dc.b    6, $16, $18, $14, 3, $13, 1, 4, 3, 4
                dc.b    7, 4, $1D, 4, $15, $A, $17, $A, $1B, $A
                dc.b    $1D, $A, 7, $A, 9, $A, 7, $10, 1, $10
                dc.b    3, $10, $15, $10, $1B, $16, $1D, $16, 0, $16
                dc.b    3, $16, 5, $16, 0, 0, 5, 7, 5, $D
                dc.b    5, $13, $19, $13, $19, $D, $19, 7, 8, 7
                dc.b    3, 6, $A, 7, $10, 7, $16, $19, $16, $19
                dc.b    $10, $1A, $A, $17, 3, 0
Level_Data3:    dc.b    $7F, $D, $88, $70, $88, 8, $88, $64, $84, $18  ; was: byte_1AEDC
                dc.b    $84, $64, $88, 8, $88, $70, $88, 0, $F, 3
                dc.b    7, 8, $17, $10, 1, $16, 4, 6, $E, 8
                dc.b    $E, $E, $12, $10, $12, 0, 0, 9, 9, 9
                dc.b    $11, $F, $15, $15, $11, $15, 9, $1F, $D, 6
                dc.b    7, 3, 0, 9, 7, $D, $F, $10, $F, $A
                dc.b    5, $14, 2, $17, 5, $19, $15, 0
Level_Data4:    dc.b    6, $C7, $7F, $3A, $86, 5, $C7, $8A, 5, $C7  ; was: byte_1AF20
                dc.b    $84, $7F, $21, $C7, $8A, 5, $C7, $8A, $7F, $2B
                dc.b    $C6, $8A, 5, $8B, $7F, 0, $F, 5, $1D, 6
                dc.b    $15, $18, $C, $16, 4, $C, 4, $13, 4, 7
                dc.b    $10, 9, $10, 0, 0, $1B, 7, 3, 7, 5
                dc.b    $D, 5, $13, $19, $13, $18, $D, 6, $A, 4
                dc.b    3, $A, 9, $16, $12, $10, $12, $A, $18, 4
                dc.b    2, $1D, $10, $1A, $16, 0
Level_Data5:    dc.b    $57, $C5, $86, $6D, $8C, 1, $87, $1F, $C4, $41  ; was: byte_1AF6C
                dc.b    $85, $1A, $81, 4, $C4, $26, $C7, $8B, $29, $84
                dc.b    $17, $85, $60, $87, 5, $86, 4, $8A, 6, $C5
                dc.b    $7F, 0, $F, 5, $1A, 2, $1A, $18, 1, 8
                dc.b    3, $D, $A, $F, $A, $16, $16, 1, 2, 5
                dc.b    0, $C, 7, $C, $D, $C, $13, $C, $19, $18
                dc.b    $19, $18, $13, 6, 4, 3, 0, $16, 7, $A
                dc.b    7, $F, $E, $10, $D, $16, 2, $18, $B, $13
                dc.b    3, 0
Level_Data6:    dc.b    $7F, 3, $CB, $8B, 4, $8C, $1F, $CA, $6A, $86  ; was: byte_1AFBE
                dc.b    4, $CB, $85, $15, $CA, $75, $85, $10, $85, $7F
                dc.b    6, $8B, 6, $8B, $7F, 0, $F, $17, $1A, 4
                dc.b    7, $18, 4, 2, 6, 9, 2, $B, 2, 4
                dc.b    $C, $A, $11, $15, $11, $1A, $C, 2, 6, 8
                dc.b    $17, $17, 0, 9, 5, 9, $A, 9, $14, $15
                dc.b    $14, $15, $A, $15, 5, 4, 7, 2, $17, 2
                dc.b    9, 8, $1F, $B, 4, $15, 8, $15, $E, 9
                dc.b    $E, $F, $C, 0
Level_Data7:    dc.b    $40, $84, $18, $C7, $83, 3, $C2, $20, $84, $24  ; was: byte_1B012
                dc.b    $88, $25, $83, $24, $84, $19, $83, 3, $C2, $20
                dc.b    $84, $24, $88, $24, $84, $1F, $C8, 4, $84, $18
                dc.b    $84, 3, $C2, $20, $84, $24, $88, $24, $83, $25
                dc.b    $84, $18, $84, 0, $F, 4, 0, 8, $11, $18
                dc.b    $D, $16, 3, 5, $E, $F, $F, $18, $10, 0
                dc.b    1, 7, $16, $F, $12, $F, $19, $1D, $15, $1D
                dc.b    $F, $1D, 9, $1D, 3, 4, 6, 2, 5, 8
                dc.b    5, $E, $19, 2, 4, $19, $A, $15, $F, $F
                dc.b    $16, $F, 9, 0
Level_Data8:    dc.b    $43, $9A, $7F, 4, $8E, 4, $8E, $6E, $84, $7A  ; was: byte_1B070
                dc.b    $88, $7F, $17, $8C, 0, $F, $13, 2, $18, $19
                dc.b    7, $1C, $E, 1, $1A, $16, 1, $18, $13, 2
                dc.b    0, $10, 5, $D, 5, 3, 9, 3, $D, 3
                dc.b    $11, 3, $15, 3, $19, 3, 4, $F, 1, 9
                dc.b    5, $15, 5, $F, 9, 4, 6, $F, 2, $13
                dc.b    $1A, $14, $18, $E
Level_Data9:    dc.b    $6A, $C3, $87, $1F, $C4, $E, $82, 4, $84, $12  ; was: byte_1B0B0
                dc.b    $84, $32, $84, $70, $84, $C, $C5, $83, $F, $C4
                dc.b    $58, $84, 4, $84, 4, $84, 4, $84, $62, $82
                dc.b    $1C, $82, $A, $8C, 0, $F, $13, $14, 7, 4
                dc.b    $18, $1B, $16, 3, $1B, $D, $13, $D, $B, $D
                dc.b    1, 4, $15, 2, 0, $B, $18, 3, $B, 4
                dc.b    $13, 8, $13, $10, $13, $15, $B, $15, $B, $10
                dc.b    4, 3, 2, $D, 2, $1D, 3, $18, 6, 4
                dc.b    2, $B, $C, $B, $12, $D, $19, $15
Level_Data10:   dc.b    $6C, $88, $7F, $14, $86, 6, $86, $7F, $2A, $86  ; was: byte_1B108
                dc.b    $10, $86, $7F, $23, $83, $1A, $83, 0, $F, $17
                dc.b    9, 8, $1B, $E, $10, $11, 2, $16, 6, 4
                dc.b    $C, 2, 6, $17, $15, $15, 3, $19, 4, $1B
                dc.b    $A, 0, 4, $B, 9, 6, $F, 1, $15, $1D
                dc.b    $15, $18, $F, $13, 9, 4, 0, 6, 4, $C
                dc.b    1, $12, $C, $11, 4, $13, $11, $1D, $12, $1C
                dc.b    7, $15, 6, 0
Level_Data11:   dc.b    $68, $85, $B, $C3, $83, $10, $C2, $20, $8B, $68  ; was: byte_1B152
                dc.b    $84, 8, $89, 7, $84, $14, $CA, $7F, $14, $C6
                dc.b    $87, 5, $87, $72, $86, $C, $88, 0, $F, 4
                dc.b    $1A, 3, $C, $F, $1B, $16, 3, 2, $12, $17
                dc.b    $D, $19, $D, 0, 1, 5, $A, $A, 4, $C
                dc.b    $A, $E, $14, 6, $15, $15, $10, $19, 4, 4
                dc.b    4, 5, 3, $11, 9, 8, $17, 9, 4, $11
                dc.b    $E, $10, $17, $17, $14, $A, $14, 0
Level_Data12:   dc.b    $7F, 1, $82, $C, $84, $C, $82, $62, $84, 4  ; was: byte_1B1A0
                dc.b    $84, 4, $84, 4, $84, $68, $84, $C, $84, $68
                dc.b    $84, 4, $84, 4, $84, 4, $84, $62, $82, $C
                dc.b    $84, $C, $82, 0, $F, 3, 3, 8, $17, $18
                dc.b    9, $16, 4, $B, $E, $B, 6, $13, 6, $13
                dc.b    $E, 0, 2, $16, 4, 0, $C, $C, 9, $A
                dc.b    $11, 0, $15, $1E, $15, $14, $11, $12, 9, 4
                dc.b    8, 5, 7, $A, 6, $15, $F, $B, 4, $13
                dc.b    $15, $17, 9, $1B, 5, $1D, $F, 0
Level_Data13:   dc.b    $47, $C7, $85, 6, $86, $1F, $C6, $55, $84, $30  ; was: byte_1B1F8
                dc.b    $85, $12, $85, $7F, $25, $86, $10, $C7, $85, 9
                dc.b    $C6, $7F, $21, $85, 6, $85, 0, $F, 5, $A
                dc.b    2, $14, $18, $1C, $16, 2, $1A, 6, 4, 6
                dc.b    0, 1, 0, $13, 7, 3, 9, 3, $B, 3
                dc.b    $13, 3, $15, 3, $17, 3, 4, 0, $C, 3
                dc.b    6, $A, $F, 2, $14, 4, $F, $D, $14, $F
                dc.b    $1A, $15, $1B, 5
Level_Data14:   dc.b    $7F, 1, $8D, 6, $87, 5, $81, $7F, $21, $9A  ; was: byte_1B242
                dc.b    5, $81, $C, $CA, $7F, $14, $86, 7, $8D, 5
                dc.b    $81, $60, $8C, $12, $82, $32, $C2, $C2, $C2, $C2
                dc.b    0, $F, 9, 4, 4, $F, $18, $13, $14, 0
                dc.b    8, 8, 3, $E, 3, $18, 3, $1A, 8, $11
                dc.b    $F, $17, $15, 5, $E, 4, 8, 5, $A, 8
                dc.b    7, $11, $1B, $B, $17, $E, 0, 2, 3, $11
                dc.b    5, $15, 5, 5, $17, 5, $17, $B, $17, $11
                dc.b    4, $A, 2, 4, 8, 8, $10, $E, $14, 4
                dc.b    $1B, $15, $F, $E, $15, 8, $1C, 3
Level_Data15:   dc.b    $4E, $84, $7A, $88, $75, $8E, $6F, $94, $7F, $A  ; was: byte_1B2A4
                dc.b    $9A, $7F, 0, $F, $17, $F, 6, $17, $18, 0
                dc.b    $B, 0, 4, 2, $B, 7, 3, $15, 4, $17
                dc.b    7, 3, 1, 7, 5, 6, $1C, $D, $F, 7
                dc.b    $F, $B, $D, $F, $11, $F, $13, $14, $B, $14
                dc.b    4, 4, $A, $A, 4, $C, $12, 8, $17, 4
                dc.b    $15, $17, $12, $12, $15, 5, $1D, 9
Level_Data16:   dc.b    $48, $85, 6, $C6, $84, 8, $82, $A, $C5, $11  ; was: byte_1B2E8
                dc.b    $82, $7F, 4, $85, $10, $85, $7F, $2C, $85, 6
                dc.b    $C6, $84, 8, $84, 8, $C5, $F, $C6, $83, 3
                dc.b    $C5, $69, $86, $11, $84, $10, $84, 0, $F, $17
                dc.b    $1E, 3, 5, $18, $1C, $D, 0, 5, 0, $C
                dc.b    6, $C, 5, $13, 9, $17, $13, $D, 2, $F
                dc.b    $E, $E, 3, 9, 3, 9, $F, $15, 3, $15
                dc.b    $F, $1E, $10, $1F, 4, 4, $F, 3, 5, 4
                dc.b    9, $A, 7, $12, 4, $15, $B, $19, 5, $17
                dc.b    $13, $1F, $D, 0
Level_Data17:   dc.b    $6B, $C6, $82, 4, $D2, $82, $18, $D1, 6, $C5  ; was: byte_1B346
                dc.b    $73, $C6, $82, $A, $83, $1F, $C5, $6D, $C6, $82
                dc.b    $10, $83, $1F, $C5, $67, $83, $16, $83, $2C, $83
                dc.b    6, $83, 0, $F, $17, $13, 3, 3, $18, $1E
                dc.b    4, 8, 8, 6, 5, $B, 2, $10, $1C, $10
                dc.b    $19, $A, $16, 6, $14, $12, $A, $12, 1, 1
                dc.b    5, 0, $C, 4, 9, 9, 6, $E, $18, $E
                dc.b    $15, 9, $12, 4, 4, 8, 3, 4, 8, $A
                dc.b    $E, $1F, $E, 4, $14, $E, $F, $B, $16, 3
                dc.b    $1A, 8
Level_Data18:   dc.b    $62, $94, $1F, $C4, $4A, $8A, $C, $84, 4, $82  ; was: byte_1B3A2
                dc.b    $19, $C4, $4C, $C5, $92, $68, $85, $A, $8C, 6
                dc.b    $C4, $60, $9B, $7F, 0, $F, 2, $F, $B, $F
                dc.b    $18, $1E, $10, 4, $12, 9, $A, $11, $C, $11
                dc.b    $C, 9, 0, 1, $1C, $B, $14, $C, $15, $C
                dc.b    $16, $C, 3, $14, 4, $14, 5, $14, 4, 2
                dc.b    $C, 8, 2, 9, $10, 9, $16, 4, $D, 8
                dc.b    $1C, $C, $1C, 4, $14, $16
Level_Data19:   dc.b    $D8, $60, $91, 4, $86, $1F, $D0, $55, $C5, $85  ; was: byte_1B3EE
                dc.b    $1F, $C8, $56, $C5, $83, $78, $C5, $83, 5, $84
                dc.b    $6F, $84, 1, $8D, $7F, 0, $F, $17, 8, 3
                dc.b    6, $18, 2, $D, 4, $A, $D, 6, $11, $E
                dc.b    9, $13, 5, 1, 3, 9, 0, 1, 4, $A
                dc.b    $14, $B, $14, $12, $10, $13, $10, $14, $10, 4
                dc.b    $B, 9, 5, $D, 2, $15, $F, $10, 4, $13
                dc.b    $C, $18, $B, $1D, $B, $19, 2, 0
Level_Data20:   dc.b    $64, $98, $64, $8D, 6, $8D, $64, $98, $64, $8D  ; was: byte_1B43C
                dc.b    6, $8D, $64, $98, $7F, 0, $F, 2, $F, $B
                dc.b    $F, $18, $1C, $16, 8, $1E, $16, 0, $16, 0
                dc.b    $D, 0, 5, $1E, 5, $1E, $D, $E, $11, $10
                dc.b    $11, 0, 0, 9, 8, 9, $10, $15, $10, $14
                dc.b    8, $F, $C, $F, $14, 4, $B, 2, 9, $16
                dc.b    $F, 8, $F, $10, 4, $15, $16, $1F, $14, $1F
                dc.b    $C, $1F, 2, 0
Level_Data21:   dc.b    $63, $D1, $97, $7F, $12, $94, $7F, 9, $91, $7F  ; was: byte_1B486
                dc.b    $2C, $99, $7F, 0, $F, 2, $15, 8, $D, $18
                dc.b    $1A, $C, 5, 9, $B, $B, $11, $D, $11, $12
                dc.b    $11, $14, $11, 0, 0, $C, 9, $C, $E, $C
                dc.b    $14, $17, $14, $17, $E, $17, 9, 4, $11, $C
                dc.b    7, 9, 5, $F, $1F, $14, 4, $11, $11, $13
                dc.b    $17, $1C, $F, $1D, 4, 0
Level_Data22:   dc.b    $46, $C6, $85, $A, $C6, $85, $7F, 5, $C7, $85  ; was: byte_1B4C8
                dc.b    $A, $C7, $85, $7F, $35, $C6, $85, $A, $C6, $85
                dc.b    $7F, 5, $C6, $85, $A, $C6, $85, $7F, 0, $F
                dc.b    $17, 8, 2, $18, 2, $1E, $16, $A, $15, $10
                dc.b    $17, $10, $1C, $B, $1E, $B, 5, $10, 7, $10
                dc.b    $B, $B, $D, $B, $11, 5, $13, 5, 0, 0
                dc.b    4, 8, $E, $E, 5, $19, $15, $19, $14, 8
                dc.b    $1E, $E, 4, 1, 3, 5, $D, $B, 8, 6
                dc.b    $16, 4, $E, $13, $15, $E, $12, 2, $18, $16
Level_Data23:   dc.b    $1F, $D8, $43, $CC, $88, 7, $89, $1F, $CB, $68  ; was: byte_1B522
                dc.b    $89, 5, $89, $7F, $2A, $89, 5, $89, $7F, $E
                dc.b    $8F, $7F, 0, $F, $17, 7, 3, $F, $13, 1
                dc.b    $12, 4, 4, $15, $A, $C, $13, $C, $19, $15
                dc.b    1, $14, 7, 0, 9, 9, 9, $F, 9, $14
                dc.b    $13, $14, $13, $F, $13, 9, 4, $F, 3, 0
                dc.b    8, 3, $12, 5, $C, 4, $F, $D, $18, $C
                dc.b    $1A, $14, $1D, 9
Level_Data24:   dc.b    $60, $8E, 4, $8E, $7F, $4F, $84, $7F, $4F, $8E  ; was: byte_1B56C
                dc.b    4, $8E, $7F, 0, $F, 9, $1A, 3, 4, $11
                dc.b    1, $B, 4, $B, $F, 9, $F, $13, $F, $15
                dc.b    $F, 1, 4, $16, 0, 2, $19, 2, $12, 2
                dc.b    4, $1D, 4, $1D, $12, $1D, $19, 4, 6, 2
                dc.b    2, $E, 9, 9, 6, $15, 4, $18, 2, $14
                dc.b    9, $1C, $F, $18, $15, 0
Level_Data25:   dc.b    $4A, $85, 3, $D3, $84, $17, $D2, $33, $CD, $84  ; was: byte_1B5AE
                dc.b    $13, $85, $1F, $CC, $2B, $84, 5, $84, $4C, $84
                dc.b    $13, $84, $4C, $84, 5, $84, $4C, $84, $13, $84
                dc.b    $4C, $84, 5, $84, 0, $F, $17, $1B, 5, 3
                dc.b    $18, $10, $D, 4, 4, 9, 4, $F, $1B, $F
                dc.b    $1B, 9, 0, 0, $B, 3, $B, 9, $B, $F
                dc.b    $12, $F, $12, 9, $12, 3, 4, $B, 6, $B
                dc.b    $12, 8, $C, $1F, $C, 4, $15, 6, $14, $12
                dc.b    $17, $C, $10, $A
Level_Data26:   dc.b    $60, $CF, $8E, 3, $8E, $67, $C4, $83, $B, $C4  ; was: byte_1B602
                dc.b    $83, $10, $C3, $E, $C3, $27, $86, 1, $82, 1
                dc.b    $84, 3, $84, 1, $82, 1, $86, $67, $C4, $83
                dc.b    $B, $C4, $83, $10, $C3, $E, $C3, $27, $86, 1
                dc.b    $82, 1, $84, 3, $84, 1, $82, 1, $86, $60
                dc.b    $87, $13, $C3, $85, 6, $C2, 0, $F, $17, $1C
                dc.b    3, 8, $18, 2, 8, 4, $C, 8, $C, $F
                dc.b    $13, $F, $13, 8, 0, 0, $C, 4, $C, $B
                dc.b    $C, $12, $13, $12, $13, $B, $13, 4, 4, $10
                dc.b    7, 3, 8, 3, $F, 9, $15, 4, $10, $F
                dc.b    $15, $15, $1D, $F, $1D, 7
Level_Data27:   dc.b    $4C, $89, $1F, $C4, $51, $CC, $89, 5, $85, $1F  ; was: byte_1B66C
                dc.b    $CB, $49, $83, $A, $84, 6, $85, $7F, $43, $85
                dc.b    1, $85, 8, $C4, $84, 1, $83, $E, $C3, $40
                dc.b    $88, 0, $F, $13, $10, 2, $1E, $18, $F, $17
                dc.b    4, 8, $F, $A, $F, $14, $F, $16, $F, 1
                dc.b    0, $16, 0, 7, 7, 4, $12, 8, $12, $12
                dc.b    3, $1B, $B, $16, $12, 4, 9, 3, 0, 7
                dc.b    0, $F, 6, $16, 4, $B, $D, $16, $D, $19
                dc.b    $16, $1B, 3, 0
Level_Data28:   dc.b    $7F, $7F, $70, $84, $7F, $4F, $82, 6, $84, 8  ; was: byte_1B6C0
                dc.b    $84, 6, $82, $7F, 0, $F, $A, 9, $18, $15
                dc.b    $12, $F, $10, 4, 3, $A, 5, $A, $19, $A
                dc.b    $1B, $A, 0, 0, 9, $13, $15, $13, $1F, $13
                dc.b    4, $19, $F, $19, $1A, $19, 4, 3, $10, 7
                dc.b    9, $B, 7, $1F, 9, 4, $14, 7, $F, $13
                dc.b    $18, 9, $1A, $10
Level_Data29:   dc.b    $40, $89, 5, $92, $12, $D2, $4D, $8E, 8, $8A  ; was: byte_1B700
                dc.b    $D, $C4, $72, $8A, 9, $8D, $60, $8E, 9, $89
                dc.b    $D, $C8, $72, $89, $A, $8D, 0, $F, $17, $B
                dc.b    6, $B, $F, $F, $E, 4, $17, 9, $19, 9
                dc.b    $17, $12, $19, $12, 1, 3, $13, 0, $1A, $19
                dc.b    $1A, $15, $1A, $10, $1A, $C, $1A, 7, $1A, 3
                dc.b    4, 6, 2, $A, $A, $F, $A, $14, $A, 4
                dc.b    $E, 2, $A, $14, $F, $13, $14, $13
Level_Data30:   dc.b    $40, $83, 3, $85, 3, $85, 3, $85, 3, $82  ; was: byte_1B74E
                dc.b    $62, $85, 3, $85, 3, $85, 3, $85, $61, $83
                dc.b    3, $85, 3, $85, 3, $85, 3, $82, $62, $85
                dc.b    3, $85, 3, $85, 3, $85, $61, $83, 3, $85
                dc.b    3, $85, 3, $85, 3, $82, $7F, 0, $F, $17
                dc.b    7, $A, $17, $A, $F, 9, 4, 3, $16, 5
                dc.b    $16, $19, $16, $1B, $16, 2, 8, $17, $12, $17
                dc.b    0, $B, 7, $14, 7, $17, $B, 7, $B, $F
                dc.b    $B, $F, $13, 4, 7, 2, 7, $D, 7, $16
                dc.b    $C, $B, 4, $14, $B, $17, 2, $18, $E, $17
                dc.b    $17, 0
Level_Data31:   dc.b    $63, $84, 4, $84, 4, $84, 4, $84, 7, $C7  ; was: byte_1B7B4
                dc.b    7, $C7, 7, $C7, 7, $C7, $7F, $22, $82, 5
                dc.b    $83, 5, $83, 5, $83, 5, $81, 1, $C7, 7
                dc.b    $C7, 7, $C7, 7, $C7, $7F, $29, $83, 5, $83
                dc.b    5, $83, 5, $83, 7, $C6, 7, $C6, 7, $C6
                dc.b    7, $C6, $7F, 0, $F, $17, $C, 3, $1C, 3
                dc.b    $B, $A, 4, 0, 8, 2, 8, $10, 8, $12
                dc.b    8, 0, 0, 4, 4, $C, 4, $14, 4, $1C
                dc.b    4, $18, $19, 7, $19, 4, 1, $15, 6, $F
                dc.b    $B, 8, 9, $16, 4, $E, $E, $16, $E, $1E
                dc.b    $E, $19, $15, 0
Level_Data32:   dc.b    $6E, $84, $7F, $65, $86, $7F, $45, $88, $7F, 0  ; was: byte_1B81C
                dc.b    $F, 2, 3, $11, $13, $18, 0, 6, 0, 7
                dc.b    4, $E, 7, $B, 9, 8, $16, 4, $19, $E
                dc.b    $19, $17, $B, $13, 0, $D, 4, $D, 4, $D
                dc.b    4, $D, 4, $D, 4, $D, 4, 4, 6, $F
                dc.b    6, 6, $F, 7, $F, $D, 4, $F, $14, $1B
                dc.b    $F, $17, 6, $1E, 6, 0
Level_Data33:   dc.b    $60, $82, $D, $C4, $82, $D, $C4, 1, $C3, $F  ; was: byte_1B85E
                dc.b    $C3, $2E, $81, $F, $81, $56, $C4, $82, $D, $C4
                dc.b    $82, $F, $C3, $F, $C3, $2E, $81, $F, $81, $35
                dc.b    $85, $D, $82, $1D, $C4, 1, $C3, $3E, $81, $49
                dc.b    $C4, $82, 7, $C4, $82, $15, $C3, 9, $C3, $34
                dc.b    $81, 9, $81, 0, $F, $D, 8, 9, $1B, $18
                dc.b    $1B, 4, 0, 5, 2, $B, 4, $16, $A, 6
                dc.b    $13, 3, $19, 7, 0, 7, $A, $1F, 4, $1F
                dc.b    $10, $E, $F, $11, $F, $17, $A, 4, 7, 5
                dc.b    $A, $14, $1F, $C, $1F, $17, 4, $15, $14, $10
                dc.b    $16, $F, 2, $18, 6, 0
Level_Data34:   dc.b    $68, $C8, $8F, $1F, $C7, $77, $C6, $C6, $34, $C8  ; was: byte_1B8C8
                dc.b    $82, $10, $83, $1F, $C7, $31, $C8, $82, 2, $83
                dc.b    $1F, $C7, $4E, $C4, $82, $16, $83, $1F, $C6, $2B
                dc.b    $C4, $82, 4, $83, 1, $83, 0, $F, 2, 5
                dc.b    $A, $19, $18, $F, 7, 0, 3, 2, 7, $19
                dc.b    3, $1A, 6, 0, $F, 9, $D, $E, $11, $E
                dc.b    $11, $15, $14, $15, $A, $19, 4, 4, 3, $C
                dc.b    7, $F, $12, 8, $11, 4, $13, 7, $17, $11
                dc.b    $1B, 3, $1F, $B
Level_Data35:   dc.b    5, $C4, 5, $C4, 9, $C4, 5, $C4, $47, $C4  ; was: byte_1B91C
                dc.b    $81, 7, $82, 5, $C4, $81, 7, $82, $F, $C3
                dc.b    $F, $C3, $26, $89, 7, $89, $63, $85, 5, $C4
                dc.b    $8C, 5, $C4, $83, 4, $C3, $11, $C3, $29, $84
                dc.b    7, $8B, 7, $83, $60, $8A, 5, $C3, $82, 5
                dc.b    $C7, $88, 9, $C6, 7, $C2, $F, $C5, $82, 1
                dc.b    $C5, $82, 8, $81, 8, $C3, $82, 1, $C5, $82
                dc.b    7, $C4, $1B, $C3, 2, $81, $13, $82, 2, $82
                dc.b    $1B, $C2, 6, $81, $16, $82, 3, $82, 0, $F
                dc.b    $17, $10, $A, 0, $11, $10, 4, 0, 0, 0
                dc.b    $B, $B, $14, $B, $1E, $B, $1D, $12, 2, $12
                dc.b    0, $B, 4, 3, 3, $C, 3, 7, $B, $E
                dc.b    $11, 4, $11, $11, $18, $B, $13, 3, $1C, 3
                dc.b    0, 0
empty_block_2:  ; dc.b [$465F]$FF
                org     $1FFFF
RomEndData:     dc.b    $FF  ; was: byte_1FFFF
