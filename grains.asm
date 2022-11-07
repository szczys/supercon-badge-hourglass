;;;;;;;;;;;;;;;;;;;;;;;;;
; Wasting Time
; by Mike Szczys
; MIT License 2022
;
; Cellular automata to simulate sand grains of an hourglass on the 8x16 LED
; display of the 2022 Hackaday Superconference badge
;;;;;;;;;;;;;;;;;;;;;;;;;

; Register map:
; R1 = upper page address
; R2 = lower page address
; R6 = column address [0..3]
; R8 = loop counter (create bit every 3 loops)

start:
; set slow clock speed
MOV R0,0b0100
MOV [0b1111:0b0001],R0

; Show page 2
MOV R0,0b0010
MOV [0b1111:0b0000],R0

; clear memory
MOV R0,0b0000 ; zeros to copy to registers
MOV R1,0b0010 ; upper nibble address
MOV R2,0b1111 ; lower nibble address

; clear page 2
MOV [R1:R2],R0
DSZ R2
JR [0b1111:0b1101]
MOV [R1:R2],R0
; clear page 3
INC R1
MOV [R1:R2],R0
DSZ R2
JR [0b1111:0b1101]
MOV [R1:R2],R0
DEC R1

; set up timer
MOV R8,0b0010 ; Start timer at max-1

loop:
; Reset the upper page nibble
MOV R1,2

; set up column tracker
MOV R6,0b1111 ; Start at min-1
; increment timer
INC R8
MOV R0,R8
; check timer for creation frame
CP R0,0b0011  ; Compare counter to 3
SKIP Z,2 ; Skip next 3 lines if R0 == 3
GOTO frames

  ; check for full hourglass
  ;   this will restart the app when the display is full, but only when the
  ;   grain being created is on lower page, bit 3
  ;   FIXME: make grain generation location and rate variable
  ;          physics for this work, but the creation/restart logic doesn't
  MOV R0,[R1:R2]
  BIT R0,3
  SKIP Z,2
  GOTO start

  ; create grain
  MOV R0,0b1000
  MOV [R1:R2],R0
  ; Restart timer for next run
  MOV R8,0b0000

; FIXME: testing to create grain on second page
;        this won't be checked for a full display
;  INC R1
;  MOV R0,0b0100
;  MOV [R1:R2],R0
;  DEC R1


; service movement frames
frames:
  ; iterate from 14..0
  ; start from 15. it will dec before starting loop
  MOV R2,0b1110
  ; locate grain in row
  findgrain:
  ; Check column tracker
  MOV R0,R6
  CP R0,3 ; When R6==bit3, we're done scanning
  SKIP Z,2
  GOTO process_columns ; Keep iterating columns
  MOV R6,0b1111 ; Restart column tracker

  ; check if R2 is zero
  MOV R0,R2
  CP R0,0
  SKIP Z,2
  GOTO continueframes ; R2 is not zero, keep checking rows

  ; R2 is zero. Check if we need to increment pages
  MOV R0,R1
  CP R0,2
  SKIP Z,2
  GOTO loop ; Both pages are done, start the loop anew

  ; Lower page is finished so run again for upper page
  INC R1
  MOV R2,0b1111
  ; end zero check

  continueframes:
  DEC R2 ; dec happens at beginning of loop

  process_columns:
  INC R6;
  MOV R0,R6
  CP R0,0
  SKIP NZ, 2
  GOTO check_zero
  CP R0,1
  SKIP NZ, 2
  GOTO check_one
  CP R0,2
  SKIP NZ, 2
  GOTO check_two
  CP R0,3
  SKIP NZ, 2
  GOTO check_three
  GOTO findgrain

;;;;;;;;;;;;;;;;;check bit0 loc
check_zero:
  MOV R0,[r1:r2]
  BIT R0,0
  SKIP NZ,2
  GOTO findgrain ; no grain found

  ; grain found
  INC R2
  MOV R0,[r1:r2]
  ; check below
  BIT R0,0
  SKIP NZ,2
  GOTO zero_availzero
;  BIT R0,0
;  SKIP NZ,2
;  GOTO one_availzero
  BIT R0,1
  SKIP NZ,2
  GOTO zero_availone

  ;Check if left page
  MOV R0,R1
  CP R0,3
  SKIP Z,3
  DEC R2
  GOTO findgrain ; This is not an edge-case; move along

  ; This the right edge of the left page, check across page break
  DEC R1
  MOV R0,[R1:R2]
  BIT R0,3
  SKIP Z,0
  INC R1
  DEC R2
  GOTO findgrain ; there's no room, reset registers and move along

  ; We found room, set new grain and erase old
  GOSUB setthree
  INC R1 ; Reset upper page address (done with page break operations)
  GOTO erasezero ; found space

  ; draw new grain
  zero_availzero:
  GOSUB setzero
  GOTO erasezero
  zero_availone:
  GOSUB setone
  GOTO erasezero

;;;;;;;;;;;;;;;;;;;;;;;;end check bit0 loc

;;;;;;;;;;;;;;;;;check bit1 loc
check_one:
  MOV R0,[r1:r2]
  BIT R0,1
  SKIP NZ,2
  GOTO findgrain ; no grain found

  ; grain found
  INC R2
  MOV R0,[r1:r2]
  ; check below
  BIT R0,1
  SKIP NZ,2
  GOTO one_availone
  BIT R0,0
  SKIP NZ,2
  GOTO one_availzero
  BIT R0,2
  SKIP NZ,2
  GOTO one_availtwo
  DEC R2
  GOTO findgrain ; grain below, do nothing

  ; draw new grain, erase old
  one_availzero:
  GOSUB setzero
  GOTO eraseone
  one_availone:
  GOSUB setone
  GOTO eraseone
  one_availtwo:
  GOSUB settwo
  GOTO eraseone
  one_availthree:
  GOSUB setthree
  GOTO eraseone

;;;;;;;;;;;;;;;;;;;;;;;;end check bit1 loc

;;;;;;;;;;;;;;;;;check bit2 loc
check_two:
  MOV R0,[r1:r2]
  BIT R0,2
  SKIP NZ,2
  GOTO findgrain ; no grain found

  ; grain found
  INC R2
  MOV R0,[r1:r2]
  ; check below
  BIT R0,2
  SKIP NZ,2
  GOTO two_availtwo
  BIT R0,1
  SKIP NZ,2
  GOTO two_availone
  BIT R0,3
  SKIP NZ,2
  GOTO two_availthree

  DEC R2
  GOTO findgrain ; grain below, do nothing

  ; draw new grain, erase old
  two_availone:
  GOSUB setone
  GOTO erasetwo
  two_availtwo:
  GOSUB settwo
  GOTO erasetwo
  two_availthree:
  GOSUB setthree
  GOTO erasetwo

;;;;;;;;;;;;;;;;;;;;;;;;end check bit1 loc

;;;;;;;;;;;;;;;;;check bit3 loc
check_three:
  MOV R0,[r1:r2]
  BIT R0,3
  SKIP NZ,2
  GOTO findgrain ; no grain found

  ; grain found
  INC R2
  MOV R0,[r1:r2]
  ; check below
  BIT R0,3
  SKIP NZ,2
  GOTO three_availthree ; found space

  BIT R0,2
  SKIP NZ,2
  GOTO three_availtwo ; found space

  ;Check if right page
  MOV R0,R1
  CP R0,2
  SKIP Z,3
  DEC R2
  GOTO findgrain ; This is not an edge-case; move along

  ; This the left edge of the right page, check across page break
  INC R1
  MOV R0,[R1:R2]
  BIT R0,0
  SKIP Z,0
  DEC R1
  DEC R2
  GOTO findgrain ; there's no room, reset registers and move along

  ; We found room, set new grain and erase old
  GOSUB setzero
  DEC R1 ; Reset upper page address (done with page break operations)
  GOTO erasethree ; found space

  ; draw new grain, erase old
  three_availtwo:
  GOSUB settwo
  GOTO erasethree
  three_availthree:
  GOSUB setthree
  GOTO erasethree

;;;;;;;;;;;;;;;;;;;;;;;;end check bit3 loc

; Erase previous grain
erasezero:
DEC R2
MOV R0,[R1:R2]
BCLR R0,0
MOV [R1:R2],R0
GOTO findgrain

eraseone:
DEC R2
MOV R0,[R1:R2]
BCLR R0,1
MOV [R1:R2],R0
GOTO findgrain

erasetwo:
DEC R2
MOV R0,[R1:R2]
BCLR R0,2
MOV [R1:R2],R0
GOTO findgrain

erasethree:
DEC R2
MOV R0,[R1:R2]
BCLR R0,3
MOV [R1:R2],R0
GOTO findgrain

setzero:
BSET R0,0
MOV [R1:R2],R0
RET R0,0

setone:
BSET R0,1
MOV [R1:R2],R0
RET R0,0

settwo:
BSET R0,2
MOV [R1:R2],R0
RET R0,0

setthree:
BSET R0,3
MOV [R1:R2],R0
RET R0,0

