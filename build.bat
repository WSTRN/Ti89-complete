@echo off


del complete.89z
del complete.89y
del cmpltdat.89z

.\a68k.exe complete.asm -g -t -vti89
.\a68k.exe cmpltdat.asm -g -t -vti89
.\makeprgm\makeprgm.exe complete
.\makeprgm\makeprgm.exe cmpltdat
del complete.o > nul
del cmpltdat.o > nul
.\ttppggen.exe complete.89z complete

