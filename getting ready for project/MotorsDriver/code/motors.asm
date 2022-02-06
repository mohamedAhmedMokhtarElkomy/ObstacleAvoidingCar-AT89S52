;R4 store received character
ORG 0
LeftForward EQU P2.0
LeftBackward EQU P2.1
RightForward EQU P2.2
RightBackward EQU P2.3

CLR LeftForward
CLR LeftBackward
CLR RightForward
CLR RightBackward

MOV TMOD, #00100000B	;Mode 2 for timer 1 (8 bit auto reload)
MOV TH1, #0FDH		;setting baud rate 9600
MOV SCON, #01010000B	;Serial Mode 1, REN Enabled

SETB TR1	;Run timer 1
Receive:JNB RI, $	;Waiting for receive interrupt flag
	MOV A, SBUF	;Move received character to A
	CLR RI		;Clear receive interrupt flag
	MOV R4, A
	Switch:	CLR C		;Clear carry flag befor using SUBB for comparing
		SUBB A, #'f'	;Compare A to 1
		JZ MoveForward	;If A = 1 turn on LED	
		
		MOV A, R4;	
		CLR C		;Clear carry flag befor using SUBB for comparing
		SUBB A, #'b'	;Compare A to 0
		JZ MoveBackward	;If A = 0 turn off LED
		
		MOV A, R4;	
		CLR C		;Clear carry flag befor using SUBB for comparing
		SUBB A, #'s'	;Compare A to 0
		JZ Stop	;If A = 0 turn off LED
		
		
		SJMP Receive	;Jump back to Receive
		
MoveForward:
	CLR RightBackward
	CLR LeftBackward
	SETB RightForward
	SETB LeftForward	
	JMP FeedBck	
	
MoveBackward:
	CLR RightForward	
	CLR LeftForward
	SETB RightBackward
	SETB LeftBackward
	JMP FeedBck

Stop:	CLR RightBackward
	CLR LeftBackward
	CLR RightForward	
	CLR LeftForward

FeedBck:MOV SBUF, R4
	JNB TI, $
	CLR TI
	SJMP Receive	;Jump back to Receive
		
	


END	