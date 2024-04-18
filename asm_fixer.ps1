$env:Path += ';C:\aswcurr\bin'

Set-Location ida

python asm_fixer.py flicky.asm flicky.map

Copy-Item flicky.s ..

Set-Location ..
