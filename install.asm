;Copyright 2004 by Samuel Stearely


;This file has the installation code.



	movem.l	d3-d7/a2-a6,-(a7)
	move.l	a7,d7
	move.l	200,a6
	moveq		#16,d6		;value to add, will be increased for a hw2 by 0x40000
	

; Hardware version detection, adapted from gray.s
; Copyright (C) 2002 Thomas Nussbaumer.
; Copyright (C) 2003 Kevin Kofler.
; See License.txt for licensing conditions.
; Slightly modified by me Samuel

__get_hw_version:
    ;--------------------------------------------------------------------------
    ; get the HW parm block using the algorithm suggested by Julien Muchembled
    ;--------------------------------------------------------------------------
        move.l   $c8,d0
        andi.l   #$E00000,d0 ; get the ROM base
        movea.l  d0,a0
        movea.l  260(a0),a1  ; get pointer to the hardware param block
        adda.l   #$10000,a0
        cmpa.l   a0,a1      ;  check if the HW parameter block is near enough
        bcc.s    L.is_hw1      ; if it is too far, it is HW1
        cmpi.w   #22,(a1)     ; check if the parameter block contains HW ver
        bls.s    L.is_hw1      ; if it is too small, it is HW1
    ;--------------------------------------------------------------------------
    ; check for VTI (trick suggested by Julien Muchembled)
    ;--------------------------------------------------------------------------
        trap     #12         ; enter supervisor mode. returns old (sr) in d0.w
        move.w   #$3000,sr ; set a non-existing flag in sr (but keep s-flag)
        move.w   sr,d1     ; get sr content and check for non-existing flag
        move.w   d0,sr     ; restore old sr content
        btst.l   #12,d1     ; this non-existing flag can only be set on the VTI
        beq.s    L.not_vti   ; flag not set -> no VTI
    ;--------------------------------------------------------------------------
    ; VTI detected -> treat as HW1
    ;--------------------------------------------------------------------------
        ; Fall through...

L.is_hw1:
    ;--------------------------------------------------------------------------
    ; HW1 detected
    ;--------------------------------------------------------------------------
	  bra.s  NO_ADD
L.not_vti:
    ;--------------------------------------------------------------------------
    ; Real calculator detected, so read the HW version from the HW parm block
    ;--------------------------------------------------------------------------
        move.l   22(a1),d0 ; get the hardware version
	  cmp.b	#2,d0
	  bne.s	NO_ADD
	  add.l #$40000,d6
NO_ADD:



;---First thing to do is to find the pointer to the home text edit structure
;---to get pointers to the various variables.  And then put it into code.

	move.l	1080(a6),a0			;get pointer to the code of home execute call
	move.l	708(a6),d0			;get pointer to te_select- will search
							;  for this value in the code of the home execute
							;  call
SearchLoop:
	addq.l	#2,a0				;code is word alligned
	cmp.l		(a0),d0			;is it the place to jsr too?
	bne.s		SearchLoop
	move.w	-4(a0),d0			;now got pointer to the tios entyline text edit
							;  structure.
	add.w		#18,d0			;point it to the cursor position
	lea		moveOpcode5+2(pc),a0
	move.w	d0,(a0)
	add.w		#12,d0			;point to the cursor x value
	lea		moveOpcode3+2(pc),a0
	move.w	d0,(a0)
	add.w		#2,d0				;point to the flag
	lea		btstOpcode+4(pc),a0	;point to adress operand
	move.w	d0,(a0)			;move it into the ram
	addq.w	#2,d0				;point to the handle
	lea		moveOpcode4+2(pc),a0
	move.w	d0,(a0)

;---The Second thing to do is to get the pointer to the window flags of the
;---applications and install it into my code

	move.l	3324(a6),a0		;command display home, force it to start
	jsr		(a0)

;----get and install the home applications window flags---

	move.l	(a6),a0		;get pointer to the first window pointer
	move.l	(a0),a0
	addq.w	#1,a0
	lea		tstOpcode+2(pc),a1
	move.w	a0,(a1)

;---The third thing to do is get the handle of the folder table-----

	pea		mainEnd(pc)
	move.l	392(a6),a0
	jsr		(a0)			;get the hsym of the main folder
	swap		d0
	lea		moveOpcode+2(pc),a0
	move.w	d0,(a0)

;---The fourth thing to do is install the tios pointer to the global
;---buffer that has the folder name in it.

	move.l	416(a6),a0			;rom call that pushes the buffer
	lea		6(a0),a0
	moveq		#0,d0
	move.w	(a0)+,d0
	bne.s		SkipSecondWord
	move.w	(a0),d0
SkipSecondWord:
	lea		leaOpcode2+2(pc),a1
	move.l	d0,(a1)

;---And finally install the code to allocated ram-------

	move.l	2700(a6),a5			;got pointer to old evhook
	lea		oldEvent(pc),a1		;get pointer to the save space
	move.l	(a5),(a1)
	move.l	#END_OF_HOOK-BEGINNING_OF_HOOK,d3
	move.l	d3,-(a7)
	move.l	584(a6),a0			;get heap allocate high call
	jsr		(a0)
	pea		errorMessage
	tst.w		d0
	beq.s		MemoryError
	move.w	d0,-(a7)
	move.l	600(a6),a0			;get dereference call
	jsr		(a0)
	move.l	a0,a1
	add.l		d6,a0				;increase to bypass hw2 protection
	move.l	a0,(a5)			;overwrite old event handler
	subq.l	#1,d3
	lea		BEGINNING_OF_HOOK(pc),a0
CopyLoop:
	move.b	(a0)+,(a1)+
	dbra.s	d3,CopyLoop
	pea		message(pc)
MemoryError:
	move.l	920(a6),a0			;help display call
	jsr		(a0)
	move.l	d7,a7
	movem.l	(a7)+,d3-d7/a2-a6
	rts


_comment:
message:		dc.b		"Complete by Samuel Stearley (C) 2005",0
errorMessage:	dc.b		"Error: Not enough Memory",0