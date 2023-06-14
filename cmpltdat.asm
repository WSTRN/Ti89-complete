;copyright 2004 Samuel Stearley

;-Word flag, true if the database is indexed
;		 false if not indexed.
;	Then maybe the indexing:
;		word	-offset to letter a
;		word	-number of strings beginning with an a
;		word	-offset to letter b
;		word	-number of strings beginning with an b
;
;		....And so forth
;
;		word	-offset to letter z
;		word	-number of strings beginning with an z
;		word	-offset to non-alphabetical
;		word	-number of strings beginning with an non-alphabetical
;			 character
;
;-offset to the end zero of the external database
;	zero if no external database
;-number of strings-1
;	negative if no strings
;-offset to lower case version
;	zero if no lower case version
;-title
;-string data
;-All lower case string data


	include	"os.h"

 ifd ti89
	xdef		_ti89
 endc

 ifd ti92plus
	xdef		_ti92plus
 endc

	xdef		_nostub


	bra.s		AfterOffsets
l:	dc.w		start-l
	dc.w		variables-l
	dc.w		caseInsensitiveTable-l
AfterOffsets:

;---Backup the screen------

	movem.l	d0-d7/a0-a6,-(a7)
	lea		LCD_MEM,a0
	move.w	#959,d0
Backup:
	move.l	(a0)+,-(a7)
	dbra		d0,Backup
	move.l	200,a6

;---make my box-----------

MakeMenu:
	moveq		#-1,d0
	lea		LCD_MEM+2*30,a0
	moveq		#77,d1
	moveq		#1,d2
	move.l	#$80000000,d3
	moveq		#8,d4
	moveq		#14,d5
	move.l	d0,(a0)+		;the top line
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
PartOfMenu:
	add.l		d5,a0
	move.l	d3,(a0)+
	clr.l		(a0)+
	clr.l		(a0)+
	move.l	d2,(a0)+
	dbra		d4,PartOfMenu
	add.l		d5,a0
	move.l	d0,(a0)+		;dividing line
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
PartOfMenu2:
	add.l		d5,a0
	move.l	d3,(a0)+
	clr.l		(a0)+
	clr.l		(a0)+
	move.l	d2,(a0)+
	dbra		d1,PartOfMenu2
	add.l		d5,a0
	move.l	d0,(a0)+		;bottom line
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+

;---Display the text---------------------

	move.w	#1,-(a7)
	move.l	1596(a6),a0
	jsr		(a0)			;set the font to medium
	addq.l	#2,a7
	move.l	1700(a6),a2		;get the text display rom call
	move.w	#4,-(a7)		;color
	pea		title(pc)
	move.l	#2*65536+4,-(a7)
	jsr		(a2)
	addq.l	#8,a7
	lea		variables(pc),a3

;---The first option togles the size of the menu--

	lea		option1_1(pc),a0
	tst.w		(a3)+
	beq		.l1
	lea		option1_2(pc),a0
.l1
	move.l	a0,-(a7)
	move.l	#2*65536+14,-(a7)
	jsr		(a2)
	addq.l	#8,a7

;---The second option lets the menu move with the cursor---

	lea		option2_1(pc),a0
	tst.w		(a3)+
	beq		.l2
	lea		option2_2(pc),a0
.l2
	move.l	a0,-(a7)
	move.l	#2*65536+23,-(a7)
	jsr		(a2)
	addq.l	#8,a7

;---The Third option dictates usage of _xtrast1----

	lea		option3_1(pc),a0
	tst.w		(a3)+
	beq		.l3
	lea		option3_2(pc),a0
.l3
	move.l	a0,-(a7)
	move.l	#2*65536+32,-(a7)
	jsr		(a2)
	addq.l	#8,a7

;---And now the keypress settings---------

	pea		option4(pc)
	move.l	#2*65536+41,-(a7)
	jsr		(a2)
	addq.l	#8,a7

	pea		option5(pc)
	move.l	#2*65536+50,-(a7)
	jsr		(a2)
	addq.l	#8,a7

	pea		option6(pc)
	move.l	#2*65536+59,-(a7)
	jsr		(a2)
	addq.l	#8,a7

;---And now the external usage of underscores----

	lea		option7_1(pc),a0
	addq.l	#6,a3
	tst.w		(a3)+
	beq		.l4
	lea		option7_2(pc),a0
.l4
	move.l	a0,-(a7)
	move.l	#2*65536+68,-(a7)
	jsr		(a2)
	lea		10(a7),a7

;---Get a keypress-----

GetAnotherKeypress:
	clr.l		-(a7)
	clr.w		-(a7)
	move.l	1528(a6),a0
	jsr		(a0)
	addq.l	#6,a7
	cmp.w		#'1',d0
	bne		NoToggleMenuSize

;---Toggle the size------

	lea		variables(pc),a3
	tst.w		(a3)
	beq		Make1
	clr.w		(a3)
	bra		MakeMenu
Make1:
	move.w	#1,(a3)
	bra		MakeMenu
NoToggleMenuSize:
	cmp.w		#'2',d0
	bne		NoToggleMenuMoves

;---Toggle the menu moves flag------

	lea		variables+2(pc),a3
	not.w		(a3)
	bra		MakeMenu
NoToggleMenuMoves:
	cmp.w		#'3',d0
	bne		NoToggleXtrast1Usage

;---Toggle the usage of xtrast1 flag---

	lea		variables+4(pc),a3
	not.w		(a3)
	bra		MakeMenu
NoToggleXtrast1Usage:

;----key responses to 4, 5, and 6--------

	lea		variables+6(pc),a3
	cmp.w		#'4',d0
	beq		LoadKeypress
	addq.l	#2,a3
	cmp.w		#'5',d0
	beq		LoadKeypress
	addq.l	#2,a3
	cmp.w		#'6',d0
	beq		LoadKeypress

;----toggle the usage of underscores in external dbs-------

	cmp.w		#'7',d0
	bne		NoToggleUnderscore
	lea		useUnderscore(pc),a3
	not.w		(a3)
	bra		MakeMenu
NoToggleUnderscore:
	cmp.w		#264,d0	;escape
	bne		GetAnotherKeypress

;---Restore the screen------

	lea		LCD_MEM+3840,a0
	move.w	#959,d0
Backup2:
	move.l	(a7)+,-(a0)
	dbra		d0,Backup2
	pea		site(pc)
	move.l	920(a6),a0
	jsr		(a0)			;print help
	addq.l	#4,a7
	movem.l	(a7)+,d0-d7/a0-a6
	rts

;---Get a keypress and store it to (a3)---------

LoadKeypress:
	move.w	#0,-(a7)
	pea		prompt(pc)
	move.l	#1*65536+84,-(a7)
	jsr		(a2)
	clr.l		-(a7)
	clr.w		-(a7)
	move.l	1528(a6),a0
	jsr		(a0)
	lea		16(a7),a7
	move.w	d0,(a3)
	bra		MakeMenu

site:		dc.b		"http://www.stearley.org",0
title: 	dc.b		"COMPLETE'S SETTINGS:",0
option1_1:	dc.b		"1:Menu is Small",0
option1_2:	dc.b		"1:Menu is Large",0
option2_1:	dc.b		"2:Menu Stays Still",0
option2_2:	dc.b		"2:Menu Moves",0
option3_1:	dc.b		"3:Use _xtrast1",0
option3_2:	dc.b		"3:Skip _xtrast1",0
option4:	dc.b		"4:Set Right Key",0
option5:	dc.b		"5:Set Much Right Key",0
option6:	dc.b		"6:Set Left Key",0
prompt:	dc.b		"   Enter Keypress    ",0
option7_1:	dc.b		"7:Extrnal DBs use _",0
option7_2:	dc.b		"7:Extrnal DBs skip _",0


	EVEN

variables:
	dc.w	1		;the size of the menu 	0-small/1-big
	dc.w	0		;menu moves flag 		0-no moving/not zero-moves
	dc.w	0		;use _xtrast1		0-use it/not zero-do not use it

 ifd ti89
	dc.w	344		;the 'right' keypress
	dc.w	4440		;the 'much right' keypress
	dc.w	338		;the 'left' keypress
 endc

 ifd ti92plus
	dc.w	340
	dc.w	4436
	dc.w	337
 endc

useUnderscore:
	dc.w	0	;external uses an underscore



	EVEN

start:
	dc.w		systemVariableText-start
	dc.w		unitOffsetTable-start

	EVEN	

mainDatabase:
	dc.w	1
	dc.w	la-b,9,lb-b,-1,lc-b,13,ld-b,7,le-b,7,lf-b,5,lg-b,4,lh-b,-1,li-b,6
	dc.w	lj-b,-1,lk-b,-1,ll-b,9,lm-b,9,ln-b,7
	dc.w	lo-b,2,lp-b,6,lq-b,2,lr-b,18,ls-b,16,lt-b,7,lu-b,2,lv-b,0
	dc.w	lw-b,0,lx-b,0,ly-b,-1,lz-b,0,oddBalls-b,17

	dc.w	secondDatabase-mainDatabase
	dc.w	160				;number of strings-1 if negative then no strings at all
	dc.w	mainEnd-mainStart
	dc.b	"COMPLETE",0		;title
mainStart:
b:
la:
	dc.b	"abs(",0,"ans(",0,"and ",0,"approx(",0,"arcLen(",0,"avgRC(",0
	dc.b	"augment(",0,"angle(",0,"Archive ",0
lb:
lc:
	dc.b	"cSolve(",0,"cFactor(",0,"cZeros(",0
	dc.b	"crossP(",0,"cosh(",0,"cosh",180,"(",0,"comDenom(",0,"conj(",0
	dc.b	"char(",0,"colDim(",0,"colNorm(",0,"ceiling(",0,"CubicReg ",0
	dc.b	"cumSum(",0
ld:
	dc.b	"deSolve(",0,"det(",0,"diag(",0,"dim(",0,"dotP(",0
	dc.b	"Define ",0,"DelFold ",0,"DelVar ",0
le:
	dc.b	"expand(",0,"exp",18,"list(",0,"expr(",0,"eigVc(",0
	dc.b	"eigVl(",0,"entry(",0,"exact(",0,"ExpReg ",0
lf:
	dc.b	"factor(",0,"floor(",0
	dc.b	"fmax(",0,"fmin(",0,"format(",0,"fPart(",0
lg:
	dc.b	"gcd(",0,"getDenom(",0
	dc.b	"getNum(",0,"Graph ",0,"getConfg()",0
lh:
li:
	dc.b	"identity(",0,"imag(",0,"int(",0,"intDiv(",0
	dc.b	"iPart(",0,"isPrime(",0,"inString(",0
lj:
lk:
ll:
	dc.b	"log(",0,"lcm(",0,"left(",0
	dc.b	"limit(",0,"list",18,"mat(",0,"LinReg ",0,"LnReg ",0,"Logistic ",0
	dc.b	"LU ",0,"Lock ",0
lm:
	dc.b	"mat",18,"list(",0
	dc.b	"max(",0,"mean(",0,"median(",0,"mid(",0
	dc.b	"min(",0,"mod(",0,"mRow(",0,"mRowAdd(",0,"MedMed ",0
ln:
	dc.b	"nCr(",0,"nPr(",0
	dc.b	"nDeriv(",0,"nSolve(",0,"nInt(",0,"norm(",0,"not ",0,"NewProb",0
lo:
	dc.b	"or ",0,"ord(",0,"OneVar ",0
lp:
	dc.b	"part(",0,"polyEval(",0,"product(",0
	dc.b	"propFrac(",0,"P",18,"Rx(",0,"P",18,"Ry(",0,"PowerReg ",0
lq:
	dc.b	"QR ",0
	dc.b	"QuadReg ",0,"QuartReg ",0
lr:
	dc.b	"rand(",0,"randMat(",0,"randNorm(",0
	dc.b	"randPoly(",0,"real(",0,"ref(",0,"remain(",0,"right(",0,"rotate(",0
	dc.b	"round(",0,"rowAdd(",0,"rowDim(",0,"rowNorm(",0,"rowSwap(",0
	dc.b	"rref(",0,"R",18,"P",136,"(",0,"R",18,"Pr(",0,"RandSeed ",0,"root(",0
ls:
	dc.b	"sinh(",0,"sinh",180,"(",0,"solve(",0,"seq(",0,"shift(",0,"sign(",0
	dc.b	"simult(",0,"stdDev(",0,"string(",0,"subMat(",0,"sum(",0,"ShowStat",0
	dc.b	"SinReg ",0,"SortA ",0,"SortD ",0,"switch(",0,"stDevPop(",0
lt:
	dc.b	"tanh(",0,"tanh",180,"(",0
	dc.b	"taylor(",0,"tCollect(",0,"tExpand(",0,"tmpCnv(",0,"true",0
	dc.b	"TwoVar ",0
lu:
	dc.b	"unitV(",0,"Unarchiv ",0,"UnLock ",0
lv:
	dc.b	"variance(",0
lw:
	dc.b	"when(",0
lx:
	dc.b	"xor ",0
ly:
lz:
	dc.b	"zeros(",0
oddBalls:
	dc.b	" xor ",0," and ",0," or ",0,132,"List(",0,18,"Bin",0,18,"Dec",0,18,"Hex",0
	dc.b	18,"Cylind",0,18,"DD",0,18,"DMS",0,18,"Polar",0,18,"Rect",0,18,"Sphere",0
	dc.b	132,"tmpCnv(",0,18,"ln",0,18,"logbase(",0,18,"Grad",0,18,"Rad",0
mainEnd:

mainTextLowerCase:
	dc.b	0

	dc.b	"abs(",0,"ans(",0,"and ",0,"approx(",0,"arclen(",0,"avgrc(",0
	dc.b	"augment(",0,"angle(",0,"archive ",0

	dc.b	"csolve(",0,"cfactor(",0,"czeros(",0
	dc.b	"crossp(",0,"cosh(",0,"cosh",180,"(",0,"comdenom(",0,"conj(",0
	dc.b	"char(",0,"coldim(",0,"colnorm(",0,"ceiling(",0,"cubicreg ",0
	dc.b	"cumsum(",0

	dc.b	"desolve(",0,"det(",0,"diag(",0,"dim(",0,"dotp(",0
	dc.b	"define ",0,"delfold ",0,"delvar ",0

	dc.b	"expand(",0,"exp",18,"list(",0,"expr(",0,"eigvc(",0
	dc.b	"eigvl(",0,"entry(",0,"exact(",0,"expreg ",0

	dc.b	"factor(",0,"floor(",0
	dc.b	"fmax(",0,"fmin(",0,"format(",0,"fpart(",0

	dc.b	"gcd(",0,"getdenom(",0
	dc.b	"getnum(",0,"graph ",0,"getconfg()",0

	dc.b	"identity(",0,"imag(",0,"int(",0,"intdiv(",0
	dc.b	"ipart(",0,"isprime(",0,"instring(",0

	dc.b	"log(",0,"lcm(",0,"left(",0
	dc.b	"limit(",0,"list",18,"mat(",0,"linreg ",0,"lnreg ",0,"logistic ",0
	dc.b	"lu ",0,"lock ",0

	dc.b	"mat",18,"list(",0,"max(",0,"mean(",0,"median(",0,"mid(",0
	dc.b	"min(",0,"mod(",0,"mrow(",0,"mrowadd(",0,"medmed ",0

	dc.b	"ncr(",0,"npr(",0
	dc.b	"nderiv(",0,"nsolve(",0,"nint(",0,"norm(",0,"not ",0,"newprob",0

	dc.b	"or ",0,"ord(",0,"onevar ",0

	dc.b	"part(",0,"polyeval(",0,"product(",0
	dc.b	"propfrac(",0,"p",18,"rx(",0,"p",18,"ry(",0,"powerreg ",0

	dc.b	"qr ",0
	dc.b	"quadreg ",0,"quartreg ",0

	dc.b	"rand(",0,"randmat(",0,"randnorm(",0
	dc.b	"randpoly(",0,"real(",0,"ref(",0,"remain(",0,"right(",0,"rotate(",0
	dc.b	"round(",0,"rowadd(",0,"rowdim(",0,"rownorm(",0,"rowswap(",0
	dc.b	"rref(",0,"r",18,"p",136,"(",0,"r",18,"pr(",0,"randseed ",0,"root(",0

	dc.b	"sinh(",0,"sinh",180,"(",0,"solve(",0,"seq(",0,"shift(",0,"sign(",0
	dc.b	"simult(",0,"stddev(",0,"string(",0,"submat(",0,"sum(",0,"showstat",0
	dc.b	"sinreg ",0,"sorta ",0,"sortd ",0,"switch(",0,"stdevpop(",0

	dc.b	"tanh(",0,"tanh",180,"(",0
	dc.b	"taylor(",0,"tcollect(",0,"texpand(",0,"tmpcnv(",0,"true",0
	dc.b	"twovar ",0

	dc.b	"unitv(",0,"unarchiv ",0,"unlock ",0

	dc.b	"variance(",0

	dc.b	"when(",0

	dc.b	"xor ",0

	dc.b	"zeros(",0

	dc.b	" xor ",0," and ",0," or ",0,132,"list(",0,18,"bin",0,18,"dec",0,18,"hex",0
	dc.b	18,"cylind",0,18,"dd",0,18,"dms",0,18,"polar",0,18,"rect",0,18,"sphere",0
	dc.b	132,"tmpcnv(",0,18,"ln",0,18,"logbase(",0,18,"grad",0,18,"rad",0


	EVEN	

systemVariableText:
	dc.w	0
	dc.w	(externalSystemDatabase-systemVariableText)
	dc.w	111
	dc.w	systemEnd-systemBegin
	dc.b	"SYSTEM VARIABLES",0
systemBegin:
	dc.b	154,":    S",0,155,":    S",0
	dc.b	"corr: S",0,"maxX: S",0,"maxY: S",0,"medStat: S",0,"medx1: S",0,"medx2: S",0
	dc.b	"medx3: S",0,"medy1: S",0,"medy2: S",0,"medy3: S",0,"minX:  S",0,"minY:  S",0
	dc.b	"nStat: S",0,"q1:    S",0,"q3:   S",0,"regCoef: S",0,"regEq(: S",0,"seed1:  S",0
	dc.b	"seed2:  S",0,"Sx:  S",0,"Sy:  S",0,142,"x:  S",0,142,"xy: S",0,142,"y:  S",0
	dc.b	142,"x",178,": S",0,142,"y",178,": S",0,"R",178,":  S",0,143,"x:  S",0
	dc.b	143,"y:  S",0,"errornum",0,"sysMath",0,"tblInput",0,"tblStart",0,"xfact",0
	dc.b	"xmax",0,"xmin",0,"xres",0,"xscl",0,"yfact",0,"ymax",0,"ymin",0,"yscl",0
	dc.b	"zeye",136,0,"zeye",145,0,"zeye",146,0,"zfact",0,"znmax",0,"znmin",0
	dc.b	"zpltstep",0,"zpltstrt",0,"zt0de",0,"ztstep",0,"ztstepde",0,"zxgrid",0
	dc.b	"zxmax",0,"zxmin",0,"zxres",0,"zxscl",0,"zygrid",0,"zymax",0,"zymin",0
	dc.b	"zyscl",0,"zzmax",0,"zzmin",0,"zzscl",0,"z",136,"max",0,"z",136,"min",0
	dc.b	"z",136,"step",0,132,"tbl",0,"nc:",0,"ok:",0,"rc:",0,"tc:",0,"xc:",0,"yc:",0
	dc.b	"zc:",0,"ztmax",0,"ztmaxde",0,"ztmin",0,"ztplotde",0,136,"c:",0,"xgrid",0
	dc.b	"ygrid",0,132,"x:",0,132,"y:",0,"zmin",0,"zmax",0,"zscl",0,"eye",136,0
	dc.b	"eye",145,0,"eye",146,0,"ncontour",0,136,"min",0,136,"max",0,136,"step",0
	dc.b	"tmin",0,"tmax",0,"tstep",0,"t0:",0,"tplot",0,"ncurves",0,"diftol",0
	dc.b	"dtime",0,"Estep",0,"fldpic",0,"fldres",0,"nmin",0,"nmax",0,"plotStrt",0
	dc.b	"plotStep",0
systemEnd:

	dc.b	0
	dc.b	154,":     ",0,155,":     ",0
	dc.b	"corr:  ",0,"maxx:  ",0,"maxy:  ",0,"medstat:  ",0,"medx1:  ",0,"medx2:  ",0
	dc.b	"medx3:  ",0,"medy1:  ",0,"medy2:  ",0,"medy3:  ",0,"minx:   ",0,"miny:   ",0
	dc.b	"nstat:  ",0,"q1:     ",0,"q3:    ",0,"regcoef:  ",0,"regeq(:  ",0,"seed1:   ",0
	dc.b	"seed2:   ",0,"sx:   ",0,"sy:   ",0,142,"x:   ",0,142,"xy:  ",0,142,"y:   ",0
	dc.b	142,"x",178,":  ",0,142,"y",178,":  ",0,"r",178,":   ",0,143,"x:   ",0
	dc.b	143,"y:   ",0,"errornum",0,"sysmath",0,"tblinput",0,"tblstart",0,"xfact",0
	dc.b	"xmax",0,"xmin",0,"xres",0,"xscl",0,"yfact",0,"ymax",0,"ymin",0,"yscl",0
	dc.b	"zeye",136,0,"zeye",145,0,"zeye",146,0,"zfact",0,"znmax",0,"znmin",0
	dc.b	"zpltstep",0,"zpltstrt",0,"zt0de",0,"ztstep",0,"ztstepde",0,"zxgrid",0
	dc.b	"zxmax",0,"zxmin",0,"zxres",0,"zxscl",0,"zygrid",0,"zymax",0,"zymin",0
	dc.b	"zyscl",0,"zzmax",0,"zzmin",0,"zzscl",0,"z",136,"max",0,"z",136,"min",0
	dc.b	"z",136,"step",0,132,"tbl",0,"nc:",0,"ok:",0,"rc:",0,"tc:",0,"xc:",0,"yc:",0
	dc.b	"zc:",0,"ztmax",0,"ztmaxde",0,"ztmin",0,"ztplotde",0,136,"c:",0,"xgrid",0
	dc.b	"ygrid",0,132,"x:",0,132,"y:",0,"zmin",0,"zmax",0,"zscl",0,"eye",136,0
	dc.b	"eye",145,0,"eye",146,0,"ncontour",0,136,"min",0,136,"max",0,136,"step",0
	dc.b	"tmin",0,"tmax",0,"tstep",0,"t0:",0,"tplot",0,"ncurves",0,"diftol",0
	dc.b	"dtime",0,"estep",0,"fldpic",0,"fldres",0,"nmin",0,"nmax",0,"plotstrt",0
	dc.b	"plotstep",0


	EVEN	

	dc.w	shortcutText-unitOffsetTable
unitOffsetTable:
base:
	dc.w	u1-base,uE-base,u2-base,u3-base,u4-base,u5-base,u6-base
	dc.w	u7-base,u8-base,u9-base,u10-base,u11-base,u12-base,u13-base
	dc.w	u14-base,u15-base,u16-base,u17-base,u18-base,u19-base,u20-base
	dc.w	u21-base,u22-base,u23-base,u24-base,u25-base,u26-base,u27-base
	dc.w	u28-base,u29-base,u30-base,u31-base

 EVEN	

u1:	dc.w	0
	dc.w	(n1-u1)-1,19,u1E-u1s
	dc.b	"Constants",0
u1s
	dc.b	"_c:   Spd Lt",0,"_Cc:  Colomb",0,"_g:   G Erth",0,"_Gc:  Grav C",0
	dc.b	"_h:   Planck",0,"_k:   Botzmn",0,"_Me:  Electn",0,"_Mn:  Nuetrn",0
	dc.b	"_Mp:  Proton",0,"_Na:  Avagdo",0,"_q:   E Chrg",0,"_Rb:  Bhr Rd",0
	dc.b	"_Rc:  Mol Gs",0,"_Rdb:  Rdbrg",0,"_Vm:  Mol Vl",0,"_",134,"0:  Pt Vac",0
	dc.b	"_",143,":   Stf-Bo",0,"_",145,"0:  Mg Flx",0,"_",181,"0:  PM Vac",0
	dc.b	"_",181,"b:  Bhr Mg",0
u1E
	dc.b	0
	dc.b	"_c:         ",0,"_cc:        ",0,"_g:         ",0,"_gc:        ",0
	dc.b	"_h:         ",0,"_k:         ",0,"_me:        ",0,"_mn:        ",0
	dc.b	"_mp:        ",0,"_na:        ",0,"_q:         ",0,"_rb:        ",0
	dc.b	"_rc:        ",0,"_rdb:       ",0,"_vm:        ",0,"_",134,"0:        ",0
	dc.b	"_",143,":         ",0,"_",145,"0:        ",0,"_",181,"0:        ",0
	dc.b	"_",181,"b:        ",0



 EVEN 

uE:
	dc.w	0
	dc.w	(nE-uE)-1,3,0
	dc.b	"Earth Constants",0
	dc.b	0,"_emass",0,"_erad",0,"_edsun",0,"_edmoon",0


 EVEN	

u2:	dc.w	0
	dc.w	(n2-u2)-1,18,u2E-u2s
	dc.b	"Length",0
u2s
	dc.b	"_Ang",0,"_au",0,"_cm",0,"_fath",0,"_fm",0,"_ft",0,"_in",0
	dc.b	"_km",0,"_ltyr",0,"_m:",0,"_mi",0,"_mil:_in",149,173,"3",0,"_mm",0,"_Nmi",0
	dc.b	"_pc",0,"_rod",0,"_yd",0,"_",181,":",0,"_",197,":",0
u2E
	dc.b	0
	dc.b	"_ang",0,"_au",0,"_cm",0,"_fath",0,"_fm",0,"_ft",0,"_in",0
	dc.b	"_km",0,"_ltyr",0,"_m:",0,"_mi",0,"_mil:   ",149,173,"3",0,"_mm",0,"_nmi",0
	dc.b	"_pc",0,"_rod",0,"_yd",0,"_",181,":",0,"_",197,":",0



 EVEN	

u3:	dc.w	0
	dc.w	(n3-u3)-1,3,0
	dc.b	"Area",0,0,"_acre",0,"_ha",0,"_m^2",0,"_in^2",0


 EVEN	

u4:	dc.w	0
	dc.w	(n4-u4)-1,9,u4E-u4s
	dc.b	"Volume",0
u4s
	dc.b	"_cup",0,"_floz",0,"_flozUK",0,"_gal",0,"_galUK",0,"_l:",0
	dc.b	"_ml",0,"_pt",0,"_qt",0,"_tbsp",0
u4E
	dc.b	0
	dc.b	"_cup",0,"_floz",0,"_flozuk",0,"_gal",0,"_galuk",0,"_l:",0
	dc.b	"_ml",0,"_pt",0,"_qt",0,"_tbsp",0



 EVEN	

u5:	dc.w	0
	dc.w	(n5-u5)-1,8,0
	dc.b	"Time",0,0
	dc.b	"_day",0,"_hr",0,"_min",0,"_ms",0,"_ns",0,"_s:",0
	dc.b	"_week",0,"_yr",0,"_",181,"s",0




 EVEN	

u6:	dc.w	0
	dc.w	(n6-u6)-1,3,0
	dc.b	"Velocity",0,0
	dc.b	"_knot",0,"_kph",0,"_mph",0,"_m/_s",0




 EVEN	

u7:	dc.w	0
	dc.w	(n7-u7)-1,0,0
	dc.b	"Acceleration",0,0,"_m/_s^2",0




 EVEN	

u8:	dc.w	0
	dc.w	(n8-u8)-1,3,u8E-u8s
	dc.b	"Temperature",0
u8s:
	dc.b	"_",176,"C",0,"_",176,"F",0,"_",176,"K",0,"_",176,"R",0
u8E
	dc.b	0
	dc.b	"_",176,"c",0,"_",176,"f",0,"_",176,"k",0,"_",176,"r",0




 EVEN	

u9:	dc.w	0
	dc.w	(n9-u9)-1,0,0
	dc.b	"Luminus Intensity",0,0,"_cd",0




 EVEN	

u10:	dc.w	0
	dc.w	(n10-u10)-1,0,0
	dc.b	"Amount of Substance",0,0,"_mol",0




 EVEN	

u11:	dc.w	0
	dc.w	(n11-u11)-1,10,u11E-u11s
	dc.b	"Mass",0
u11s
	dc.b	"_amu",0,"_gm",0,"_kg",0,"_lb",0,"_mg",0,"_mton",0
	dc.b	"_oz",0,"_slug",0,"_ton",0,"_tonne",0,"_tonUK",0
u11E
	dc.b	0
	dc.b	"_amu",0,"_gm",0,"_kg",0,"_lb",0,"_mg",0,"_mton",0
	dc.b	"_oz",0,"_slug",0,"_ton",0,"_tonne",0,"_tonuk",0




 EVEN	

u12:	dc.w	0
	dc.w	(n12-u12)-1,4,u12E-u12s
	dc.b	"Force",0
u12s
	dc.b	"_dyne",0,"_kgf",0,"_lbf",0,"_N:",0,"_tonf",0
u12E
	dc.b	0
	dc.b	"_dyne",0,"_kgf",0,"_lbf",0,"_n:",0,"_tonf",0




 EVEN	

u13:	dc.w	0
	dc.w	(n13-u13)-1,8,u13E-u13s
	dc.b	"Energy",0
u13s
	dc.b	"_Btu",0,"_cal",0,"_erg",0,"_eV",0,"_ftlb",0
	dc.b	"_J:",0,"_kcal",0,"_kWh",0,"_latm",0
u13E
	dc.b	0
	dc.b	"_btu",0,"_cal",0,"_erg",0,"_ev",0,"_ftlb",0
	dc.b	"_j:",0,"_kcal",0,"_kwh",0,"_latm",0



 EVEN	

u14:	dc.w	0
	dc.w	(n14-u14)-1,2,u14E-u14s
	dc.b	"Power",0
u14s
	dc.b	"_hp",0,"_kW",0,"_W:",0
u14E
	dc.b	0
	dc.b	"_hp",0,"_kw",0,"_w:",0




 EVEN	

u15:	dc.w	0
	dc.w	(n15-u15)-1,8,u15E-u15s
	dc.b	"Pressure",0
u15s
	dc.b	"_atm",0,"_bar",0,"_inH2O",0,"_inHg",0,"_mmH2O",0
	dc.b	"_mmHg",0,"_pa",0,"_psi",0,"_torr",0
u15E
	dc.b	0
	dc.b	"_atm",0,"_bar",0,"_inh2O",0,"_inhg",0,"_mmh2O",0
	dc.b	"_mmhg",0,"_pa",0,"_psi",0,"_torr",0




 EVEN	

u16:	dc.w	0
	dc.w	(n16-u16)-1,0,u16E-u16s
	dc.b	"Viscosity, Kinematic",0
u16s
	dc.b	"_St",0
u16E
	dc.b	0
	dc.b	"_st",0




 EVEN	

u17:	dc.w	0
	dc.w	(n17-u17)-1,0,u17E-u17s
	dc.b	"Viscosity, Dynamic",0
u17s
	dc.b	"_P:",0
u17E
	dc.b	0
	dc.b	"_p:",0



 EVEN	

u18:	dc.w	0
	dc.w	(n18-u18)-1,3,u18E-u18s
	dc.b	"Frequency",0
u18s
	dc.b	"_GHz",0,"_Hz",0,"_kHz",0,"_MHz",0
u18E
	dc.b	0
	dc.b	"_ghz",0,"_hz",0,"_khz",0,"_mhz",0




 EVEN	

u19:	dc.w	0
	dc.w	(n19-u19)-1,3,u19E-u19s
	dc.b	"Electric Current",0
u19s
	dc.b	"_A:",0,"_kA",0,"_mA",0,"_",181,"A",0
u19E
	dc.b	0
	dc.b	"_a:",0,"_ka",0,"_ma",0,"_",181,"a",0




 EVEN	

u20:	dc.w	0
	dc.w	(n20-u20)-1,0,0
	dc.b	"Charge",0,0,"_coul",0




 EVEN	

u21:	dc.w	0
	dc.w	(n21-u21)-1,3,u21E-u21s
	dc.b	"Potential",0
u21s
	dc.b	"_kV",0,"_mV",0,"_V:",0,"_volt",0
u21E
	dc.b	0
	dc.b	"_kv",0,"_mv",0,"_v:",0,"_volt",0




 EVEN	

u22:	dc.w	0
	dc.w	(n22-u22)-1,3,u22E-u22s
	dc.b	"Resistance",0
u22s:
	dc.b	"_k",147,0,"_M",147,0,"_ohm",0,"_",147,":",0
u22E
	dc.b	0
	dc.b	"_k",147,0,"_m",147,0,"_ohm",0,"_",147,":",0




 EVEN	

u23:	dc.w	0
	dc.w	(n23-u23)-1,3,0
	dc.b	"Conductance",0,0,"_mho",0,"_mmho",0,"_siemens",0,"_",181,"mho",0



 EVEN	

u24:	dc.w	0
	dc.w	(n24-u24)-1,3,u24E-u24s
	dc.b	"Capacitance",0,
u24s
	dc.b	"_F:",0,"_nF",0,"_pF",0,"_",181,"F",0
u24E
	dc.b	0
	dc.b	"_f:",0,"_nf",0,"_pf",0,"_",181,"f",0





 EVEN	

u25:	dc.w	0
	dc.w	(n25-u25)-1,0,u25E-u25s
	dc.b	"Mag Field Strength",0
u25s
	dc.b	"_Oe",0
u25E
	dc.b	0
	dc.b	"_oe",0




 EVEN	

u26:	dc.w	0
	dc.w	(n26-u26)-1,1,u26E-u26s
	dc.b	"Mag Flux Density",0
u26s
	dc.b	"_Gs:   Gauss",0,"_T:    Tesla",0	
u26E
	dc.b	0
	dc.b	"_gs:        ",0,"_t:         ",0	




 EVEN

u27:	dc.w	0
	dc.w	(n27-u27)-1,0,u27E-u27s
	dc.b	"Magnetic Flux",0
u27s
	dc.b	"_Wb",0
u27E
	dc.b	0
	dc.b	"_wb",0




 EVEN	

u28:	dc.w	0
	dc.w	(n28-u28)-1,3,u28E-u28s
	dc.b	"Inductance",0
u28s
	dc.b	"_henry",0,"_mH",0,"_nH",0,"_",181,"H",0
u28E
	dc.b	0
	dc.b	"_henry",0,"_mh",0,"_nh",0,"_",181,"h",0




	EVEN

u31:	dc.w	0
	dc.w	(firstDb-u31),-1,0	;has external but no internal
	dc.b	"External Strings",0

 EVEN	

u29:	dc.w	0
	dc.w	0,30,0
	dc.b	"Complete's Variables",0,0
	dc.b	"_xtrast1"
firstDb	dc.b	0
	dc.b	"_xtrast2"
secondDatabase:	dc.b	0
	dc.b	"_sysext"
externalSystemDatabase:	dc.b	0
	dc.b	"_cnstant",0
n1	dc.b	"_earthcn",0
nE	dc.b	"_length",0
n2	dc.b	"_area",0
n3	dc.b	"_volume",0
n4	dc.b	"_time",0
n5	dc.b	"_veloc",0
n6	dc.b	"_accel",0
n7	dc.b	"_temp",0
n8	dc.b	"_linten",0
n9	dc.b	"_amount",0
n10	dc.b	"_mass",0
n11	dc.b	"_force",0
n12	dc.b	"_energy",0
n13	dc.b	"_power",0
n14	dc.b	"_press",0
n15	dc.b	"_viscok",0
n16	dc.b	"_viscod",0
n17	dc.b	"_freq",0
n18	dc.b	"_ecurent",0
n19	dc.b	"_charge",0
n20	dc.b	"_poten",0
n21	dc.b	"_resist",0
n22	dc.b	"_conduct",0
n23	dc.b	"_capacit",0
n24	dc.b	"_magfstr",0
n25	dc.b	"_magflxd",0
n26	dc.b	"_magflux",0
n27	dc.b	"_induct",0
n28


 EVEN	

u30:	dc.w	0
	dc.w	0,-1,0			;0 means no external
	dc.b	"Variables",0		;just for the help line text

 EVEN	

shortcutText:
	dc.w	0
	dc.w	0,28,0
	dc.b	"Unit Shortcuts",0,0
	dc.b	"c-Constants",0,"l-Length",0,"a-Area",0,"v-Volume",0,"t-Time",0
	dc.b	"m-Mass",0,"f-Force",0,"e-Energy",0,"p-Power",0,"r-Resistnce",0
	dc.b	"k-Vis, Kine",0,"d-Vis, Dyna",0,"i-Current",0,"s-Conduct",0,"g-Mg Flux D",0
	dc.b	"w-Mg Flux",0,"x-External",0,"n-Amount",0,"q-Charge",0,"y-System",0
	dc.b	"z-Velocity",0,"^-Acelerate",0,"b-Temper",0,"j-Lum Inten",0,"o-Pressure",0
	dc.b	"u-Potental",0," -Capacit",0,"Enter-MFStr",0

 ifd ti89
	dc.b	"home-Induct",0
 endc

 ifd ti92plus
	dc.b	"=-Induct",0
 endc


caseInsensitiveTable:
	dc.b	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
	dc.b	26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50
	dc.b	51,52,53,54,55,56,57,58,59,60,61,62,63,64
	dc.b	"abcdefghijklmnopqrstuvwxyz",91,92,93,94,95,96,"abcdefghijklmnopqrstuvwxyz"
	dc.b	123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139
	dc.b	140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158
	dc.b	159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176
	dc.b	177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195
	dc.b	196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215
	dc.b	216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234
	dc.b	236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255

	end	
