ORG 0                

MOV P1,#00000000B      ; sets P1 as output port
MOV P0,#00000000B      ; sets P0 as output port
CLR P2.0               ; sets P2.0 as output for sending trigger
SETB P2.1              ; sets P2.1 as input for receiving echo
MOV TMOD,#00100000B    ; sets timer1 as mode 2 auto reload timer
MAIN: MOV TL1,#207D    ; loads the initial value to start counting from
      MOV TH1,#207D    ; loads the reload value
      MOV A,#00000000B ; clears accumulator
      SETB P2.0        ; starts the trigger pulse
      ACALL DELAY1     ; gives 10uS width for the trigger pulse
      CLR P2.0         ; ends the trigger pulse
HERE: JNB P2.1,HERE    ; loops here until echo is received
BACK: SETB TR1         ; starts the timer1
HERE1: JNB TF1,HERE1   ; loops here until timer overflows (ie;48 count)
      CLR TR1          ; stops the timer
      CLR TF1          ; clears timer flag 1
      INC A            ; increments A for every timer1 overflow
      JB P2.1,BACK     ; jumps to BACK if echo is still available
      MOV R4,A         ; saves the value of A to R4
      ACALL DLOOP      ; calls the display loop
      SJMP MAIN        ; jumps to MAIN loop

DELAY1: MOV R6,#2D     ; 10uS delay
LABEL1: DJNZ R6,LABEL1
        RET 

DLOOP: 
	MOV TMOD, #20H	; or 00100000B => Mode 2 for Timer1 (8bit Auto Reload)
	MOV TH1, #0FDH	;Setting BaudRate of 9600 (-3). SMOD is 0 by default
	MOV SCON, #50H	;Serial Mode 1, REN Enabled or 01010000B
	SETB TR1
AGAIN:	MOV SBUF, A
	JNB TI, $
	CLR TI
	SJMP MAIN
END