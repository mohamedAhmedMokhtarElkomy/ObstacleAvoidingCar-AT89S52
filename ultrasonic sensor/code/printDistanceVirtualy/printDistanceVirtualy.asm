;R5 is used in DLOOP for POPing from stack
;R6 is used in printing, storing ECHO times to be printed
;R7 is used in all Delays, as counter in DLOOP
ORG 0
MOV P1,#00000000B      ; sets P1 as output port
MOV P0,#00000000B      ; sets P0 as output port

TRIG EQU P2.0
CLR TRIG               ; sets TRIG as output for sending trigger

ECHO EQU P2.1
SETB ECHO              ; sets ECHO as input for receiving echo

MAIN:     
	SETB TRIG		; starts the trigger pulse
	ACALL Delay10M     	; Delay 10uS width for the trigger pulse
	CLR TRIG         	; ends the trigger pulse
	JNB ECHO,$    		; loops here until echo is received
	MOV A, #0H
	
	;Loop until ECHO pin is low
	echoIS1:ACALL Delay1000M	;Delay 10 microsecond
		INC A		;Increment number of 10 microseconds occured
		JB ECHO, echoIS1;If ECHO is high loop to echo is 1 
		MOV R6, A	;Store A value in R6
		ACALL DLOOP      ;calls the display loop to print A which is stored in 
		
		ACALL DelaySec	 ;Delay 1 sec   		   						
		SJMP MAIN        ;short jumps to MAIN loop
	
;TODO remove		
;DELAY1: MOV R6,#2D     ; 10uS delay
;LABEL1: DJNZ R6,LABEL1
;        RET 
	
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
    	SETB TR0 ;Start timer 0
    	
    	JNB TF0, $ ;Loop until Timer 0 overflow = 1
    	CLR TR0 ;Stop timer 0
    	CLR TF0 ;Clear overFlow
    	
    	DJNZ R7, DelaySecLoop ;Decrement A then if A != 0 jump to DelaySecLoop
    	
;    	POP 07H
RET

;Delay 10 micro sec
Delay10M:
	MOV TMOD, #00000001B ;set timer0 as mode 2 8-bit auto relode
	MOV TL0, #0F7H
	MOV TH0, #0FFH
	
	SETB TR0
	
	JNB TF0, $
	CLR TR0
	CLR TF0
RET 
;Delay 10 micro sec
Delay1000M:
	MOV TMOD, #00000001B ;set timer0 as mode 2 8-bit auto relode
	MOV TL0, #66H
	MOV TH0, #0FCH
	
	SETB TR0
	
	JNB TF0, $
	CLR TR0
	CLR TF0
RET 

close:
	END