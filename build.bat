@echo off


del complete.89z
del complete.89y

.\a68k.exe complete.asm -g -t -vti89
.\makeprgm\makeprgm.exe complete
del complete.o > nul
.\ttppggen.exe complete.89z complete

