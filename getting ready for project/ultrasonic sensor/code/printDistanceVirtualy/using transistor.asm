;R5 is used in DLOOP for POPing from stack
;R6 is used in printing, storing ECHO times to be printed
;R7 is used in all Delays, as counter in DLOOP
ORG 0
JMP program

ORG 000BH
JMP intof



ORG 100H
program:
MOV P1,#00000000B      ; sets P1 as output port
MOV P0,#00000000B      ; sets P0 as output port

TRIG EQU P2.0
CLR TRIG               ; sets TRIG as output for sending trigger

ECHO EQU P2.1
SETB ECHO              ; sets ECHO as input for receiving echo

USGROUND EQU P2.2
SETB USGROUND

MOV A, #0H
MOV IE, #10000010B	;enable external interrupts IE0, IE1
MAIN:   ;TRIG CODE
	CLR P1.0
	SETB TRIG		; starts the trigger pulse
	ACALL Delay10M     	; Delay 10uS width for the trigger pulse
	CLR TRIG         	; ends the trigger pulse
	JNB ECHO,$    		; loops here until echo is received

	ACALL CalcDistance
		
	;ACALL DelaySec	 ;Delay 1 sec   		   						
	SJMP MAIN        ;short jumps to MAIN loop
	
;Display LOOP for send char to serial port for printing it on virtual terminal
DLOOP:	MOV TMOD, #20H	; or 00100000B => Mode 2 for Timer 1 (8bit Auto Reload)
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
		MOV SBUF, A
		JNB TI, $
		CLR TI
		;ACALL DelaySec		;TODO i think it is not useful
		DJNZ R7, print		;decrements the byte indicated by the first operand and, if the resulting value is not zero, branches to the address specified in the second operand.
		MOV A, #' '
		MOV SBUF, A
		JNB TI, $
		CLR TI
	
RET

CalcDistance:
	;Loop until ECHO pin is low
	MOV TMOD, #00000001B	;set timer0 as mode 1 16-bit 
	;Start counting ticks from 44103D => AC47
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
	;ACALL DelaySec
	;ACALL DelaySec
	SETB P2.2		
		 
	clear:CLR TR0
	
	;Subroutine UDIV32
;32-Bit / 16-Bit to 32-Bit Quotient & Remainder Unsigned Divide
;input: r3, r2, rl, r0 = Dividend X
;D, r4 = Divisor Y
;output: r3, r2, r1, r0 = quotient Q of division Q = X/ Y
;r7, r6, r5, r4 = remainder
;alters: acC, Tlags

	MOV R3, #0
	MOV R2, #0
	MOV R1, TH0
	MOV R0, TL0
	
	MOV R5, #0
	MOV R4, #58	
	
	ACALL UDIV32
	
	MOV A, R1
	MOV R6, A
	
	;Move TH0 to R6 to be printed
;	MOV R6, TH0
;	ACALL DLOOP
	
	MOV A, R0
	MOV R6, A	
	;Move TL0 to R6 to be printed	
	;MOV R6, TL0
	ACALL DLOOP
RET
	


;Delay 10 micro sec
Delay10M:
	MOV R6,#2D     ; 10uS delay
LABEL1: DJNZ R6,LABEL1
        RET
RET 

;Delay 1000 micro sec
Delay1000M:
	MOV TMOD, #00000001B ;set timer0 as mode 2 16-bit
	;MOV TL0, #66H
	;MOV TH0, #0FCH
	
	MOV TL0, #47H
	MOV TH0, #0ACH
	
	SETB TR0
	
	JNB TF0, $
	CLR TR0
	CLR TF0
RET 


intof:
SETB P1.0
RETI



















;Subroutine UDIV32
;32-Bit / 16-Bit to 32-Bit Quotient & Remainder Unsigned Divide
;input: r3, r2, rl, r0 = Dividend X
;D, r4 = Divisor Y
;output: r3, r2, r1, r0 = quotient Q of division Q = X/ Y
;r7, r6, r5, rd = remainder
;alters: acC, Tlags
UDIV32: push 08 ;Save Register Bank 1
	push 09
	push 0AH
	push 0BH
	push 0CH
	push 0DH
	push 0EH
	push 0FH
	push dpl
	push dph
	push B
	setb RS0 ;Select Register Bank 1
	mov r7, #0 ;clear partial remainder
	mov r6, #0
	mov r5, #0
	mov r4, #0
	mov B, #32 ;Set loop coutt
div_lp32: clr RS0 ;Select Register Bank
	clr C ;clear carry flag
	mov a, r0 ;shift the highest bit of the
	rlc a ;dividend into...
	mov r0, a
	mov a, r1
	rlc a
	mov r1, a
	mov a, r2
	rlc a
	mov r2, a
	mov a, r3
	rlc a
	mov r3,a
	setb RS0 ;Select Register Bank 1
	mov a, r4;...the lowest bit of the
	rlc a; partial remainder
	mov r4, a
	mov a, r5
	rlc a
	mov r5, a
	mov a, r6
	rlc a
	mov r6, a
	mov a, r7
	rlc a
	mov r7, a
	mov a, r4;trial subt ract divisor from
	clr C;partial remainder
	subb a, 04
	mov dpl, a
	mov a, r5
	subb a, 05
	mov dph, a
	mov a, r6
	subb a, #0
	mov 06, a
	mov a, r7
	subb a, #0
	mov 07, a
	cpl C;Complement external borrow
	jnc div_321;update partial remainder if borrow
	mov r7, 07;update partial remainder
	mov r6, 06
	mov r5, dph
	mov r4, dpl
div_321: mov a, r0;shift result bit into partial
	rlc a;quotient
	mov r0, a
	mov a, r1
	rlc a
	mov r1, a
	mov a, r2
	rlc a
	mov r2, a
	mov a, r3
	rlc a	
	mov r3,a
	djnz B, div_lp32
	mov 07, r7;put remainder, saved before the
	mov 06,r6;last subt raction, in bank 0
	mov 05, r5
	mov 04, r4
	mov 03, r3;put quotient in bank 0
	mov 02, r2
	mov 01, r1
	mov 00, r0
	clr RS0
	pop B
	pop dph
	pop dpl
	pop 0FH;Retrieve Register Bank 1
	pop 0EH
	pop 0DH
	pop 0CH
	pop 0BH
	pop 0AH
	pop 09
	pop 08
ret



close:
	END