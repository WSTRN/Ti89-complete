;By Samuel Stearley copyright 2004



;-----This is the code for the unit menu replacement------

PossiblyNewUnitMenu:
	cmp.w		#$710,(a2)		;check here if not in the home app
	bne		PassItOn

 ifd ti89
	cmp.w		#4147,10(a2)	;is it the units?
	bne		PassItOn
 endc

 ifd ti92plus
	cmp.w		#8272,10(a2)
	bne		PassItOn
 endc

;-----The following code is executed if it the unit menu is executed

DefinitelyUnitMenu:
	move.w	#$700,(a2)		;make it command idle
	move.b	menuIndic(pc),d0
	beq.s		NotSeen
	bsr		RemoveMenu
	lea		menuIndic(pc),a0
	clr.b		(a0)
NotSeen:

;----Allocate memory----------

	move.l	200,a6
	bsr		AllocateMem

;------Now To actually do the unit menu-------

NewUnitMenu2:

;----Set certain variables----

	moveq		#0,d7
NewUnitMenu3:
	lea		unitIndic(pc),a0
	st.b		(a0)
	lea		unitReplacementIndic(pc),a0
	st.b		(a0)
	move.w	offsetTableIndex(pc),d2
	cmp.w		#NUMBER_OF_UNIT_MENUS,d2
	bcs		NotVariablePage
	moveq		#0,d2
	lea		offsetTableIndex(pc),a0
	move.w	d2,(a0)
NotVariablePage:
	cmp.w		#NUMBER_OF_UNIT_MENUS-2,d2
	bne		KeepUnitMenu
	move.l	externalDb(pc),a0
	move.w	(a0),d1
	lea		2(a0,d1.w),a0	;point to the system variable strings
	bra		UseSystemVariables
KeepUnitMenu
	move.l	externalDb(pc),a0
	move.w	2(a0),d0	
	lea		0(a0,d0.w),a0	;point to the offset table
	move.w	0(a0,d2.w),d0
	lea		2(a0,d0.w),a0	;point to the data item, the '2' is to get past the
UseSystemVariables:			;  indexed flag.
DoShortcutMenu:
	move.w	(a0)+,d1
	bne		ThereIsExternal
	sub.l		a5,a5
	bra		KeepA52
ThereIsExternal:
	lea		-4(a0,d1.w),a5
KeepA52:
	move.w	(a0)+,d1
	move.w	(a0)+,d2
	lea		title(pc),a1
	move.l	a0,(a1)		;new title for the menu.
	move.l	ptr(pc),a3
	moveq		#NUMBER_OF_MATCHES,d0;max number of items in the list
	tst.w		d2
	bne		NoCompensate
Adver
	tst.b		(a0)+
	bne		Adver
NoCompensate:

;----Advance a0 past the title----

Advances:
	tst.b		(a0)+
	bne.s		Advances

;----put pointers to the list---

	move.l	a0,(a3)+		;add to the list
	addq.l	#3,a0
	subq.w	#1,d0			;decrease the number of remaining
	dbeq		d1,Advances		;add pointers to all the strings

;----Add external data items to the list----

	tst.w		d7
	bne		NoExternal
	lea		charBuffer(pc),a0
	move.w	#$0100,(a0)		;let in everything with out question

;----Set up for the call to add to the list from an external---

	cmp.w		#NUMBER_OF_UNIT_MENUS-2,d2;system vars?
	beq		NoExternal
	move.l	a5,a0
	bsr		AddFromExternal

;----Display the menu---

NoExternal
	and.w		#%1111,d0
ZeroThem:
	clr.l		(a3)+			;zero the rest of them
	dbra		d0,ZeroThem
	lea		listBufferIndex(pc),a0
	clr.l		(a0)
ReDoMenu2:

 ifd ti89
	moveq		#4,d5			;x of menu
 endc

 ifd ti92plus
	moveq		#10,d5
 endc

	lea		menuX(pc),a0
	move.w	d5,(a0)		;for when the menu is gotten rid of
	move.l	d7,-(a7)
	bsr		DisplayMenu
	move.l	(a7)+,d7

;----Idle and process keys-----

CanNotScroll2:
	clr.l		-(a7)
	clr.w		-(a7)
	move.l	1528(a6),a0
	jsr		(a0)
	addq.l	#6,a7
	lea		listBufferIndex(pc),a0
	move.w	(a0),d1
	moveq		#32,d2

 ifd ti89
	cmp.w		#337,d0		;up?
	beq.s		ScrollUp2
	cmp.w		#340,d0		;down?
	bne.s		NotVerticalArrows2
 endc

 ifd ti92plus
	cmp.w		#338,d0
	beq.s		ScrollUp2
	cmp.w		#344,d0
	bne.s		NotVerticalArrows2
 endc

;----Code to scroll down----------------

	move.l	ptr(pc),a1
	tst.l		32(a1,d1)		;is the first adress of the next page a zero?
	beq		CanNotScroll2
	add.w		d2,d1
	move.w	d1,(a0)
	bra		ReDoMenu2

;----Code to scroll up------------------

ScrollUp2:
	tst.w		d1			;are we still on the first page?
	beq		CanNotScroll2
	sub.w		d2,d1
	move.w	d1,(a0)
	bra		ReDoMenu2
NotVerticalArrows2:


;----maybe a shortcut table---------

	lea		offsetTableIndex(pc),a0

 ifd ti89
	moveq		#56,d1
	cmp.w		#277,d0		;home?
	beq		PutIt
	moveq		#28,d1
	cmp.w		#258,d0		;store? (p)
	beq		PutIt
 endc

	cmp.w		#256,d0		;a char?
	bcc		NotShortcut
	lea		shortcutTable(pc),a4
	lea		shortcutOffsets-2(pc),a1
SearchTable:
	addq.l	#2,a1
	tst.b		(a4)
	beq		NotShortcut
	cmp.b		(a4)+,d0
	bne		SearchTable
	move.w	(a1),d1
PutIt:
	move.w	d1,(a0)
	bra		NewUnitMenu2

NotShortcut:
	tst.w		d7		;any other key results in the previous menu being displayed
	bne		NewUnitMenu2

;----is it apps?------------

	cmp.w		#265,d0
	bne		NotApps
	moveq		#1,d7
NeedShortcuts:
	lea		unitIndic(pc),a0
	clr.b		(a0)			;no help
	move.l	externalDb(pc),a0
	move.w	2(a0),d0
	lea		0(a0,d0.w),a0	;point to the offset table
	move.w	-2(a0),d0
	lea		2(a0,d0.w),a0	;point to the data base
	bra		DoShortcutMenu

;----Is it escape?---------

NotApps:
	cmp.w		#264,d0
	beq		RestoreTheScreenAndRestartBuffer

;----Now For right and left arrows-----------

	moveq		#2,d1			;increment
	move.w	(a0),d2

 ifd ti89
	cmp.w		#4440,d0		;2nd + right?
	beq.s		ScrollMuchRight2
	cmp.w		#338,d0		;left?
	beq.s		ScrollLeft3
	cmp.w		#344,d0		;right?
	bne.s		NotHorizontalArrows2
 endc

 ifd ti92plus
	cmp.w		#4436,d0
	beq.s		ScrollMuchRight2
	cmp.w		#337,d0
	beq.s		ScrollLeft3
	cmp.w		#340,d0
	bne.s		NotHorizontalArrows2
 endc

;----code to scroll right---------------

	cmp.w		#NUMBER_OF_UNIT_MENUS-2,d2;are we already as far left as possible?
	bne.s		NoWrapToLeftSide2		;then we can not scroll it
	moveq		#-2,d2
NoWrapToLeftSide2:
	add.w		d1,d2
	move.w	d2,(a0)
	bra		NewUnitMenu2

;----code to scroll left---------------

ScrollLeft3:
	sub.w		d1,d2
	bcc.s		NoWrapToRightSide2
	moveq		#NUMBER_OF_UNIT_MENUS-2,d2
NoWrapToRightSide2:			
	move.w	d2,(a0)
	bra		NewUnitMenu2

;----code to scroll much right-----------

ScrollMuchRight2:
	add.w		#14,d2
	cmp.w		#NUMBER_OF_UNIT_MENUS,d2
	bcs.s		SkipWrapping3
	sub.w		#NUMBER_OF_UNIT_MENUS,d2
SkipWrapping3:
	move.w	d2,(a0)
	bra		NewUnitMenu2
NotHorizontalArrows2:


;----Now for the function keys------------

	move.w	d0,d1
	sub.w		#268,d1
	bcs		CanNotScroll2
	cmp.w		#8,d1
	bcc		CanNotScroll2
	lsl.w		#2,d1
	move.w	listBufferIndex(pc),d2
	add.w		d1,d2
	move.l	ptr(pc),a0
	move.l	0(a0,d2),d0
	beq		CanNotScroll2
	bra		PasteString