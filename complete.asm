;copyright 2004 by Samuel Stearley


NUMBER_OF_MATCHES		EQU	70	;max number of matches to find, it must be a multiple
						;  of 8.  It will give up to 14 pages of matches.

NUMBER_OF_UNIT_MENUS	EQU	62	;(number of unit menus *2)-2, this number does include
						;  the "fake" unit menus.



 ifnd ti89
ti92plus
 endc

	include	"os.h"

 ifd ti89
	xdef		_ti89
 endc

 ifd ti92plus
	xdef		_ti92plus
 endc

	xdef		_nostub

debug MACRO
	move	#1,ccr
\loop:
	bcs	\loop

	ENDM	


 ifd I_AM_DEBUGGING
checkTrashing MACRO
	movem.l	d0-d2/a0-a1,-(a7)
	lea		trash_message(pc),a0
	move.b	#\1,(a0)
	move.w	#4,-(a7)
	move.l	a0,-(a7)
	move.l	#$009A0020,-(a7)
	move.l	200,a0
	move.l	1700(a0),a0
	jsr		(a0)
	lea		10(a7),a7
	moveq		#30,d0
\@delay
	move.b	#$1E,$600005
	dbra		d0,\@delay
	movem.l	(a7)+,d0-d2/a0-a1
	ENDM
 endc

 ifnd I_AM_DEBUGGING
checkTrashing MACRO
	; \1
	ENDM


 endc

;-----------------------------------------------
;Nostub comment format
;-----------------------------------------------
program_start:
 move.l (a7),(a7)
 bra.w end_extension_header
 dc.w $2e76,$5c7b,$4e74,$4e72,$4afc,0
 dc.l $01000000
 dc.w	2
 dc.w 0
 dc.w _comment-program_start
 dc.w	6
 dc.w	compatFlags-program_start
compatFlags:
 dc.l	1+8		;tsr, ev_hook
end_extension_header:
;------------------------------------------------
;INSTALL COMPLETE TO HIGH ALLOCATED RAM
;------------------------------------------------
	include	"install.asm"
;------------------------------------------------
;NOW THE CODE OF THE ACTUAL HOOK
;------------------------------------------------

	EVEN		
BEGINNING_OF_HOOK:
		dc.b		"evHkComplete"
oldEvent:	dc.l		0

	movem.l	d1-d7/a1-a6,-(a7)
	move.l	56(a7),a2		;get pointer to the event structure
	move.b	activatedFlag(pc),d0
	bne		PassItOn
tstOpcode:
	tst.b		$1234			;for the home flag
	bpl		PossiblyNewUnitMenu
btstOpcode:
	btst.b	#1,$1234		;make sure we are not in history
	beq		DoNothing
	move.l	200,a6
	cmp.w		#$723,(a2)		;command paste string?
	bne		NotPaste
	move.l	8(a2),a0
	tst.b		1(a0)			;1 letter string?
	bne		DoneWithCommandBeingEntered
	moveq		#0,d0
	move.b	(a0),d0
	cmp.w		#')',d0		;Fix a Bug with AutoClose Brackets by Kevin Kofler
	beq		RestoreTheScreenAndRestartBuffer
	bra		KeepAsKeypress
NotPaste
	cmp.w		#$710,(a2)		;see if it is CM_KEYPRESS
	bne		DoNothing

;----Diamond +space is right arrow key on a 92+

	move.w	10(a2),d0		;get the key press
KeepAsKeypress:

 ifd ti92plus
	cmp.w		#8224,d0
	bne		NotDiamondSpace
	move.w	#340,d0
	move.b	menuIndic(pc),d1	;if menu visible then I use the
	beq		NotVisible		;  key code that is set in cmpltdat
	move.w	right(pc),d0	;And get that keycode
NotVisible:
	move.w	d0,10(a2)
NotDiamondSpace
 endc

;----Special treatment of underscore, fix a bug with ash--

 ifd ti89
	cmp.w		#16650,d0
	bne		NotUnderscore
	move.w	#'_',d0
	move.w	d0,10(a2)
NotUnderscore:
 endc

;---Initiate some stuff----

	include "preprocs.asm"

;---A special search that only re-searches the already existing matches---

	lea		foldersAndVarsIndic(pc),a2
	clr.b		(a2)
	move.b	menuIndic(pc),d0
	beq		NoSpecialSearch
	move.b	listIsFull(pc),d0
	beq		NoSpecialSearch
	move.b	oneThingAllowed(pc),d0
	bne		NoSpecialSearch
	lea		listBufferIndex(pc),a1
	clr.w		(a1)
	move.l	ptr(pc),a1
	move.l	a1,a3
	moveq		#NUMBER_OF_MATCHES,d0
	move.b	-1(a0,d5),d1		;get the new character
	moveq		#58,d5			;':'
	moveq		#0,d4
	move.l	caseTable(pc),a5
	lea		$40000000,a4
SkipIt:
NextPtr:
	move.l	(a1)+,d2
	beq		MaybeNeedChangeTypes
	move.l	d2,a0
	move.b	(a0)+,d4			;get the next char
	move.b	0(a5,d4),d4			;get case insensitive version
	cmp.b		d4,d1
	bne		SkipIt
	move.b	(a0),d2
	beq		SkipIt			;entire match?
	cmp.b		d2,d5				;':'?
	beq		SkipIt
	cmp.l		a4,a0				;a variable or folder?
	bcs		NoSet
	st.b		(a2)
NoSet:
	move.l	a0,(a3)+
	subq.l	#1,d0
	bra		NextPtr

;---if no matches then start to look here

NoSpecialSearch:
NewUnitMenu:
	lea		offsetTableIndex(pc),a0
	move.w	(a0),2(a0)			;prevent automatic unit type switching from
							;  going too far
NewMenu:
OnlyVariables:
IncludeAll:
	lea		foldersAndVarsIndic(pc),a2
	clr.b		(a2)
	lea		listBufferIndex(pc),a0
	clr.w		(a0)
	bsr		AllocateMem
	move.l	ptr(pc),a3			;pointer to allocated memory
	moveq		#NUMBER_OF_MATCHES,d0	;counter

;----Load the pointer to the correct structure to search because units might
;----be needed,  OR just folders and variables are wanted OR just variables
;----from the last auto completed folder OR just stuff from the flash app
;----function.

	move.b	flashAppIndic(pc),d3
	beq		NoFlashAppStuff

;----load and search through 1 external file for the flash app data--------

	move.l	zeroTerminator(pc),a0
	bsr		AddFromExternal
	cmp.w		#NUMBER_OF_MATCHES,d0
	beq		RestoreTheScreenAndRestartBuffer
	bra		DoVisuals

;----now see if it should add only data from a specific folder------

NoFlashAppStuff:
	lea		charBuffer(pc),a1
	move.b	folderWasCompleted(pc),d3
	beq.s		NotJustFiles
	move.w	d0,d6				;it expects it to be backed up in d6
	move.l	zeroTerminator(pc),a0
	addq.l	#1,a0				;compensate for the pea -1(a0)
	bra		AddOnlyFilesFromLastCompletedFolder
NotJustFiles:
	move.b	pageIndic(pc),d3
	beq		NotSystemVariables
	bpl		AddOnlyVariablesToList	;if they pressed right

;---get pointer to the system variable database-----

	move.l	externalDb(pc),a4
	move.w	(a4),d1
	lea		0(a4,d1.w),a4
	bra		SkipFirstExternalDatabase
NotSystemVariables:
	move.l	externalDb(pc),a4

;----See if we need an alternative unit structure-----

	lea		unitIndic(pc),a5
	clr.b		(a5)
	cmp.b		#'_',(a1)
	bne.s		SkipLoadingOfAlternativeStructure

;----load alternative unit structure-----

	move.w	2(a4),d1
	lea		0(a4,d1.w),a4		;point to the offset table
	move.w	offsetTableIndex(pc),d3
	st.b		(a5)				;set unit indicator

;----maybe do a unit menu of all variables starting with an '_'----

	cmp.w		#NUMBER_OF_UNIT_MENUS-2,d3
	bne		NormalUnitMenu
	lea		title(pc),a0
	lea		unitVariableTitle(pc),a1
	move.l	a1,(a0)
	lea		mainEnd+1(pc),a0
	move.w	d0,d6
	bra		AddOnlyFilesFromLastCompletedFolder

;----Normal unit menu of internal unit strings-----

NormalUnitMenu:
	move.w	0(a4,d3),d3
	lea		0(a4,d3),a4
	bra.s		SkipFirstExternalDatabase
SkipLoadingOfAlternativeStructure:

;----Add items from the first external database------------

	move.w	useXtrast1(pc),d1
	bne		SkipXtrast1
	lea		_xtrast1(pc),a0
	bsr		AddFromExternal
	tst.w		d0
	beq		DoVisuals
SkipXtrast1:

;----Add items from the internal database-----

	addq.l	#4,a4				;point to the internal strings
SkipFirstExternalDatabase:
	moveq		#0,d7
	move.w	charBufferIndex(pc),d4	;get the number of characters entered
	move.w	(a4)+,d1			;is it indexed?
	beq		NoIndexing
	tst.w		d4
	beq		SkipIndexing

;---IF THE INTERNAL DATABASE IS INDEXED------

	moveq		#0,d1
	move.b	(a1),d1		;get first character entered
	sub.b		#97,d1
	bcs		Use26
	cmp.b		#26,d1
	bcs		Skip26
Use26:
	moveq		#26,d1		;things like convert and delta get indexed all together
Skip26:
	lsl.l		#2,d1			;quadruople it
	move.w	0(a4,d1),d7		;get offset
	move.w	2(a4,d1),d1		;number of strings-1

	moveq		#108,d3
	add.l		d3,a4
	move.w	(a4)+,d3
	bne		ThereIsAnExternal3
	sub.l		a5,a5
	bra		A5Alone3
ThereIsAnExternal3
	lea		-112(a4,d3.w),a5	;point to end zero of the external database
A5Alone3:
	addq.l	#2,a4
	bra		ContinueOn

;---IF THE INTERNAL DATABASE IS NOT INDEXED----

SkipIndexing:
	moveq		#108,d1
	add.l		d1,a4			;skip the offset table
NoIndexing:
	move.w	(a4)+,d1
	bne		ThereIsAnExternal
	sub.l		a5,a5
	bra		A5Alone
ThereIsAnExternal
	lea		-4(a4,d1.w),a5	;point to end zero of the external database
A5Alone:
	move.w	(a4)+,d1		;get the number of strings
ContinueOn:					;jump here if they are indexed
	moveq		#0,d2
	move.w	(a4)+,d2
	lea		title(pc),a0
	move.l	a4,(a0)
	tst.w		d1
	bmi		NoInternalItems
AdvnceIt:
	tst.b		(a4)+
	bne		AdvnceIt
	add.l		d2,a4			;point to the lower case version
	add.l		d7,a4			;go to the indexed point
	move.l	d2,d3
	bne		Add1
	moveq		#-1,d3
Add1:
	addq.l	#1,d3
	moveq		#58,d2		;':'
	subq.w	#1,d4
	beq		Special1CharSearch
	bcs		Special0CharSearch

;------THE VARIABLE LENGTH SEARCH LOOP FOR THE INTERNAL DATABASE-----------

SearchThroughEachString:
	move.l	a1,a0
AdvancePointerThroughStrings
	tst.b		(a4)+
	bne.s		AdvancePointerThroughStrings
CompareTheBytes:
	cmp.b		(a4)+,(a0)+
	beq.s		CompareTheBytes
	subq.l	#1,a4
	tst.b		(a0)			;did I hit a zero? If I did then I have a match
	bne.s		NoMatch
	move.b	(a4),d4
	beq		NoMatch		;entire match?
	cmp.b		d4,d2			;':'?
	beq		NoMatch
	move.l	a4,(a3)
	sub.l		d3,(a3)+		;point to the uppercase version
	subq.l	#1,d0			;limit # of matches
	beq		DoVisuals
ContinueLoop:
NoMatch:
	dbra		d1,SearchThroughEachString
	bra		AfterThe1CharSearch

;---THE INTERNAL SEARCH OPTOMIZED FOR 1 CHARACTER-------

Special1CharSearch:
	move.b	(a1),d4		;the character
AdvanceDestPtr:
NextStr:
	tst.b		(a4)+
	bne.s		AdvanceDestPtr
	cmp.b		(a4)+,d4		;the 1 char?
	bne		NotAMatch
	cmp.b		(a4),d2		;':'?
	beq		NotAMatch
	move.l	a4,(a3)		;save it
	sub.l		d3,(a3)+
	subq.l	#1,d0
	beq		DoVisuals
NotAMatch:
	addq.l	#2,a4			;reduce time in the advance loop
	dbra		d1,NextStr		;Onward Ho
	bra		After0CharSearch

;---Special search optomized for a search string
;---containing no characters

Special0CharSearch:
	sub.l		d3,a4
AdvnceDestPtr:
NextStr2:
	tst.b		(a4)+
	bne		AdvnceDestPtr
	move.l	a4,(a3)+
	addq.l	#3,a4
	subq.l	#1,d0
	dbeq		d1,NextStr2
	beq		DoVisuals

;---Add external strings that come after the internal--

AfterThe1CharSearch:
After0CharSearch:
NoInternalItems:
	move.l	a5,d1			;are there any external?
	beq		UnitsSoNoMore
	move.l	a5,a0
AddFromExternalSystemDatabase
SearchForIt:
	bsr		AddFromExternal
	tst.w		d0
	beq		DoVisuals
	move.b	unitIndic(pc),d7	;if on the unit page then nothing else
	bne		UnitsSoNoMore	; is needed.
	move.b	pageIndic(pc),d7
	bmi		SystemVariablesSoNoMore

;----Add the folders to the list of pointers---------

moveOpcode:
AddOnlyVariablesToList:
	move.w	#$1234,d7			;the handle of the folder table
	move.l	#$80000000,d6
	bsr		AddToListFromSymbolTable;d0-> limit variable
							;d6-> Marker flag
							;d7-> handle
							;a3-> place to store addresses
							;a2-> pointer to the match indicator
							;a6-> pointer to the jump table
	move.w	d0,d7
	beq		DoVisuals

;----Add the stuff from the current folder to the list of pointers-----

 checkTrashing 'a'

SearchAndDisplay:
	move.w	d0,d6
leaOpcode2:
	lea		$12345678,a1			;point to buffer that has the name
	lea		currentFolderName(pc),a0;place to store the current folder
CopyLoop3
	move.b	(a1)+,(a0)+
	bne.s		CopyLoop3
	lea		zeroTerminator(pc),a1
	move.l	a0,(a1)
	subq.l	#1,(a1)

;----Jump here if the buffer has a folder name, It need
;----not be the name of the current folder.  A0 and d6 will
;----need to be loaded.

AddOnlyFilesFromLastCompletedFolder:
	pea		-1(a0)
	move.l	392(a6),a0
	jsr		(a0)			;get hsym
	addq.l	#4,a7
	move.l	d0,d1
	move.l	d6,d0
	tst.l		d1
	beq		MaybeNeedChangeTypes
	move.l	d1,-(a7)
	move.l	484(a6),a0
	jsr		(a0)			;dereference hsym
	addq.l	#4,a7
	move.w	$C(a0),d7		;got the handle
	move.w	d6,d0			;restore the limit variable
	move.l	#$40000000,d6

 checkTrashing 'b'

	bsr		AddToListFromSymbolTable

;----Check the number of matches-------

SystemVariablesSoNoMore:
UnitsSoNoMore:
MaybeNeedChangeTypes:
	cmp.w		#NUMBER_OF_MATCHES,d0
	bne		DoVisuals

;----Zero matches were found.  So if it is a unit menu we change
;----the unit type.  If it is a normal menu then we go to the system variables

	move.b	unitIndic(pc),d0
	beq		NotUnits

;---Change unit menu-----

	move.l	56(a7),a2
	moveq		#0,d3
	cmp.w		#257,10(a2)
	beq		BackspaceSoNO
	btst.w	#11,8(a2)
	sne		d3
BackspaceSoNO:
	lea		offsetTableIndex(pc),a0
	move.w	(a0),d0
	moveq		#2,d1
	move.b	autoUnitScrollDirection(pc),d2
	beq		LeavePositive
	neg.w		d1
LeavePositive:
	add.w		d1,d0
	bpl		NoWrappingIt1
	tst.b		d3			;we will not wrap if it is an auto repeating
	bne		Revert		;  arrow.
	move.w	#NUMBER_OF_UNIT_MENUS,d0;wrapping to end
NoWrappingIt1:
	cmp.w		#NUMBER_OF_UNIT_MENUS+2,d0
	bne		NoWrappingIt2
	tst.b		d3
	bne		Revert
	clr.w		d0			;wrap to beginning
NoWrappingIt2:
	move.w	d0,(a0)
	cmp.w		2(a0),d0		;have we exhaused everything?
	beq		RestoreTheScreenAndRestartBuffer
	bra		NewMenu
Revert:
	move.w	lastUnitMenuWMatches(pc),d0
	move.w	d0,(a0)
	move.w	listBufferIndex(pc),d0
	bne		NewMenu
	lea		renderingNeeded(pc),a0
	st.b		(a0)
	bra		NewMenu

;---Change to system variables if it can---

NotUnits:

 checkTrashing 'c'
	lea		pageIndic(pc),a0
	tst.b		(a0)
	bne		RestoreTheScreenAndRestartBuffer
	st.b		(a0)
	bra		NewMenu
;--------------------------------------------------------
;THE TABLE OF POINTERS TO THE MATCHES HAS BEEN CREATED.
;IT NOW HAS TO DO THE GRAPHICS.  THE FIRST STEP IS TO
;FIND THE X TO DISPLAY THE MENU AT.
;--------------------------------------------------------
DoVisuals:
ReDoMenu:
	lea		listIsFull(pc),a0
	tst.l		d0
	sne		(a0)
	and.w		#%111,d0
ClearRest:
	clr.l		(a3)+
	dbra		d0,ClearRest
ReDoMenuNoClearing:
	lea		autoUnitScrollDirection(pc),a1
	clr.b		(a1)
	lea		offsetTableIndex(pc),a0
	move.w	(a0),-2(a0)
	move.b	renderingNeeded(pc),d0
	bne		NoRendering

ReDrawMenu:
	lea		menuX(pc),a4
	move.w	menuMoves(pc),d0
	bne		MoveIt
	move.w	(a4),d5
	move.b	menuIndic(pc),d0
	bne		SkipXCalc
	bra		OverMoveIt
 MoveIt:
	lea		menuIndic(pc),a0
	tst.b		(a0)
	beq		SkipRemoval
	clr.b		(a0)
	bsr		RemoveMenu
SkipRemoval
OverMoveIt:

moveOpcode3:
	move.w	$1234,d5		;cursor position

 ifd ti89
	mulu		#6,d5			;to find the x
	lsr.w		#3,d5			;find the byte position
	cmp.w		#8,d5
	bcs		d5IsSmallEnough
	moveq		#9,d5
d5IsSmallEnough:
	move.w	d5,(a4)
 endc

 ifd ti92plus
	cmp.w		#18,d5
	bcs		d5IsSmallEnough
	moveq		#19,d5
d5IsSmallEnough:
	move.w	d5,(a4)
 endc

SkipXCalc:

 checkTrashing 'd'

	bsr		DisplayMenu		;input d5 is x
NoRendering:
	lea		renderingNeeded(pc),a0
	clr.b		(a0)
	bra		PassItOn
;---------------------------------------------------------
;NOW TO HANDLE THE PRESSING OF THE ARROW KEYS AND THE
;APPROPRIATE REPONSES TO THOSE KEYS.
;---------------------------------------------------------
NotCharacter:
 	include	"arrows.asm"

;----maybe display a shorcut table for the unit menu-----

	move.b	shortcutTableInView(pc),d1
	bne		MaybeRespondToShortctKey
	move.b	unitIndic(pc),d1
	beq		NotAppKey
	cmp.w		#265,d0
	bne		NotAppKey
	move.l	#$700,(a2)
	move.l	externalDb(pc),a0
	move.w	2(a0),d0
	lea		0(a0,d0.w),a0
	move.w	-2(a0),d0
	lea		2(a0,d0.w),a0		;now points to the shortcut table
	move.l	ptr(pc),a1			;place to keep the matches
	move.w	2(a0),d0			;counter
	addq.l	#6,a0
	lea		title(pc),a3
	move.l	a0,(a3)			;load the pointer to the title
	moveq		#32,d1
Forward2:
	tst.b		(a0)+
	bne		Forward2
Forward3:
	tst.b		(a0)+
	bne		Forward3
	move.l	a0,(a1)+
	addq.l	#4,a0
	subq.w	#1,d0
	dbeq		d1,Forward3
	and.w		#$7,d1
ClrIt:
	clr.l		(a1)+
	dbra		d1,ClrIt			;zero the rest
	lea		listBufferIndex(pc),a0
	clr.w		(a0)				;go to first page
	lea		shortcutTableInView(pc),a0
	st.b		(a0)
	lea		charBufferIndex(pc),a0
	lea		charBufferIndex2(pc),a1
	move.w	(a0),(a1)
	clr.w		(a0)
	bra		ReDrawMenu			;re do all visuals

;----Look through the shortcut listings---------

MaybeRespondToShortctKey:
	move.w	#$700,(a2)
	lea		offsetTableIndex(pc),a0

 ifd ti89
	moveq		#56,d1
	cmp.w		#277,d0		;home?
	beq		StoreIndex
	moveq		#28,d1
	cmp.w		#258,d0		;store? (p)
	beq		StoreIndex
 endc

	cmp.w		#256,d0		;a char?
	bcc		NotAShortcut
	lea		shortcutTable(pc),a4
	lea		shortcutOffsets-2(pc),a1
SearchTable2:
	addq.l	#2,a1
	tst.b		(a4)
	beq		NotAShortcut
	cmp.b		(a4)+,d0
	bne		SearchTable2
	move.w	(a1),d1
StoreIndex:
	move.w	d1,(a0)
NotAShortcut:
	lea		charBufferIndex(pc),a0
	lea		charBufferIndex2(pc),a1
	move.w	(a1),(a0)			;restore the index into the table
	lea		shortcutTableInView(pc),a0
	clr.b		(a0)
	bra		NewUnitMenu			;and redisplay the onld unit menu or the new
NotAppKey:

;----See if it is diamond+some function key------

 ifd ti89
	cmp.w		#16652,d0
	bcs		NotDiamondFunctionKey
	cmp.w		#16657,d0
	bcc		NotDiamondFunctionKey
 endc

 ifd ti92plus
	cmp.w		#8460,d0
	bcs		NotDiamondFunctionKey
	cmp.w		#8468,d0
	bcc		NotDiamondFunctionKey
 endc

;----if it is a folder change it---------

	move.w	d3,(a2)		;make it an idle event

 ifd ti89
	sub.w		#16652,d0		;d0 is 0 for f1, 1 for f2, ect...
 endc

 ifd ti92plus
	sub.w		#8460,d0
 endc

	lsl.w		#2,d0
	lea		listBufferIndex(pc),a1
	add.w		(a1),d0
	move.l	ptr(pc),a0
	move.l	0(a0,d0),d0
	bpl		PassItOn

;----So it is a folder, set it as current and be done-----

	move.l	d0,a0
	lea		charBufferIndex(pc),a1
	moveq		#0,d3
	move.w	(a1),d3
	sub.l		d3,a0			;point to the beginning
	clr.w		(a1)
	lea		currentFolderName(pc),a1
	clr.b		(a1)+			;beginning zero
	move.l	a1,-(a7)		;use later for st_folder call
	clr.w		-(a7)			;flag
CFolName:
	move.b	(a0)+,(a1)+
	bne		CFolName
	subq.l	#1,a1
	lea		zeroTerminator(pc),a0
	move.l	a1,(a0)
	move.l	a1,-(a7)		;pointer to the end zero
	move.l	404(a6),a0
	jsr		(a0)			;set the current folder
	addq.l	#6,a7
	move.l	912(a6),a0		;st_folder
	jsr		(a0)
	lea		title(pc),a0
	move.l	(a7)+,(a0)
	lea		folderWasCompleted(pc),a0
	st.b		(a0)
	lea		charBuffer(pc),a0
	move.w	#$0100,(a0)

;----Delete already entered folder name----

	pea		deleteEvent(pc)
	move.w	#-2,-(a7)
	move.l	824(a6),a3
ContinueDeletion:
	subq.w	#1,d3
	bcs		DoneDeleting
	jsr		(a3)
	bra		ContinueDeletion
DoneDeleting:
	addq.l	#6,a7
	bra		OnlyVariables

;----see if it is a function key-----

NotDiamondFunctionKey:
	sub.w		#268,d0
	bcs		NotAKeyToHandle
	cmp.w		#8,d0
	bcc		NotAKeyToHandle	;d0 is 0 for f1, 1 for f2, ect...

;----go into the following code if it was a function key
;----it will turn the keypress event into a paste event

	move.w	d3,(a2)			;make it an idle event- it will remain an idle
	lsl.w		#2,d0				;  event if the pointer is null meaning a function
	add.w		listBufferIndex(pc),d0	;  key with no associated text was pressed
	move.l	ptr(pc),a0
	move.l	0(a0,d0),d0			;get pointer
	beq		PassItOn
	moveq		#0,d3
	move.w	charBufferIndex(pc),d3
	sub.l		d3,d0
	moveq		#0,d2
	bsr		IsSpecialString2
	tst.l		d0				;is it a folder name?
	bpl.s		NotFolderName

;----PUT THE FOLDER TEXT TO THE LINE AND THEN GIVE A MENU
;----OF ALL THE VARIABLES IN THAT FOLDER

	lea		currentFolderName(pc),a1
	lea		title(pc),a0
	move.l	a1,(a0)
	move.l	d0,a0
Lllll:
	move.b	(a0)+,(a1)+
	bne		Lllll
	subq.l	#2,a1
	clr.b		(a1)				;get rid of the "\"
	lea		zeroTerminator(pc),a0
	move.l	a1,(a0)
	add.l		d3,d0				;bring it back up
	lea		pasteEventAddress(pc),a0
	move.l	d0,(a0)
	pea		pasteEvent(pc)
	move.w	#-2,-(a7)
	move.l	824(a6),a0
	jsr		(a0)				;send the text to the entry line.
	lea		folderWasCompleted(pc),a0
	st.b		(a0)				;set the flag
	addq.l	#6,a7
;	lea		charBuffer(pc),a0
;	move.w	#$0100,(a0)		;will let in everything in the search
	bra		OnlyVariables

;------ PASS IT ON AND GET RID OF THE MENU ----------

NotFolderName:
	add.l		d3,d0			;bring pointer back up

PasteString:				;entrance for unit menu replacement
	bsr		RemoveComments
	move.w	#$723,(a2)		;turn it into a command paste text
	move.l	d0,8(a2)		;put pointer to the event structure

;----this code restores the screen and restarts my buffer----

NotAKeyToHandle:
RestoreTheScreenAndRestartBuffer:
DoneWithCommandBeingEntered:
	move.b	menuIndic(pc),d0
	beq.s		DoNotRestore
	bsr		RemoveMenu

;----Unallocate the memory------

DoNotRestore:
	move.w	handle(pc),-(a7)
	beq		NoHandle
	move.l	604(a6),a0
	jsr		(a0)
NoHandle:
	addq.l	#2,a7
	lea		handle(pc),a0
	clr.w		(a0)

;----re inintiate variables-----

	lea		listBufferIndex(pc),a0
	clr.l		(a0)+			;clear char_buffer_index and list_buffer_index
	clr.l		(a0)+			;clear the menu visible flag, the unit indicator
						;  and the variables only indicator and the last
						;  completion was a folder completion.
	clr.l		(a0)+			;clears the folder and vars indicator
						;  and the do not put stuff straight to the
						;  buffer flag.  And the direction to scroll
						;  the unit menu automatically.
	clr.l		(a0)			;Clear the unit replacement flag, and the
						;  rendering needed flag, the indicator of the
						;  unit shortcut menu, and the indicator of the
						;  list buffer being entirely full

;----The final exiting code that will pass up the event---

NotVisibleSoIgnoreRemainingKeys:
CanNotScroll:
DoNothing:
PassItOn:
	movem.l	(a7)+,d1-d7/a1-a6
	move.l	oldEvent(pc),d0
	beq.s		NoOldHook
	move.l	d0,-(a7)
NoOldHook:
	rts
;----------------------------------------------------------------------
;INCLUDE THE SUBROUTINES, THE UNIT REPLACEMENT CODE, THE VARIABLES
;AND ARRAYS.
;----------------------------------------------------------------------
	include	"unit.asm"
	include	"sub.asm"
	include	"menu.asm"
	include	"data.asm"

 ifd I_AM_DEBUGGING

trash_message:
	dc.b		0,0
 endc


END_OF_HOOK:




	END			
