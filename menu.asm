;Copyright 2004 Samuel Stearley


;----Inputs---------------------------------------------
;d5.w -> x cordinate, in bytes of where to draw the
;	   menu.
;----Outputs--------------------------------------------
;The menu is drawn.  It is 11 bytes wide.
;Text might be placed in the help line.
;Flags might get set or reset.
;
;In essence, pretty much all graphical stuff is done
;here.
;
;Text also might be pasted and highlighted.
;-------------------------------------------------------
DisplayMenu:

 checkTrashing 'f'


;----First see if there is only one item in the menu and if so
;----place it and highlight it.

	lea		oneThingAllowed(pc),a1	;backspace indicator
	tst.b		(a1)
	bne		StillShowMenu
	move.b	unitIndic(pc),d0
	bne		StillShowMenu
	move.l	ptr(pc),a0
	tst.l		4(a0)
	bne		StillShowMenu
	tst.l		(a0)
	bmi		StillShowMenu		;is the one thing a folder name?

;----So it can be pasted----

	move.l	60(a7),a2			;get event structure
	move.l	(a0),a0
	move.w	charBufferIndex(pc),d3
	ext.l		d3
	sub.l		d3,a0
	move.l	a0,d0
	moveq		#0,d2				;no special file types
	bsr		IsSpecialString2
	add.l		d3,d0
	move.l	d0,a3
	lea		activatedFlag(pc),a5
	st.b		(a5)
	move.l	a2,-(a7)
	move.w	#-2,-(a7)
	move.l	824(a6),a0
	jsr		(a0)				;it has not been displayed so send the event
							;  if it had been displayed at the beginning
							;  then it would have been turned into command
							;  idle


 checkTrashing 'A'

	move.w	#$700,(a2)			;make it command idle

;----make sure no ':' char is in it-------

	move.l	a3,d0
	bsr		RemoveComments
	move.l	d0,a3
PasteString2:

;----Put the text to the entry line-------

	lea		pasteEvent(pc),a0
	move.w	#$723,(a0)			;make sure it is a paste event
	move.l	a0,-(a7)
	move.w	#-2,-(a7)
	move.l	a3,8(a0)			;put pointer to the event
	move.l	824(a6),a4			;get ev send event
	jsr		(a4)				;send it, if the menu is visible it is deleted

 checkTrashing 'B'


;----Highlight the pasted text---

	moveq		#-2,d3
CounterLoop:
	addq.l	#1,d3
	tst.b		(a3)+
	bne		CounterLoop
	lea		shiftBackEvent(pc),a0
	move.l	a0,2(a7)
HighLightLoop:
	jsr		(a4)
	dbra		d3,HighLightLoop
	lea		16(a7),a7
	clr.b		(a5)
	bra		RestoreTheScreenAndRestartBuffer
;--------------------------------------------
;DO THE MENU LIKE NORMAL
;--------------------------------------------
StillShowMenu:
	move.w	mode(pc),d6
	clr.b		(a1)				;clear the One thing allowed flag
	moveq		#1,d0				;set low bit and clear the rest
	moveq		#-128,d1			;set the high bit of the byte
	moveq		#-1,d2			;set all the bits
	moveq		#20,d4			;increment

 ifd ti89
	lea		LCD_MEM+30*22,a1		;the y of where my menu is in video memory
 endc

 ifd ti92plus
	lea		LCD_MEM+30*48,a1
 endc

	tst.w		d6
	beq		LeaveA1Alone

 ifd ti89
	lea		LCD_MEM+60,a1
 endc

 ifd ti92plus
	lea		LCD_MEM+30*28,a1
 endc

LeaveA1Alone:

 checkTrashing 'g'

	lea		menuIndic(pc),a5
	tst.b		(a5)
	bne.s		SkipBackup
	move.l	ptr(pc),a0
	add.l		#(NUMBER_OF_MATCHES+1)*4,a0	;pointer to the backup
	lea		0(a1,d5),a3				;copy to alter
	moveq		#58,d3
	tst.w		d6
	beq		LeavD3Alone
	moveq		#76,d3
LeavD3Alone:

BackupLoop:
	move.b	(a3)+,(a0)+
	move.b	(a3)+,(a0)+
	move.b	(a3)+,(a0)+
	move.b	(a3)+,(a0)+
	move.b	(a3)+,(a0)+
	move.b	(a3)+,(a0)+
	move.b	(a3)+,(a0)+			
	move.b	(a3)+,(a0)+			
	move.b	(a3)+,(a0)+			
	move.b	(a3)+,(a0)+			
	move.b	(a3),(a0)+
	add.l		d4,a3				;move down 1 line
	dbra		d3,BackupLoop		;save all of it.
SkipBackup:
	lea		0(a1,d5),a1
	lea		windowPointer(pc),a0
	move.l	a1,(a0)			;save pointer to the window

;---Top line------

	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+			;upper line
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)
	add.l		d4,a1				;move down a line

;---Sides and clear inner-----

	moveq		#56,d3			;counter
	tst.w		d6
	beq		LeaveD3Alone2
	moveq		#74,d3
LeaveD3Alone2:
DrawMostOfIt:
	move.b	d1,(a1)+			;make the left border
	clr.b		(a1)+
	clr.b		(a1)+
	clr.b		(a1)+
	clr.b		(a1)+
	clr.b		(a1)+				;clear the inner part
	clr.b		(a1)+
	clr.b		(a1)+
	clr.b		(a1)+
	clr.b		(a1)+
	move.b	d0,(a1)			;right border
	add.l		d4,a1
	dbra		d3,DrawMostOfIt		;do all of it

;----Now for the bottom line----

	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)+
	move.b	d2,(a1)
	st.b		(a5)				;indicate that the menu is drawn

;----Now for the line dividing the title from the rest----

 ifd	ti89
	lea	LCD_MEM+30*30,a0
 endc

 ifd	ti92plus		
	lea	LCD_MEM+30*56,a0
 endc

	tst.w		d6
	beq		LeaveA0Alone3
 ifd ti89
	lea		LCD_MEM+30*12,a0
 endc

 ifd ti92plus
	lea		LCD_MEM+30*38,a0
 endc

LeaveA0Alone3:
	lea		0(a0,d5),a0
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+
	move.b	d2,(a0)+		;the division line

;----Now for the title part of my menu----


 checkTrashing 'p'


	lsl.w		#3,d5				;multiply x in bytes by 8
	move.l	1596(a6),a0			;set font rom call
	move.w	d6,-(a7)			;want the small or large font
	jsr		(a0)

 checkTrashing 'C'

	move.w	#4,-(a7)
	move.l	title(pc),a0
	tst.w		d6
	beq		NoTruncating
	lea		buffer(pc),a1
	moveq		#13,d0
TruncateLoop:
	move.b	(a0)+,(a1)+
	dbeq		d0,TruncateLoop
	clr.b		(a1)
	lea		buffer(pc),a0
NoTruncating:
	move.l	a0,-(a7)

 checkTrashing 'D'

 ifd ti89
	move.w	#24,-(a7)			;cordnates of the title
 endc

 ifd ti92plus
	move.w	#50,-(a7)
 endc

	tst.w		d6
	beq		LeaveYAlone

 ifd ti89
	move.w	#4,(a7)
 endc

 ifd ti92plus
	move.w	#30,(a7)
 endc

LeaveYAlone:
	addq.w	#1,d5
	move.w	d5,-(a7)
	move.l	1700(a6),a5			;text display rom call
	jsr		(a5)

 checkTrashing 'E'

;----Now for the right arrow that indicates if names or variables were
;----Added so it can be scrolled right.

	move.b	foldersAndVarsIndic(pc),d0
	beq.s		NoRightArrow
	move.b	pageIndic(pc),d0			;indicates vars are in the list
	bne.s		NoRightArrow
	move.b	folderWasCompleted(pc),d0
	bne.s		NoRightArrow
	move.b	unitIndic(pc),d0
	bne.s		NoRightArrow
	lea		rightArrow(pc),a0
	move.l	a0,4(a7)
	add.w		#79,(a7)				;alter x
	jsr		(a5)

;----Now for the function key label part of my menu----

NoRightArrow:
	addq.l	#8,a7
	lea		functionString(pc),a4
	move.l	a4,-(a7)
	move.b	#'1',(a4)

 ifd ti89
	move.w	#32,-(a7)	;y cordinate
 endc

 ifd ti92plus
	move.w	#58,-(a7)
 endc

	moveq		#6,d4
	tst.w		d6
	beq		LeaveYAlone2
	moveq		#8,d4

 ifd ti89
	move.w	#14,(a7)
 endc

 ifd ti92plus
	move.w	#40,(a7)
 endc

LeaveYAlone2:
	move.w	d5,-(a7)			;x
	moveq		#7,d7				;counter - function keys
DrawFunctionKeyLoop:
	jsr		(a5)				;display it
	add.w		d4,2(a7)			;alter y
	addq.b	#1,(a4)			;change it from '1' to '2' ...
	dbra.s	d7,DrawFunctionKeyLoop
	lea		12(a7),a7

;----Now for the up arrow to indicate that the menu can be
;----scrolled up, if it can't then nothing is displayed

	move.w	#4,-(a7)
	pea		upArrow(pc)

 ifd ti89
	move.w	#32,-(a7)
 endc

 ifd ti92plus
	move.w	#58,-(a7)
 endc

	tst.w		d6
	beq		LeaveYAlone3

 ifd ti89
	move.w	#14,(a7)
 endc

 ifd ti92plus
	move.w	#40,(a7)
 endc

	addq.w	#2,d5
LeaveYAlone3:
	addq.w	#4,d5
	move.w	d5,-(a7)			;x
	move.l	ptr(pc),a3
	move.w	listBufferIndex(pc),d3
	beq.s		NoUpArrowNeeded
	jsr		(a5)

;----Now for the strings behind each of the function labels just
;----displayed above.

NoUpArrowNeeded:
	lea		0(a3,d3),a3
	addq.w	#7,(a7)
	tst.b		d6
	bne		hop45
	subq.w	#2,(a7)
hop45
	moveq		#7,d7
DrawOptionLoop:
	move.l	(a3)+,d0
	beq.s		DoneDrawingMenu
	moveq		#0,d1
	move.w	charBufferIndex(pc),d1
	sub.l		d1,d0
	moveq		#1,d2
	bsr		IsSpecialString1		;see if it needs to have a "\" or a "(" appended
	move.l	d0,4(a7)	
	jsr		(a5)
	add.w		d4,2(a7)
	dbra.s	d7,DrawOptionLoop

;----see if the down arrow is needed to indicate that
;----it can be scrolled down.

	tst.l		(a3)
	beq.s		DoneDrawingMenu
	lea		downArrow(pc),a0
	move.l	a0,4(a7)
	subq.w	#7,(a7)

	tst.b		d6
	bne		hop412
	addq.w	#2,(a7)
hop412
	sub.w		d4,2(a7)
	jsr		(a5)
DoneDrawingMenu:
	lea		10(a7),a7

;----Now add the help line of upcoming units-------

	move.b	unitIndic(pc),d0
	beq.s		NoHelp
	move.b	shortcutTableInView(pc),d0
	bne		NoHelp

;---Loop setup----

 ifd ti89
	moveq		#4,d1
 endc

 ifd ti92plus
	moveq		#6,d1
 endc

	lea		nextUnitsBuffer(pc),a0
	move.l	a0,-(a7)
	move.w	offsetTableIndex(pc),d2
	move.l	externalDb(pc),a1
	move.w	2(a1),d0
	lea		0(a1,d0.w),a1
	moveq		#5,d0				;six titles to add
	moveq		#NUMBER_OF_UNIT_MENUS+2,d4
	move.b	unitReplacementIndic(pc),d3
	beq		KeepD4
	subq.w	#2,d4
KeepD4:

;---add the titles to the list----

AddTitlesLoop:
	addq.w	#2,d2
	cmp.w		d4,d2
	bne.s		SkipWrapping
	moveq		#0,d2
SkipWrapping:
	move.b	unitReplacementIndic(pc),d3
	beq		NotSystemVarsInUnitMenu
	cmp.w		#NUMBER_OF_UNIT_MENUS-2,d2
	bne		NotSystemVarsInUnitMenu
	moveq		#-2,d2
	lea		systemVariableText(pc),a3	;point to title
	bra		UseSystemTitle
NotSystemVarsInUnitMenu:
	move.w	0(a1,d2),d3
	lea		8(a1,d3),a3			;point to the title
UseSystemTitle:
	move.w	d1,d3
CopyPartOfTitle:
	move.b	(a3)+,(a0)+
	dbeq		d3,CopyPartOfTitle
	bne.s		SkipDecrement
	subq.l	#1,a0				;point to the zero
SkipDecrement:
	move.b	#',',(a0)+
	move.b	#' ',(a0)+
	dbra		d0,AddTitlesLoop
	clr.b		-2(a0)			;zero terminate/ clear comma

;----Display the list----------

	move.l	920(a6),a0			;get help display
	jsr		(a0)
	addq.l	#4,a7
NoHelp:
	rts