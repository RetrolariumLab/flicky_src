$env:Path += ';C:\aswcurr\bin'

Copy-Item flicky.s ida

Set-Location ida

asw -L -maxerrors 10 flicky.s
p2bin flicky.p rom.bin

Copy-Item rom.bin ..

Set-Location ..
