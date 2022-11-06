; set slow clock speed
MOV R0,0b0101
MOV [0b1111:0b0001],R0

; Show page 2
MOV R0,0b0010
MOV [0b1111:0b0000],R0

; clear memory
MOV R0,0b0000 ; zeros to copy to registers
MOV R1,0b0010 ; upper nibble address
MOV R2,0b1111 ; lower nibble address

; display page
MOV [R1:R2],R0
DSZ R2
JR [0b1111:0b1101]
MOV [R1:R2],R0

; set up timer

start:
MOV R8,0b0010 ; Start timer at max-1

; check timer for creation frame
loop:
INC R8
MOV R0,R8
CP R0,0b0011  ; Compare counter to 3
SKIP NZ,3 ; Skip next 3 lines if R0 < 3

  ; create grain
  MOV R0,0b0010 ; Use for grain creation
  MOV [R1:R2],R0
  MOV R8,0b0000 ; Restart timer for next run


; service movement frames

frames:
  ; iterate from 14..0
  ; start from 15. it will dec before starting loop
  MOV R2,0b1111
  ; locate grain in row
  findgrain:
  ; put R2 zero check here
  MOV R0,R2
  CP R0,0
  SKIP NZ,2
  GOTO loop

  DEC R2
  MOV R0,[R1:R2]
  BIT R0,1
  SKIP NZ,2
  GOTO findgrain ; no grain found

  ; grain found
  INC R2
  MOV [R1:R2],R0
  BSET R0,1
  MOV R0,[R1:R2]
  DEC R2
  ; Erase previous grain
  MOV R0,[R1:R2]
  BCLR R0,1
  MOV [R1:R2],R0
  GOTO findgrain
    ; check below
	; check below right
	; check below left
	; move if space
