;copyright 2004 Samuel Stearley


;This file contains the arrays, variables, and strings used by complete.



charBufferIndex2:		dc.w	0		;to keep a backup of the char buffer index when
							;  the unit shortcut menu is in view
zeroTerminator		dc.l	0		;place to keep the pointer to the end zero of the
							;  external dot notation database to search through
title:			dc.l	0		;place to keep the pointer to the title
lastUnitMenuWMatches:	dc.w	0		;used to prevent repeating arrows from causing the
							;  scrolling of the unit menu to wrap around when
							;  skipping unit types that have no match.
offsetTableIndex:		dc.w	0		;the index into the offset table.  Alter it to
							;  select the units that are wanted.
oldOffsetTableIndex	dc.w	0		;used for when it needs to automatically change units
charBuffer:			ds.b	12		;where to keep the character to search for
listBufferIndex:		dc.w	0		;for scrolling the menu
charBufferIndex:		dc.w	0		;where to place the next character in the buffer

menuIndic:			dc.b	0		;used to tell if the menu is visible
unitIndic:			dc.b	0		;tells if a unit menu is active
folderWasCompleted:	dc.b	0		;Remembers if a folder was the last to be completed
flashAppIndic:		dc.b	0		;Tells if only an external database should be loaded
							;  because the dot notation was used.
pageIndic:			dc.b	0		;indicates if only the variables should be shown in
							;  the menu as a result of pressing the right arrow
foldersAndVarsIndic:	dc.b	0		;Gets set if any folders or variables are in
							;  the list
oneThingAllowed		dc.b	0		;If backspace is pressed this is set and then
							;  if 1 item is in the menu it will not try
							;  and put it straight to the entry line.
autoUnitScrollDirection	dc.b	0		;The direction the unit menu automatically scrolls
							;  0 for right, nonzero for left.
unitReplacementIndic:	dc.b	0		;Dictates how the unit menu displays the help text.
renderingNeeded		dc.b	0		;Avoid flicker when denying the changing of unit
							;  menus
shortcutTableInView	dc.b	0
listIsFull			dc.b	0		;if set then the list of ptrs is not full


upArrow:			dc.b	23,0		;the up arrow
downArrow:			dc.b	24,0		;the down arrow
rightArrow:			dc.b	22,0		;the right arrow

currentFolderName:	ds.b	10		;10 bytes of storage for the current folder name
							;  or the name of the external database used with
							;  flash app dot notation.
variableTitle:		dc.b	"Folders-Variables",0
onlyVariablesTitle:	dc.b	"Current Variables",0
unitVariableTitle:	dc.b	"Variables",0

activatedFlag:		dc.b	0		;set this and complete will not process any events.
							;  It is usually set right before complete sends
							;  events with the send event rom call.
buffer:
nextUnitsBuffer		ds.b	55		;This is where partial titles of the next unit
							;  menus are copied to.
main:				dc.b	0,"main"
mainEnd:			dc.b	0

types:
	dc.b	$2D,$DD,$DE,$DF,$E0,$E1,$E2,$F8
endTypes:
	dc.b	"SDGPTFmO"

seperationCharacters:	dc.b	"#^{}()[]+-/*= <>",18
				dc.b	22,59,58,39,159,34,44,124,173,38,152
				dc.b	157,156,158,33,37,169,149,140,150,190,151,154,155
afterSepChars:

	;18 is the convert, 37 is a "%", 33 is a factorial, 44 is a ","
	;124 is a "|", 34 is a "'", 159 is an angle, 39 is a minute, 59 is a ";"
	;58 is a ":", 173 is a negate, 22 is a store, 38 is amperstand
	;152 is the radian degree sign, 157 is a not equal, 156 is less than or equal to
	;158 is greater than or equal to, 169 is a @, 149 is an E, 140 is pi
	;150 is an e (e associated with LN(), not the letter)
	;190 is an infinity, 151 is an i ( sqrt(-1) ), 154 is x-bar, 155 is y bar.

	EVEN	


variables:				;these are the variables that are in cmpldat.89z
mode:		dc.w	0		;1 for large font, 0 for small font
menuMoves:	dc.w	0		;0 for no moving
useXtrast1	dc.w	0		;0 use it
right:	dc.w	0
mRight:	dc.w	0
left:		dc.w	0
useUscore	dc.w	0		;0 for underscore, non zero it strips off leading underscore
caseTable	dc.l	0		;will be loaded with a pointer to a table to speed up case
					;  insensitive searching
handle:	dc.w	0		;handle of allocated memory
ptr		dc.l	0		;pointer to the allocated memory
externalDb:	dc.l	0		;will be loaded with a pointer to the data



pasteEvent:
	dc.w		$723			;paste
	dc.w		0			;sender
	dc.w		0			;side
	dc.w		0			;status flags
pasteEventAddress:
	dc.l		0			;address of the text to paste

deleteEvent:
	dc.w		$725,0,0,0,0

shiftBackEvent:
	dc.w		$710,0,0,0,0

 ifd ti89
	dc.w		8530
 endc

 ifd ti92plus
	dc.w		16721		
 endc


menuX:
	dc.w		0			;used to remember x of menu
windowPointer:
	dc.l		0			;used to video memory location of menu


systemVariableText:	dc.b		"Sys Vr",0

		dc.b	0,"_xtrast1"
_xtrast1:	dc.b	0

		dc.b	"cmpltdat"
cmpltdat:	dc.b	0

functionString:		dc.b	"1:",0


 ifd ti89
shortcutTable:
	dc.b	')'	;c
	dc.b	"4"	;l
	dc.b	"="	;a
	dc.b	"0"	;v
	dc.b	"t"	;t
	dc.b	"5"	;m
	dc.b	"|"	;f
	dc.b	"/"	;e
	dc.b	149	;E is k
	dc.b	","	;d
	dc.b	"8"	;h
	dc.b	"9"	;i
	dc.b	"2"	;r
	dc.b	"3"	;s
	dc.b	"7"	;g
	dc.b	"."	;w
	dc.b	"x"	;x
	dc.b	"y"	;y
	dc.b	"z"	;z
	dc.b	"^"	;^
	dc.b	"("	;b
	dc.b	"*"	;j
	dc.b	"6"	;n
	dc.b	45	;minus is an o
	dc.b	"1"	;q
	dc.b	"+"	;u
	dc.b	173	;negate
	dc.b	13	;enter
	dc.b	0	;terminate
 endc

 ifd ti92plus
shortcutTable:
	dc.b	"clavtmfekdhirsgwxyz^bjnoqu ",13
	dc.b	"p=",0
 endc


	Even	

shortcutOffsets:
	dc.w	0	;c
	dc.w	4	;l
	dc.w	6	;a
	dc.w	8	;v
	dc.w	10	;t
	dc.w	22	;m
	dc.w	24	;f
	dc.w	26	;e
	dc.w	32	;k
	dc.w	34	;d
	dc.w	36	;h
	dc.w	38	;i
	dc.w	44	;r
	dc.w	46	;s
	dc.w	52	;g
	dc.w	54	;w
	dc.w	58	;x
	dc.w	NUMBER_OF_UNIT_MENUS-2	;y
	dc.w	12	;z
	dc.w	14	;^
	dc.w	16	;b
	dc.w	18	;j
	dc.w	20	;n
	dc.w	30	;o
	dc.w	40	;q
	dc.w	42	;u
	dc.w	48	;negate
	dc.w	50	;enter

 ifd ti92plus
	dc.w	28	;p
	dc.w	56	;=
 endc



