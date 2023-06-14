;Copyright 2004 by Samuel Stearley

;This code in this file does the pre-processing of the stuff
;already typed in the entry line.


	lea		charBufferIndex(pc),a5
	move.w	(a5),d5
	move.w	d0,d3
	lea		charBuffer(pc),a4
	move.l	a4,a0

;----Backspace response-----

	cmp.w		#257,d0
	bne		NoBackSpace
	lea		folderWasCompleted(pc),a3
	clr.w		(a3)
	bra		BackSpaceIt
NoBackSpace:

;----see if it is a character and if it is maybe modify it for case
;----insensitive searching.  And In some circumstances we always pre-process

	cmp.w		#256,d3			;is it a character?
	bcc		NotCharacter
	move.b	shortcutTableInView(pc),d1
	bne		MaybeRespondToShortctKey
	cmp.b		#13,d0			;enter key
	beq		RestoreTheScreenAndRestartBuffer
	cmp.b		#':',d3
	beq		RestoreTheScreenAndRestartBuffer
	cmp.b		#' ',d3
	beq		HandleIt
	cmp.b		#'\',d3
	beq		HandleIt
	cmp.b		#'.',d3
	beq		HandleIt
	cmp.b		#'_',d3
	beq		HandleIt
	cmp.b		#18,d3
	beq		HandleIt

	cmp.b		#91,d3
	bcc.s		NotUpper1
	cmp.b		#65,d3
	bcs.s		NotUpper1
	add.b		#32,d3			;make it lower case
NotUpper1:
	move.b	menuIndic(pc),d0
	bne		PutTheNewChar
BackSpaceIt:
HandleIt:
	lea		oneThingAllowed(pc),a3	;disable paste and highlight
	st.b		(a3)

;----Just in case text is highlighted I send it as an event----

	lea		activatedFlag(pc),a3
	st.b		(a3)
	move.l	a2,-(a7)
	move.w	#-2,-(a7)
	move.l	824(a6),a0
	jsr		(a0)
	addq.l	#6,a7
	move.w	#$700,(a2)		;CM_idle
	clr.b		(a3)


 checkTrashing 'G'



;----Now consider already entered keys----

moveOpcode4:
	move.w	$1234,-(a7)		;handle on entry line text
	move.l	600(a6),a0		;dereference call
	jsr		(a0)
	addq.l	#2,a7
moveOpcode5:
	move.w	$1234,d0		;cursor position
	beq		RestoreTheScreenAndRestartBuffer
	move.w	d0,d4
	lea		seperationCharacters(pc),a1
	moveq		#0,d6			;folder indicator/flash app notation indic


 checkTrashing 'H'


;----Find First Occurence of a Seperation Character----

FindLowerSeperationChar
	subq.w	#1,d0
	bcs		DoneWithFindingSeperationChars
	move.b	0(a0,d0),d2

;----variables in other folder support---

	cmp.b		#'\',d2		;folder?
	bne		NotFolderIndic
	tst.w		d6
	bne		RestoreTheScreenAndRestartBuffer
	move.w	d0,d6			;put the position it was found into d6
NotFolderIndic:

;----Flash app notation support---------

	cmp.b		#'.',d2
	bne		NotFlashAppNotation			
	move.b	1(a0,d0),d1		;if character right after is a number then it is a
	cmp.b		#'0',d1		;seperation character
	bcs		NotANumber9
	cmp.b		#':',d1
	bcs		DotIsASeperationChar
NotANumber9:
	tst.w		d6
	bne		NotFlashAppNotation
	move.w	d0,d6

;----Degree char is not a seperation char if previous char is an underscore-----

NotFlashAppNotation:
	cmp.b		#176,d2
	bne		NotDegree
	tst.w		d0			;is there anything before
	beq		RestoreTheScreenAndRestartBuffer
	cmp.b		#'_',-1(a0,d0)
	bne		DoneWithFindingSeperationChars

;----Try to find it in the table of seperation characters---

NotDegree:
	move.l	a1,a3
	moveq		#(afterSepChars-seperationCharacters)-1,d1
FindCharsInTableLoop:
	cmp.b		(a3)+,d2
	dbeq		d1,FindCharsInTableLoop
	bne		FindLowerSeperationChar

;----Now That we have the lower seperation character, we bypass the numbers
;----immediately after it because they are for implied multiplication.

DoneWithFindingSeperationChars:
DotIsASeperationChar:
	addq.w	#1,d0
	lea		0(a0,d0),a1
	sub.w		d0,d4			;counter
	bne		NoWorry
	move.b	-(a1),d3		;Support for a seperation character as the first
	moveq		#0,d5			;  character.
	move.l	a4,a0
	bra		PutTheNewChar
NoWorry:
	cmp.w		#600,d4
	bcc		RestoreTheScreenAndRestartBuffer
	moveq		#46,d5		;'.'
	moveq		#48,d7		;'0'
	moveq		#58,d0		;':'

;---consider if it is a some other base----

	cmp.b		(a1)+,d7
	bne		NotABase
	move.b	(a1),d1
	beq		NotABase
	cmp.b		#'h',d1
	beq		HexBase
	cmp.b		#'H',d1
	beq		HexBase
	cmp.b		#'B',d1
	beq		BinaryBase
	cmp.b		#'b',d1
	bne		NotABase

;----Bypass the bin number imediately after the seperation character----

BinaryBase:
	subq.w	#2,d4
	bls		RestoreTheScreenAndRestartBuffer
	addq.l	#1,a1
FindNextNotNumberLoop3:
	move.b	(a1)+,d1
	sub.b		d7,d1
	subq.b	#1,d1
	bhi		NotANumber
	subq.w	#1,d4
	beq		RestoreTheScreenAndRestartBuffer
	bra		FindNextNotNumberLoop3

;----Bypass the hex number immediately after the seperation character----

HexBase:
	subq.w	#2,d4
	bls		RestoreTheScreenAndRestartBuffer
	addq.l	#1,a1
FindNextNotNumberLoop2:
	move.b	(a1)+,d1
	cmp.b		#'A',d1
	bcs		NotL1
	cmp.b		#'G',d1
	bcs		BypassHexChar
NotL1:
	cmp.b		#'a',d1
	bcs		NotL2
	cmp.b		#'g',d1
	bcs		BypassHexChar
NotL2:
	cmp.b		d7,d1
	bcs		NotANumber
	cmp.b		d0,d1
	bcc		NotANumber
BypassHexChar:
	subq.w	#1,d4
	beq		RestoreTheScreenAndRestartBuffer
	bra		FindNextNotNumberLoop2

;---So bypass the number---

NotABase:
	subq.l	#1,a1
FindNextNotNumberLoop:
	move.b	(a1)+,d1
	cmp.b		d5,d1			;dot?
	beq		BypassDecimal
	cmp.b		d7,d1			;0?
	bcs		NotANumber
	cmp.b		d0,d1			;upper limit on a number
	bcc		NotANumber
BypassDecimal:
	subq.w	#1,d4
	beq		RestoreTheScreenAndRestartBuffer
	bra		FindNextNotNumberLoop
NotANumber:

	cmp.b		#'\',-(a1)
	beq		RestoreTheScreenAndRestartBuffer


;----If the first thing after the numbers/seperaration chars is an underscore
;----then subsequent underscores imply multiplication.

	cmp.b		#'_',(a1)
	seq		d7

;----If we bypassed a decimal place when bypassing the number after
;----the seperation character then check if it was the same decimal
;----place that indicates flash app notation.

	lea		0(a0,d6),a0
	cmp.l		a0,a1
	scs		d6

;----So copy the characters to the internal buffer----

PutTheSeperationChar:
	moveq		#0,d5
	move.l	a4,a0
	subq.w	#1,d4
	tst.b		d6
	beq		NoLoadFlashApp

;----In case a folder or flash app notation we first copy to a different
;----buffer.

	lea		currentFolderName(pc),a4
	lea		title(pc),a0			;title of the menu
	move.l	a4,(a0)
	moveq		#0,d7

;----Now The Copy Loop, it promotes upper case to lower case and if
;----a folder is already entered it first copies the folder to it's
;----own buffer and then the name afterwards to its own buffer.

NoLoadFlashApp:
	moveq		#92,d1		;'\'
	moveq		#46,d2		;'.'
	moveq		#91,d3
	moveq		#0,d0
	lea		95,a3		;underscore

CLoop2:
	move.b	(a1)+,d0
	tst.b		d7
	beq		NoWorryAboutImpliedUnitMultiplication
	cmp.w		a3,d0
	bne		NoWorryAboutImpliedUnitMultiplication

;----if it is implied unit multiplication then we start over----

	lea		charBuffer(pc),a4
	move.l	a4,a0
	moveq		#0,d5
	bra		StoreIt
NoWorryAboutImpliedUnitMultiplication:

;----Now folder support--------

	cmp.b		d1,d0
	bne		NotEndOfFolder
	clr.b		(a4)
	lea		zeroTerminator(pc),a3
	move.l	a4,(a3)
	lea		folderWasCompleted(pc),a4
	bra		CarryOn
NotEndOfFolder:

;----Now flash app support--------

	cmp.b		d2,d0
	bne		NotEndOfAppNotation
	clr.b		(a4)
	lea		zeroTerminator(pc),a3
	move.l	a4,(a3)
	lea		flashAppIndic(pc),a4
CarryOn:
	st.b		(a4)
	lea		oneThingAllowed(pc),a0
	st.b		(a0)
	lea		charBuffer(pc),a4
	move.l	a4,a0
	moveq		#0,d5
	bra		TheDBRA
NotEndOfAppNotation:
	cmp.b		d3,d0
	bcc.s		NotUpper5
	cmp.w		#65,d0
	bcs.s		NotUpper5
	add.b		#32,d0		;make it lower case
NotUpper5:

StoreIt:
	move.b	d0,(a4)+
	addq.l	#1,d5
	cmp.w		#9,d5			;do not go over the boundaries
	beq		PassItOn
TheDBRA:
	dbra		d4,CLoop2
	bra		OnlyPlaceMarkers

;----Jump here if no preprocessing is to be done b/c the menu
;----is already visible.  It will also jump here if a seperation
;----character was typed.

PutTheNewChar:
	move.b	d3,0(a0,d5)
	addq.w	#1,d5
OnlyPlaceMarkers:
	cmp.w		#9,d5
	bcc		RestoreTheScreenAndRestartBuffer
	move.b	#1,0(a0,d5)
	clr.b		1(a0,d5)
	move.w	d5,(a5)

;----And flow back into complete.asm---