_nostub	xdef	_nostub

; Original Stub
;        tst.w ($30).w
;       bne.s KernelInstalled
;        add.l #4,a7
;        rts
;KernelInstalled:
;       move.l ($34).w,a0
;        jmp (a0)

; New small stub
;	move.l	($34).w,-(a7)
;	bne.s	\run
;	addq.l	#8,a7
;\run	rts
	
; MiStub Stub:
;	move.l	($34).w,-(a7)
;	beq.s	\error
;	rts
;\error	addq.l	#8,a7

; install_kernel Stub:
	move.l	($34).w,a0
	move.l	a0,d0
	bne.s	\jump
	move.l	(a7)+,$4004C	; Save address of program
	link	a6,#0
	move.w	#7,-(a7)	; Size
	bsr.s	\cont		; Push String
	dc.b	"preos()",0	; String
\cont	move.l	($4).w,a0
\loop		addq.l	#2,a0
		cmp.l	#$4E5E4E75,(a0) ; unlnk / rts
		bne.s	\loop
	pea	(a0)		; return address
	move.l	($c8).w,a0
	move.l	4*$10E(a0),a0	; HomeExecute
\jump	jmp	(a0)

	end
