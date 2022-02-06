;R4 store received character
ORG 0
LED EQU P2.0
CLR LED
MOV P1, #0
SETB P1.0
MOV TMOD, #00100000B	;Mode 2 for timer 1 (8 bit auto reload)
MOV TH1, #0FDH		;setting baud rate 9600
MOV SCON, #01010000B	;Serial Mode 1, REN Enabled

SETB TR1	;Run timer 1
Receive:JNB RI, $	;Waiting for receive interrupt flag
	MOV A, SBUF	;Move received character to A
	CLR RI		;Clear receive interrupt flag
	MOV R4, A
	Switch:	CLR C		;Clear carry flag befor using SUBB for comparing
		SUBB A, #'1'	;Compare A to 1
		JZ LEDON	;If A = 1 turn on LED	
		
		MOV A, R4;	
		CLR C		;Clear carry flag befor using SUBB for comparing
		SUBB A, #'0'	;Compare A to 0
		JZ LEDOFF	;If A = 0 turn off LED
		
		SJMP Receive	;Jump back to Receive
		
LEDON:	SETB LED
	JMP FeedBck	
	
LEDOFF:	CLR LED
	JMP FeedBck

FeedBck:MOV SBUF, R4
	JNB TI, $
	CLR TI
	SJMP Receive	;Jump back to Receive
		
	


END	