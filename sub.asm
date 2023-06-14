;copyright 2004 Samuel Stearley


;------This routine adds stuff from an external database-----------

;------------------------------------------------------
;INPUTS->	a0-end zero of the name string
;		d0-limit variable
;		a6-pointer to the jump table
;		a3-place to store the adrresses
;
;OUTPUTS->	d0-number of matches is decreased, assuming
;			matches are found.
;		a3-it is advanced and filled with pointers
;			to more matches.
;		-if list contains an item that is not
;		 a string it returns with the variables unaltered
;------------------------------------------------------
AddFromExternal:
	movem.l	d1-d7/a0-a2/a4/a5,-(a7)
	movem.l	d0/a3,-(a7)			;in case of error
	move.w	useUscore(pc),d3
	beq		SkipUnderscoreStripping
	move.l	a0,a1
DecLoop:
	tst.b		-(a1)
	bne		DecLoop
	addq.l	#1,a1
	cmp.b		#'_',(a1)+
	bne		SkipUnderscoreStripping
	lea		buffer(pc),a0
	clr.b		(a0)+
CopyIt:
	move.b	(a1)+,(a0)+
	bne		CopyIt
	subq.l	#1,a0				;point to the zero
SkipUnderscoreStripping:
	move.l	d0,d3				;save the number of matches
	move.l	a7,d4
	move.l	a0,-(a7)			;put the name input onto the stack
	move.l	388(a6),a0
	jsr		(a0)				;vat find in main call
	move.l	d0,-(a7)



 checkTrashing 'I'



	move.w	d3,d0
	tst.l		(a7)
	beq		NoExtras
	move.l	484(a6),a0
	jsr		(a0)				;now have a pointer to the vat entry
	move.w	$C(a0),-(a7)		;put the handle onto the stack
	move.l	600(a6),a0			;derefence the handle
	jsr		(a0)


 checkTrashing 'J'


	moveq		#0,d0
	move.w	(a0),d0
	lea		1(a0,d0.l),a5		;get an esi
	lea		4(a0),a4			;get pointer to the strings	
	move.l	d3,d0
	cmp.b		#$D9,(a5)			;Is it a list or matrix?
	bne		NoExtras
	moveq		#$2d,d6
	cmp.b		-1(a5),d6			;string?
	bne		NoExtras
	lea		charBuffer(pc),a1		;stuff to search for
	moveq		#11,d1
	moveq.b	#58,d5			;';'
	move.w	charBufferIndex(pc),d3
	beq		AddToList_E3
	sub.w		d3,d1
	move.l	caseTable(pc),a2
	moveq		#0,d2
	bra		AddToList_E2		;jump into the loop

;----Now the processing loop-----

SearchThroughEachString3:
	subq.l	#1,a4
AdvancePointerThroughStrings3
	tst.b		(a4)+
	bne.s		AdvancePointerThroughStrings3
SearchEachStringNoAdvance:
	cmp.b		(a4),d6			;string?
	bne		ErrorNotString
	addq.l	#2,a4
AddToList_E2:
	cmp.l		a5,a4
	bcc.s		DoneSearching
	move.l	a1,a0
CompareTheBytes3:
	move.b	(a4)+,d2
	move.b	0(a2,d2),d2
	cmp.b		(a0)+,d2
	beq.s		CompareTheBytes3

;---Bytes are compared, analyze results----

	tst.b		(a0)				;did I hit a zero? If I did then I have a match
	bne.s		SearchThroughEachString3
	tst.b		d2				;entire match?
	beq		SearchEachStringNoAdvance
	cmp.b		d2,d5				;':'?
	beq		SearchThroughEachString3
	subq.l	#1,a4
	move.l	a4,(a3)+
	move.w	d1,d3				;the counter
AdvancePointerThroughStrings5
	tst.b		(a4)+
	dbeq		d3,AdvancePointerThroughStrings5
	beq		SkipTooBigMarker
	or.b		#$20,-4(a3)			;mark match as too big
	subq.l	#1,d0
	bne		AdvancePointerThroughStrings3
	bra		DoneSearching
SkipTooBigMarker:
	subq.l	#1,d0
	bne		SearchEachStringNoAdvance
DoneSearching:

;----Done searching now return---------

NoExtras:
	move.l	d4,a7
	addq.l	#8,a7
	movem.l	(a7)+,d1-d7/a0-a2/a4/a5
	rts
ErrorNotString:
	move.l	d4,a7
	movem.l	(a7)+,d0/a3
	movem.l	(a7)+,d1-d7/a0-a2/a4/a5
	rts

;---Special search for zero characters----

SearchThroughEachString44:
	cmp.b		(a4),d6			;string?
	bne		ErrorNotString
	addq.l	#2,a4
AddToList_E3:
	cmp.l		a5,a4
	bcc.s		DoneSearching
	move.l	a4,(a3)+
	move.w	d1,d3				;the counter
AdvancePointerThroughStrings55
	tst.b		(a4)+
	dbeq		d3,AdvancePointerThroughStrings55
	beq		SkipTooBigMarker2
	or.b		#$20,-4(a3)			;mark match as too big
AdvanceIt2:
	tst.b		(a4)+
	bne		AdvanceIt2
SkipTooBigMarker2:
	subq.l	#1,d0
	bne		SearchThroughEachString44
	bra		DoneSearching



;------This routine adds stuff to the pointer list of matches from a
;------symbol table.

;--------------------------------------------------------
;INPUTS->	d0-# of matches limit variable
;		d6-Flag marker (is it a folder or variable?)
;		d7-handle of the symbol table
;		a3-place to store the addresses of matches
;		a2-points to the indicator of matches, complete
;		   uses this to know when to put the right
;		   arrow in the title.
;		a6-points to the jump table
;
;OUTPUTS->	d0 -number of outputs
;		a3 -maybe filled with more matches.
;
;DESTROYS-> a0,a1,a4,d1,d3,d4,a5
;---------------------------------------------------------
AddToListFromSymbolTable:
	move.w	d7,-(a7)			;the handle
	move.w	d0,d3
	move.l	600(a6),a0
	jsr		(a0)				;dereference the handle


 checkTrashing 'k'


	addq.l	#2,a7
	move.w	d3,d0
	move.w	2(a0),d1			;get the number of files in this symbol table
	lea		charBuffer(pc),a4		;stuff to search for
	addq.l	#4,a0				;point to the text
	add.l		d6,a0				;now mark it
	move.w	charBufferIndex(pc),d4
	beq		SpecialNoCharSearch

;----Quikly advance through the table to the first character of interest-----

	move.b	(a4)+,d2
	subq.w	#1,d1
	bcs.s		NoEntries
FindFirst:
	cmp.b		(a0),d2
	lea		14(a0),a0
	dbls		d1,FindFirst	;go till equal flag, or the carry flag
	bne.s		NoEntries		;if carry flag then there will be no entries
	lea		-13(a0),a0
	subq.w	#1,d4
	beq.s		PossibleSave	;if one character, then use a special search
	subq.l	#1,a0
	bra.s		SearchThroughEachString2

;----Now for the loop------------

SkipThisEntry:
	subq.w	#1,d1				;for dbra
	bcs.s		NoEntries
SearchThroughEachString2:
	move.l	a0,a5
	lea		14(a0),a0
	move.l	a4,a1
	cmp.b		(a5)+,d2			;the VERY first comparison must be equal
	bne.s		NoEntries
CompareTheBytes2:
	cmp.b		(a5)+,(a1)+
	beq.s		CompareTheBytes2
	tst.b		(a1)				;did I hit a zero? If I did then I have a match
	bne.s		NoMatch2
	tst.w		-2(a0)			;is handle null?
	beq.s		SkipThisEntry
	tst.b		-(a5)				;entire match?
	beq.s		SkipThisEntry
	move.l	a5,(a3)+
	st.b		(a2)
	subq.l	#1,d0
NoMatch2:
	dbeq		d1,SearchThroughEachString2
NoEntries:
	rts

;---Use this search if no chars have been typed---

SpecialNoCharSearch:
	st.b		(a2)
	lea		-14(a0),a0		;14 will immediately be added again
	moveq		#95,d2		;underscore
SkipThisEntry2:
	subq.w	#1,d1			;for dbra
	bcs.s		NoEntries2
SearchThroughEachString4:
	lea		14(a0),a0
	cmp.b		(a0),d2		;underscore?
	beq.s		SkipThisEntry2
	tst.w		12(a0)		;handle null?
	beq.s		SkipThisEntry2
	move.l	a0,(a3)+		;save it
	subq.w	#1,d0
	dbeq		d1,SearchThroughEachString4
NoEntries2:
	rts

;----use this search if 1 char is typed

CantSaveThisOne:
	subq.w	#1,d1
	bcs.s		NoEntries2
Search1Loop
	lea		13(a0),a0
	cmp.b		(a0)+,d2
	bne.s		Exit1Loop
PossibleSave:
	tst.b		(a0)
	beq.s		CantSaveThisOne
	tst.w		11(a0)
	beq.s		CantSaveThisOne
	st.b		(a2)
	move.l	a0,(a3)+
	subq.w	#1,d0
	dbeq		d1,Search1Loop
Exit1Loop:
	rts



;---------------------------------------------------------
;A SUBROUTINE THAT GIVEN A POINTER TO A STRING DECIDES IF
;IT NEEDS A "(" OR A "\" IF IT DOES THEN THE STRING
;IS COPPIED TO A BUFFER AND THAT CHAR IS APPPENDED.
;
;THE FIRST ENTRANCE ALSO TAKES CARE OF EXTERNAL STRINGS
;THAT MIGHT BE TOO BIG.
;---------------------------------------------------------

;--Input,	d0- pointer to the string------
;		d2- non zero if special file type association is needed
;--Output,	d0- pointer to the string-----


IsSpecialString1:					;this entrance handle strings that are too big
	btst.l	#29,d0			;  as well as folders and program variables
	beq		IsSpecialString2
	move.l	d0,a4
	lea		buffer+1(pc),a0
	move.l	a0,d0
	moveq		#10,d1				;counter
CopyLp:
	move.b	(a4)+,(a0)+
	dbra		d1,CopyLp
	move.b	#160,(a0)+			;elipses
	clr.b		(a0)				;zero terminate
	rts
IsSpecialString2:					;This entrance only is for variables
	move.l	d0,a4
	moveq		#92,d1			;char to append if it is a folder
	tst.l		d0				;check high bit (is it a folder?)
	bmi.s		AppendIt
	moveq		#40,d1			;char to append if it is a program
	btst.l	#30,d0			;is it a symbol entry?
	beq.s		NoAppendingNeeded1
	move.w	$c(a4),-(a7)		;get handle
	move.l	2332(a6),a0			;handle to esi call
	jsr		(a0)


 checkTrashing 'K'


	move.l	a4,d0				;restore pointer
	addq.l	#2,a7

;---See if it is a program so check the tags------

	cmp.b		#$DC,(a0)			;program tag
	beq.s		AppendIt
	cmp.b		#$F3,(a0)			;asm tag
	bne.s		NoAppendingNeeded2

;---Append that character--------

AppendIt:
	lea		buffer+1(pc),a0		;destination
	and.l		#$FF000000,d0		;keep flags
	add.l		a0,d0				;new place to display from (with flags)
CopyLoop2:
	move.b	(a4)+,(a0)+
	bne.s		CopyLoop2			;go till the zero terminator
	move.b	d1,-(a0)			;the extra character
	clr.b		1(a0)				;zero terminate it
NoAppendingNeeded1
	rts

;---Map the type letters------

NoAppendingNeeded2:
	tst.w		d2
	beq		NoAppendingNeeded1
	move.b	(a0),d1
	lea		types(pc),a1
	moveq		#(endTypes-types)-1,d2
FindLp:
	cmp.b		(a1)+,d1
	dbeq		d2,FindLp
	bne		NoneInTable
	move.b	7(a1),d1		;get char
	bra		HaveType
NoneInTable:
	moveq		#69,d1		;'E'
	cmp.b		#$D9,(a0)
	bne		TypeIsExpression
	moveq		#76,d1		;'L'
	cmp.b		#$D9,-(a0)
	bne		TypeIsList
	moveq		#77,d1		;'M'
TypeIsExpression:
TypeIsList:
HaveType:

;---now copy it in and append the type, but add spaces-----


	lea		buffer+1(pc),a0
	and.l		#$FF000000,d0
	add.l		a0,d0
	moveq		#10,d2
CopyVar:
	move.b	(a4)+,(a0)+
	dbeq		d2,CopyVar
	subq.l	#1,a0
CopySpaces:
	move.b	#' ',(a0)+
	dbra		d2,CopySpaces
	move.b	d1,(a0)+
	clr.b		(a0)
NoTypeAtAll:
	rts
;------------------------------------------
;Inputs ->	d0.l a pointer to a string
;		a6.l pointer to the jump table
;
;Outputs -> d0.l new pointer to the string
;		It is coppied into an internal
;		buffer before being sent allong
;		It will remove the stuff after
;		the ":" char which will also be
;		printed in the help line.
;------------------------------------------
RemoveComments:
	movem.l	d1-d3/a0/a2,-(a7)
	move.l	d0,a0
	lea		buffer(pc),a2
	clr.b		(a2)
	move.l	a2,d0				;new source
	moveq		#38,d2
	moveq		#58,d3			;':'
RemoveCommentLoop:
	move.b	(a0)+,d1
	move.b	d1,(a2)+
	beq		DoneCopying2
	cmp.b		d3,d1
	dbeq		d2,RemoveCommentLoop
	bne		DoneCopying

;---So print it, first bypass spaces------

	clr.b		-(a2)
UpIt:
	cmp.b		#' ',(a0)+
	beq		UpIt
	tst.b		-(a0)		;string with nothing?
	beq		NoPrintIt
	tst.b		1(a0)		;1 char string?
	beq		NoPrintIt
	move.l	d0,-(a7)
	move.l	a0,-(a7)
	move.l	920(a6),a0
	jsr		(a0)
	addq.l	#4,a7
	move.l	(a7)+,d0
NoPrintIt:
DoneCopying:
	clr.b		(a2)				;clear if d2 hit -1
DoneCopying2:
	movem.l	(a7)+,d1-d3/a0/a2
	rts


;---This subroutine removes the menu from the screen-------


;----Inputs-----------------------------------
;The global variable mode has the menu size
;  and the variable windowPointer points to
;  the place in video memory where the menu
;  is situated.
;----Outputs----------------------------------
;No registers destroyed, the menu is removed
;  from the screen.
;---------------------------------------------
RemoveMenu:
	movem.l	d0-d3/a0-a2,-(a7)
	move.w	handle(pc),d0
	beq		AllDone
	moveq		#19,d3
	moveq		#20,d2
	moveq		#58,d0
	move.w	mode(pc),d1
	beq		LeaveAt58
	moveq		#76,d0
LeaveAt58:
	move.l	windowPointer(pc),a1
	move.l	ptr(pc),a0
	add.l		#(NUMBER_OF_MATCHES+1)*4,a0
	move.l	a1,d1
	move		d1,ccr
	bcc		EvenAddress
	lea		CarryOnOdd(pc),a2		
	bra		OddAddress
EvenAddress:
	lea		CarryOnEven(pc),a2

;----menu is at an even address, so is the buffer----

CarryOnEven:
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	move.b	(a0)+,(a1)
	add.l		d2,a1			;next line
	subq.w	#1,d0
	bcs		AllDone

;----menu is at an odd address, buffer is at an even address
;----or maybe menu is at an even and buffer is odd

OddAddress:
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)
	add.l		d2,a1
	subq.w	#1,d0
	bcs		AllDone
	jmp		(a2)			;jump to CarryOnOdd or CarryOnEven

;-----Menu is at an odd address, buffer is at an odd address-----

CarryOnOdd
	move.b	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	add.l		d3,a1
	dbra		d0,OddAddress
AllDone:
	movem.l	(a7)+,d0-d3/a0-a2
	rts
;---------------------------------------------
;This will allocate the needed memory for
;the pointer list and screen backup buffer.
;If that fails it will escape.
;
;It will set certain variables to certain
;values, no registers will be destroyed.
;---------------------------------------------
AllocateMem:
	movem.l	d0-d2/a0-a2,-(a7)
	lea		handle(pc),a2
	tst.w		(a2)			;memory allocated?

;---Alocate memory-------

	bne		MemoryAllocated
	move.l	#880+NUMBER_OF_MATCHES*4,-(a7)
	move.l	584(a6),a0		;heap allocate high to avoid garbage collection
	jsr		(a0)


 checkTrashing 'L'



	addq.l	#4,a7
	move.w	d0,(a2)+
	beq		MemError
	move.w	d0,-(a7)
	move.l	600(a6),a0
	jsr		(a0)			;dereference
	move.l	a0,(a2)+		;save the pointer

;---Load pointer to the data----

	pea		cmpltdat(pc)
	move.l	388(a6),a0
	jsr		(a0)			;find it

 checkTrashing 'M'


	addq.l	#6,a7
	tst.l		d0
	beq		MemError		;if it does not exist
	move.l	d0,-(a7)
	move.l	484(a6),a0
	jsr		(a0)			;dereference the hsym
	move.w	$C(a0),-(a7)
	move.l	600(a6),a0		;handle dereference it
	jsr		(a0)			;point to variable
	addq.l	#4,a0			;get past the offset and  bra.s

;---move in the variables----

	move.w	2(a0),d0
	lea		0(a0,d0.w),a1
	move.l	a0,-(a7)
	lea		variables(pc),a0
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.w	(a1)+,(a0)+
	move.l	(a7),a0
	move.w	4(a0),d0
	lea		0(a0,d0.w),a1	;point to the case insensitive table
	lea		caseTable(pc),a0
	move.l	a1,(a0)
	move.l	(a7)+,a0
	move.w	(a0),d0
	lea		0(a0,d0.w),a0	;get past the code
	move.l	a0,(a2)		;put it to the variable
	addq.l	#6,a7

;---All done--------

MemoryAllocated:
	movem.l	(a7)+,d0-d2/a0-a2
	rts
MemError:
	movem.l	(a7)+,d0-d2/a0-a2
	addq.l	#4,a7
	bra		RestoreTheScreenAndRestartBuffer