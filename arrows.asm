;copyright 2004 by Samuel Stearley


;This file has the code that responds to the arrows.


;----See if a unit menu is needed it checks here in this file if the
;----current app is the home app.

 ifd ti89
	cmp.w		#4147,d0
	beq		DefinitelyUnitMenu
 endc

 ifd ti92plus
	cmp.w		#8272,d0
	beq		DefinitelyUnitMenu
 endc

	btst.w	#11,8(a2)	
	sne		d4			;will indicate if arrow is auto repeated

;----If the menu is visible then it will respond differently------

	move.b	menuIndic(pc),d1
	bne		VisibleSoHandleKeys

;----2nd + up response is the up-directory-----------------------

 ifd ti89
	cmp.w		#4433,d0
 endc

 ifd ti92plus
	cmp.w		#4434,d0
 endc

	bne		NotUpDirectory

;----Now set main as the current directory-----------

	clr.w		-(a7)
	pea		mainEnd(pc)
	move.l	404(a6),a0
	jsr		(a0)			;set folder call


 checkTrashing 'F'


	pea		main+1(pc)
	move.l	912(a6),a0
	jsr		(a0)			;change status line stuff


 checkTrashing 'G'


	move.w	#$700,(a2)
	lea		10(a7),a7
	bra		PassItOn

;----Maybe an instant menu of current variables------

NotUpDirectory:

 ifd ti89
	cmp.w		#340,d0
 endc

 ifd ti92plus
	cmp.w		#344,d0
 endc

	bne		MaybeSystemVariables

;----Check if it is an auto repeated arrow, if it is then do not give a menu-----

	move.w	#$700,(a2)				;make into cm_idle
	tst.b		d4
	bne		PassItOn

;----Make a menu of only variables---------

	bsr		AllocateMem
	move.l	ptr(pc),a3
	lea		title(pc),a0
	lea		onlyVariablesTitle(pc),a1
	move.l	a1,(a0)				;title of the menu
	lea		folderWasCompleted(pc),a0
	st.b		(a0)
;	lea		charBuffer(pc),a0
;	move.w	#$0100,(a0)				;string to search for (let everything in)
	moveq		#NUMBER_OF_MATCHES,d0
;	lea		charBufferIndex(pc),a0
;	clr.w		(a0)
	bra		SearchAndDisplay

;----Maybe a menu of system variables--------

MaybeSystemVariables:

 ifd ti89
	cmp.w		#4436,d0
 endc

 ifd ti92plus
	cmp.w		#4440,d0
 endc

	bne		NotVisibleSoIgnoreRemainingKeys

;----Do menu of only system variables------

	move.w	#$700,(a2)				;make into cm_idle
	lea		pageIndic(pc),a0
	st.b		(a0)
;	lea		charBuffer(pc),a0
;	move.w	#$0100,(a0)				;string to search for (let everything in)
;	lea		charBufferIndex(pc),a0
;	clr.w		(a0)
	bra		NewMenu	

;----Normall scrolling operations of the menu
;----see if the up or down arrows were pressed

VisibleSoHandleKeys:
	moveq		#20,d2			;increment or decrement
	move.w	#$700,d3			;idle event
	lea		listBufferIndex(pc),a0	;get pointer to the value to be modified 
	move.w	(a0),d1

 ifd ti89
	cmp.w		#337,d0			;up
	beq.s		ScrollUp
	cmp.w		#340,d0			;down
	bne.s		NotVerticalArrows
 endc

 ifd ti92plus
	cmp.w		#338,d0			;up
	beq.s		ScrollUp
	cmp.w		#344,d0			;down
	bne.s		NotVerticalArrows
 endc

;----Code to scroll down----------------

	move.w	d3,(a2)
	move.l	ptr(pc),a1
	tst.l		20(a1,d1)			;is the first adress of the next page a zero?
	bne		CanScroll
	tst.w		d1				;are we already on the first page
	beq		CanNotScroll
	tst.b		d4
	bne		PassItOn
	move.w	d2,d1
	neg.w		d1				;so when it adds it become zero
CanScroll:
	add.w		d2,d1
	move.w	d1,(a0)
	bra		ReDoMenuNoClearing

;----Code to scroll up------------------

ScrollUp:
	move.w	d3,(a2)
	tst.w		d1
	bne		ScrollNormal		;are we on the first page?
	move.l	ptr(pc),a1
	tst.l		0(a1,d2)			;is there a second page?
	beq		CanNotScroll

;---find lowest page----

	tst.b		d4
	bne		PassItOn
KeepGoing
	add.w		d2,d1
	tst.l		0(a1,d1)
	bne		KeepGoing
ScrollNormal
	sub.w		d2,d1
	move.w	d1,(a0)
	bra		ReDoMenuNoClearing

;----If it is a unit menu, then the right and left keys are enabled to change
;----the types of units that the user wants.

NotVerticalArrows:
	move.b	shortcutTableInView(pc),d1
	bne		NothingElseMatters
	lea		right(pc),a4
	lea		charBuffer(pc),a1
	move.b	unitIndic(pc),d1
	beq.s		NotAUnitMenu

;----right and left arrow code for the units------

	moveq		#2,d1					;increment
	lea		autoUnitScrollDirection(pc),a1
	clr.b		(a1)
	lea		offsetTableIndex(pc),a0
	move.w	(a0),d2

	cmp.w		2(a4),d0			;2nd + right?
	beq.s		ScrollMuchRight
	cmp.w		4(a4),d0			;left?
	beq.s		ScrollLeft
	cmp.w		(a4),d0			;right?
	bne		NotHorizontalArrows

;----code to scroll right---------------

	move.w	d3,(a2)			;make it command idle
	cmp.w		#NUMBER_OF_UNIT_MENUS,d2
	bne.s		NoWrapToLeftSide
	tst.b		d4
	bne		PassItOn
	moveq		#-2,d2
NoWrapToLeftSide:
	add.w		d1,d2
	move.w	d2,(a0)
	bra		NewUnitMenu

;----code to scroll left---------------

ScrollLeft:
	move.w	d3,(a2)
	sub.w		d1,d2
	bcc.s		NoWrapToRightSide
	tst.b		d4
	bne		PassItOn
	moveq		#NUMBER_OF_UNIT_MENUS,d2
NoWrapToRightSide:			
	move.w	d2,(a0)
	st.b		(a1)
	bra		NewUnitMenu

;----code to scroll much right-----------

ScrollMuchRight:
	move.w	d3,(a2)
	add.w		#14,d2
	cmp.w		#NUMBER_OF_UNIT_MENUS+2,d2
	bcs.s		SkipWrapping2
	sub.w		#NUMBER_OF_UNIT_MENUS+2,d2
SkipWrapping2:
	move.w	d2,(a0)
	bra		NewUnitMenu
NotAUnitMenu:

;----Handle arrows without units This will cause only the folders and
;----variable names to be depicted

	move.b	folderWasCompleted(pc),d1
	or.b		flashAppIndic(pc),d1

	cmp.w		4(a4),d0			;left?
	beq.s		ScrollLeft2
	cmp.w		(a4),d0			;right?
	bne		NotHorizontalArrows

;---Code to make it display only the variables and folders Right arrow was pressed

	move.w	d3,(a2)
	tst.b		d1				;Deny displaying folders and variables
	bne		PassItOn			; if already displaying files in an auto
							; completed folder.
	lea		pageIndic(pc),a0
	move.b	(a0),d0
	subq.b	#1,d0
	beq		PassItOn
	bcs		FoldersAndVariables
	addq.b	#1,(a0)			;system variables to normal
	bra		NewMenu
FoldersAndVariables:
	addq.b	#1,(a0)
	lea		variableTitle(pc),a0
	lea		title(pc),a3		;we get a new title
	move.l	a0,(a3)
	move.b	listIsFull(pc),d0
	beq		OnlyVariables		;reset the pointer list and search only through
							;the variable lists
	move.b	foldersAndVarsIndic(pc),d0
	beq		OnlyVariables
	move.l	ptr(pc),a0
	move.l	a0,a3
	moveq		#NUMBER_OF_MATCHES,d0
	move.l	#$40000000,d1
FindFirstVar
	cmp.l		(a0)+,d1
	bcc		FindFirstVar
	subq.l	#4,a0
CopyLower:
	move.l	(a0)+,(a3)+
	dbeq		d0,CopyLower
	lea		listBufferIndex(pc),a0	;get scrolling variable
	clr.w		(a0)
	bra		DoVisuals

;---Code to make it display the commands again Left arrow was pressed----

ScrollLeft2:
	move.w	d3,(a2)
	tst.w		d1
	bne		PassItOn			;are we in an autocompleted folder?
	lea		pageIndic(pc),a0
	tst.b		(a0)
	bmi		PassItOn			;are we on system var page?
	subq.b	#1,(a0)
	lea		oneThingAllowed(pc),a0
	st.b		(a0)
	bra		IncludeAll
NotHorizontalArrows:
NothingElseMatters:

;---After this file program execution flows into the code for the funtion keys
;---in complete.asm