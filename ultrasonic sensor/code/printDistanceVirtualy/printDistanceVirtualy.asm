;R5 is used in DLOOP for POPing from stack
;R6 is used in printing, storing ECHO times to be printed
;R7 is used in all Delays, as counter in DLOOP
ORG 0


TRIG EQU P2.3
CLR TRIG               ; sets TRIG as output for sending trigger

ECHO EQU P2.4
SETB ECHO              ; sets ECHO as input for receiving echo

USGROUND EQU P0.2
SETB USGROUND


RS BIT P2.0
RW BIT P2.1
EN  BIT P2.2
DATABUS EQU P1
LCD_F BIT P1.7

;LCD INITIALIZATION
		MOV A, #38H	; INITIATE LCD
		ACALL COMMANDWRT

		MOV A, #0FH	; DISPLAY ON CURSOR ON
		ACALL COMMANDWRT
		
		MOV A, #01H	; CLEAR LCD
		ACALL COMMANDWRT
MOV A, #0H
MAIN:   ;TRIG CODE
	SETB TRIG		; starts the trigger pulse
	ACALL Delay10M     	; Delay 10uS width for the trigger pulse
	CLR TRIG         	; ends the trigger pulse
	JNB ECHO,$    		; loops here until echo is received

	ACALL CalcDistance
		
	ACALL DelaySec	 ;Delay 1 sec   		   						
	SJMP MAIN        ;short jumps to MAIN loop
	
;Display LOOP for send char to serial port for printing it on virtual terminal
DLOOP:	MOV A, #01H	; CLEAR LCD
	ACALL COMMANDWRT
	MOV TMOD, #20H	; or 00100000B => Mode 2 for Timer 1 (8bit Auto Reload)
	MOV TH1, #0FDH	;Setting BaudRate of 9600 (-3). SMOD is 0 by default
	MOV SCON, #50H	;Serial Mode 1, REN Enabled or #01010000B
	SETB TR1

	MOV A, R6
	MOV R7, #0D	;Counter to store count of numbers
;PrintDEC, print => for converting hex value to decimal then print each number	
	PrintDEC:
		INC R7
		MOV B, #10D
		DIV AB			;the quotient is stored in the accumulator and the remainder is stored in the B register
		PUSH B
		CJNE A, #0D, PrintDEC	;Compare the first two operands and branches to the specified destination if their values are not equal
	
	print:	POP 05H			;POP to 05H which is R5
		MOV A, R5
		ADD A, #'0'		;Add 0 hex value to print number from 0 to 9
		MOV R1, A;TODO REMOVE
		;PRINTING A CHARACTER
		CALL SENDCHAR
		MOV A, R1;TODO remove
		MOV SBUF, A
		JNB TI, $
		CLR TI
		;ACALL DelaySec		;TODO i think it is not useful
		DJNZ R7, print		;decrements the byte indicated by the first operand and, if the resulting value is not zero, branches to the address specified in the second operand.
		MOV A, #' '
		MOV R1, A;TODO REMOVE
		;PRINTING A CHARACTER
		CALL SENDCHAR
		MOV A, R1;TODO remove
		MOV SBUF, A
		JNB TI, $
		CLR TI
	
RET

CalcDistance:
	;Loop until ECHO pin is low
	MOV TMOD, #00000001B	;set timer0 as mode 1 16-bit 
	;Start counting ticks from 44103D => AC47
	;MOV TL0, #0EFH
	;MOV TH0, #14H
	
	MOV TL0, #47H
	MOV TH0, #0ACH

	SETB TR0	;start timer 0
	
	;TODO LOOP while ECHO 1 and TF0 is 0	
	;JB ECHO, $	;If ECHO is high loop to echo is 1 
	;CLR TR0

	checkecho:JB ECHO, checkof
		JMP clear
	checkof:JB TF0, restart
		JMP checkecho
		
restart:CLR P2.2
	ACALL DelaySec
	ACALL DelaySec
	SETB P2.2		
		 
	clear:CLR TR0
	
	;Move TH0 to R6 to be printed
	;MOV R6, TH0
	;ACALL DLOOP
	
	;Move TL0 to R6 to be printed	
	;MOV R6, TL0
	;ACALL DLOOP
	
	CLR C
	MOV A, TH0
	SUBB A, #0ACH
	MOV R1, A;for division
	
	CLR C
	MOV A, TL0
	SUBB A, #47H
	MOV R0, A
	
	MOV R3, #0
	MOV R2, #58D
	
	ACALL DIV_16
	MOV A, R2
	MOV R6, A
	ACALL DLOOP
RET
	
;TODO store old value of R7
DelaySec:
    	MOV TMOD, #00000001B ;set timer0 as mode 1 16-bit 
    	MOV R7, #20D
    	;Timer Clk = 11.0592/12*1 = 0.9216 MHz
	;50000 uS / (1 / 0.9216)uS = 46080 [65536 - 46080 = 19456 => 4C00H]
	DelaySecLoop:
    		MOV TL0, #00H
    		MOV TH0, #4CH
    		SETB TR0	;Start timer 0
    	
    		JNB TF0, $	;Loop until Timer 0 overflow = 1
    		CLR TR0		;Stop timer 0
    		CLR TF0		;Clear overFlow
    	
    		DJNZ R7, DelaySecLoop ;Decrement A then if A != 0 jump to DelaySecLoop
    	
;    	POP 07H
RET

;Delay 10 micro sec
Delay10M:
	MOV TMOD, #00000001B ;set timer0 as mode 1 16-bit
	MOV TL0, #0F7H
	MOV TH0, #0FFH
	
	SETB TR0
	
	JNB TF0, $
	CLR TR0
	CLR TF0
RET 

;Delay 1000 micro sec
Delay1000M:
	MOV TMOD, #00000001B ;set timer0 as mode 2 16-bit
	MOV TL0, #66H
	MOV TH0, #0FCH
	
	SETB TR0
	
	JNB TF0, $
	CLR TR0
	CLR TF0
RET 
		
		
;SENDING A CHARACHTER SUBROUTINE
SENDCHAR:
	ACALL DATAWRT
	ACALL DELAY
	RET		

;COMMAND SUB-ROUTINE FOR LCD CONTROL
COMMANDWRT:

    	MOV P1, A ;SEND DATA TO P1
	CLR RS	;RS=0 FOR COMMAND
	CLR RW	;R/W=0 FOR WRITE
	SETB EN	;E=1 FOR HIGH PULSE
	ACALL DELAY
	CLR EN	;E=0 FOR H-L PULSE
	
	RET

;SUBROUTINE FOR DATA LACTCHING TO LCD
DATAWRT:

	MOV DATABUS, A
    	SETB RS	;RS=1 FOR DATA
    	CLR RW
    	SETB EN
    	ACALL DELAY
	CLR EN

	RET

	

;DELAY SUBROUTINE
DELAY:
    	MOV R0, #10 ;DELAY. HIGHER VALUE FOR FASTER CPUS
Y:	MOV R1, #255
	DJNZ R1, $
	DJNZ R0, Y

	RET

;16bit division
; R1 R0
; / R3 R2
; = R3 R2
; shift left the divisor such that the number of digits
; in the divisor is the same as the number of digits in the dividend
; shift right the divisor and substract this shifted divisor from the dividend
; repeat the process again until the divisor has shifted into its original position	
DIV_16:		
	CLR C 	;Clear carry initially
	MOV R4,#00h	;Clear R4 working variable initially
	MOV R5,#00h	;CLear R5 working variable initially
	MOV B,#00h 	;Clear B since B will count the number of left-shifted bits
lshift:		
	INC B 	;Increment counter for each left shift
	MOV A,R2 	;Move the current divisor low byte into the accumulator
	RLC A 	;Shift low-byte left, rotate through carry to apply highest bit to high-byte
	MOV R2,A 	;Save the updated divisor low-byte
	MOV A,R3 	;Move the current divisor high byte into the accumulator
	RLC A 	;Shift high-byte left high, rotating in carry from low-byte
	MOV R3,A 	;Save the updated divisor high-byte
	JNC lshift 	;Repeat until carry flag is set from high-byte
rshift: 		;Shift right the divisor
	MOV A,R3 	;Move high-byte of divisor into accumulator
	RRC A 	;Rotate high-byte of divisor right and into carry
	MOV R3,A 	;Save updated value of high-byte of divisor
	MOV A,R2 	;Move low-byte of divisor into accumulator
	RRC A 	;Rotate low-byte of divisor right, with carry from high-byte
	MOV R2,A 	;Save updated value of low-byte of divisor
	CLR C 	;Clear carry, we don't need it anymore
	MOV 07h,R1 	;Make a safe copy of the dividend high-byte
	MOV 06h,R0 	;Make a safe copy of the dividend low-byte
	MOV A,R0 	;Move low-byte of dividend into accumulator
	SUBB A,R2 	;Dividend - shifted divisor = result bit (no factor, only 0 or 1)
	MOV R0,A 	;Save updated dividend
	MOV A,R1 	;Move high-byte of dividend into accumulator
	SUBB A,R3 	;Subtract high-byte of divisor (all together 16-bit substraction)
	MOV R1,A 	;Save updated high-byte back in high-byte of divisor
	JNC result 	;If carry flag is NOT set, result is 1
	MOV R1,07h 	;Otherwise result is 0, save copy of divisor to undo subtraction
	MOV R0,06h	
result:		
	CPL C 	;Invert carry, so it can be directly copied into result
	MOV A,R4	
	RLC A 	;Shift carry flag into temporary result
	MOV R4,A 	
	MOV A,R5	
	RLC A	
	MOV R5,A 	
	DJNZ B,rshift 	;Now count backwards and repeat until "B" is zero
	MOV R3,05h 	;Move result to R3/R2
	MOV R2,04h 	;Move result to R3/R2
	RET	
	

close:
	END