; set slow clock speed
MOV R0,0b1010
MOV [0b1111:0b0001],R0

; clear memory
MOV R0,0b0000 ; zeros to copy to registers
MOV R1,0b0001 ; upper nibble address
MOV R2,0b1111 ; lower nibble address

; display page
MOV [R1:R2],R0
DSZ R2
JR [0b1111:0b1101]
MOV [R1:R2],R0

; set up timer
start:
MOV R0,0b0011 ; Start timer at max

; check timer for creation frame
loop:
CP R0,0b0100  ; Compare counter to 3
SKIP C,0b0011 ; Skip next 3 lines if R0 < 3

  ; create grain
  MOV R0,0b0010 ; Use for grain creation
  MOV [0b0001:0b0000],R0
  MOV R0,0b0000 ; Restart timer for next run


; service movement frames

INC R0
GOTO loop

  ; iterate from 14..0
  ; locate grain in row
    ; check below
	; check below right
	; check below left
	; move if space

