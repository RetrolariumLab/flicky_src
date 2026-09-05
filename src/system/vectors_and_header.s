; Exception vector table and ROM header.
; ROM $000000-$0001FF.

off_0:          dc.l    unk_FFFF70
                dc.l    EntryPoint
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    EXT
                dc.l    ErrorTrap
                dc.l    HBLANK
                dc.l    ErrorTrap
                dc.l    VBLANK
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
                dc.l    ErrorTrap
CopyRights:     dc.b    "SEGA MEGA DRIVE (C)SEGA 1991.FEB"
DomesticName:   dc.b    "FLICKY                                                         "
                dc.b    " FLICKY                          GM 00001022-00"
Checksum:       dc.w    $B7E0
Peripherials:   dc.b    "J               "
RomStart:       dc.l    0
RomEnd:         dc.l    byte_1FFFF
RamStart:       dc.l    M68K_RAM
RamEnd:         dc.l    dword_FFFFFC+3
SramCode:       dc.b    "            "
ModemCode:      dc.b    "            "
Reserved:       dc.b    "                                        "
CountryCode:    dc.b    "JUE             "
