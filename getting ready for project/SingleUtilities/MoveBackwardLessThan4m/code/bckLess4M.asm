;R4 store received character
;R3 for storing value of TH from ultrasonic echo
ORG 0
LeftForward EQU P1.0
LeftBackward EQU P1.1
RightForward EQU P1.2
RightBackward EQU P1.3

TRIG EQU P2.0
ECHO EQU P2.1

CLR TRIG		; sets P2.0(TRIG) as output for sending trigger
SETB ECHO		; sets P2.1(ECHO) as input for receiving echo

CLR LeftForward		; sets P1.0(LeftForward) as output for sending trigger
CLR LeftBackward	; sets P1.1(LeftBackward) as output for sending trigger
CLR RightForward	; sets P1.2(RightForward) as output for sending trigger
CLR RightBackward	; sets P1.3(RightBackward) as output for sending trigger

MOV TMOD, #00100000B	;Mode 2 for timer 1 (8 bit auto reload)
MOV TH1, #0FDH		;setting baud rate 9600
MOV SCON, #01010000B	;Serial Mode 1, REN Enabled

;SETB TR1	;Run timer 1

;TRIG CODE
AutoDriveMode:   
	SETB TRIG		; starts the trigger pulse
	ACALL Delay10M     	; Delay 10uS width for the trigger pulse
	CLR TRIG         	; ends the trigger pulse
	
	JNB ECHO,$    		; loops here until echo is received

	ACALL CalcDistance
	JB TF0, MoveForward 
	JNB TF0, MoveBackward
	
		
x:	ACALL DelaySec		  ;Delay 1 sec   
	SJMP AutoDriveMode        ;short jumps to MAIN loop	
		
MoveForward:
	CLR RightBackward
	CLR LeftBackward
	SETB RightForward
	SETB LeftForward	
	JMP x	
	
MoveBackward:
	CLR RightForward	
	CLR LeftForward
	SETB RightBackward
	SETB LeftBackward
	JMP x

StopCar:
	CLR RightBackward
	CLR LeftBackward
	CLR RightForward	
	CLR LeftForward
	RET


;FeedBck:MOV SBUF, R4
	;JNB TI, $
	;CLR TI
	;SJMP Receive	;Jump back to Receive
	
		
CalcDistance:
	;Loop until ECHO pin is low
	MOV TMOD, #00000001B	;set timer0 as mode 1 16-bit 
	;Start counting ticks from 44103D => AC47
	MOV TL0, #47H
	MOV TH0, #0ACH

	SETB TR0	;start timer 0
	
	;TODO LOOP while ECHO 1 and TF0 is 0	
	JB ECHO, $	;If ECHO is high loop to echo is 1 
	CLR TR0

	;Move TH0 to R6 to be printed
	;MOV R6, TH0
	;ACALL DLOOP
	
	;Move TL0 to R6 to be printed	
	;MOV R6, TL0
	;ACALL DLOOP
RET

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


END	