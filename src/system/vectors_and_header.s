; Exception vector table and ROM header
; ROM $000000-$0001FF

Sys_VectorTable:    dc.l    Ram_VDPRegisters
                dc.l    Boot_EntryPoint
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Ram_ExtIntTrampoline
                dc.l    Sys_ErrorTrap
                dc.l    Ram_HBlankTrampoline
                dc.l    Sys_ErrorTrap
                dc.l    Ram_VBlankTrampoline
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
                dc.l    Sys_ErrorTrap
CopyRights:     dc.b    "SEGA MEGA DRIVE (C)SEGA 1991.FEB"
DomesticName:   dc.b    "FLICKY                                                         "
                dc.b    " FLICKY                          GM 00001022-00"
Checksum:       dc.w    $B7E0
Peripherials:   dc.b    "J               "
RomStart:       dc.l    0
RomEnd:         dc.l    Sys_RomEndData
RamStart:       dc.l    M68K_RAM
RamEnd:         dc.l    Ram_InitFlag+3
SramCode:       dc.b    "            "
ModemCode:      dc.b    "            "
Reserved:       dc.b    "                                        "
CountryCode:    dc.b    "JUE             "
