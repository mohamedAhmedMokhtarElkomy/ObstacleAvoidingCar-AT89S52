ORG 0000H; location where execution of the program starts from
LJMP START; LJMP used to bypass the ISR

ORG 0023H; location for ISR for both TI and RI
LJMP SERIALINT

;R4 store received character
;R3 for storing value of TH from ultrasonic echo
ORG 30H
START:
LeftForward EQU P1.0
LeftBackward EQU P1.1
RightForward EQU P1.2
RightBackward EQU P1.3
AutoLED EQU P1.7	;LED indicate if Auto mode is on or not

TRIG EQU P2.0
ECHO EQU P2.1

CLR TRIG		; sets P2.0(TRIG) as output for sending trigger
SETB ECHO		; sets P2.1(ECHO) as input for receiving echo

CLR LeftForward		; sets P1.0(LeftForward) as output for sending trigger
CLR LeftBackward	; sets P1.1(LeftBackward) as output for sending trigger
CLR RightForward	; sets P1.2(RightForward) as output for sending trigger
CLR RightBackward	; sets P1.3(RightBackward) as output for sending trigger

;Setup serial port and timer 1 for bluetooth
MOV TMOD, #00100001B	;Mode 2 for timer 1 (8 bit auto reload)
MOV TH1, #0FDH		;setting baud rate 9600
MOV SCON, #01010000B	;Serial Mode 1, REN Enabled
SETB TR1		;Run timer 1
MOV IE, #10000000B	;enables interrupt

NormalMode: 
	CLR AutoLED
	ACALL StopCar
	
Main:	JNB RI, $	;Waiting for receive interrupt flag
	MOV A, SBUF	;Move received character to A
	CLR RI		;Clear receive interrupt flag
	MOV R4, A
	
;;;;;;;;Switch;;;;;;;;
	CLR C		;Clear carry flag befor using SUBB for comparing
	SUBB A, #'f'	;Compare A to 'f'
	JZ Jmvfwd	;If A = 'f' MoveForward
	
	MOV A, R4;	
	CLR C		;Clear carry flag befor using SUBB for comparing
	SUBB A, #'b'	;Compare A to 'b'
	JZ Jmvbwd	;If A = 'b' MoveBackward
	
	MOV A, R4;	
	CLR C		;Clear carry flag befor using SUBB for comparing
	SUBB A, #'r'	;Compare A to 'r'
	JZ Jmvright	;If A = 'r' MoveRight
	
	MOV A, R4;	
	CLR C		;Clear carry flag befor using SUBB for comparing
	SUBB A, #'l'	;Compare A to 'l'
	JZ Jmvleft	;If A = 'l' MoveLeft
	
	MOV A, R4;	
	CLR C		;Clear carry flag befor using SUBB for comparing
	SUBB A, #'a'	;Compare A to 'a'
	JZ AutoDriveMode;If A = 'a' then active auto drive
		
	MOV A, R4;	
	CLR C		;Clear carry flag befor using SUBB for comparing
	SUBB A, #'s'	;Compare A to 's'
	JZ Jstop	;If A = 's' stop the car


;;;;;;TRY TO OPTIMIZE;;;;;;
Jmvfwd:	ACALL MoveForward
JMP BckMain
Jmvbwd:ACALL MoveBackward
JMP BckMain
Jmvright:ACALL MoveRight
JMP BckMain
Jmvleft:ACALL MoveLeft
JMP BckMain
Jstop:ACALL StopCar
JMP BckMain		
BckMain:SJMP Main	;Jump back to Main for looping
;;;;;;TRY TO OPTIMIZE;;;;;;


;AutoDriveMode is mode for auto move and detect objects
AutoDriveMode:   
	MOV IE, #10010000B; enables serial interrupt which can be caused by both TI/RI
	SETB AutoLED
	
TrigAgain:
	CLR C
	JNB AutoLED, NormalMode	;IF autoLed pin is 0 JMP to NormalMode
	
	SETB TRIG		; starts the trigger pulse
	ACALL Delay10M     	; Delay 10uS width for the trigger pulse
	CLR TRIG         	; ends the trigger pulse
	
	JNB ECHO,$    		; loops here until echo is received

	ACALL CalcDistance
	
	JB TF0, NoObj		
	ACALL Detected
	SJMP TrigAgain
	
NoObj:	ACALL MoveForward
	SJMP TrigAgain		;short jumps to again loop	
		
MoveForward:
	CLR RightBackward
	CLR LeftBackward
	SETB RightForward
	SETB LeftForward	
	;ACALL FeedBck
	RET
	
MoveBackward:
	CLR RightForward	
	CLR LeftForward
	SETB RightBackward
	SETB LeftBackward
	;ACALL FeedBck
	RET
	
MoveRight:
	CLR RightBackward
	CLR LeftBackward
	CLR RightForward
	SETB LeftForward	
	;ACALL FeedBck
	RET
	
MoveLeft:
	CLR RightForward	
	CLR LeftForward
	SETB RightBackward
	CLR LeftBackward
	;ACALL FeedBck
	RET

StopCar:
	CLR RightBackward
	CLR LeftBackward
	CLR RightForward	
	CLR LeftForward
	;ACALL FeedBck
	RET
Detected:
	CALL MoveBackward
	RET
	
		
CalcDistance:
	;Loop until ECHO pin is low
	;Start counting ticks from 44103D => AC47
	MOV TL0, #47H
	MOV TH0, #0ACH

	SETB TR0	;start timer 0
	
	;TODO LOOP while ECHO 1 and TF0 is 0	
	JB ECHO, $	;If ECHO is high loop to echo is 1 
	CLR TR0

RET

;Delay 10 micro sec
Delay10M:
	;MOV TMOD, #00000001B ;set timer0 as mode 1 16-bit
	MOV TL0, #0F7H
	MOV TH0, #0FFH
	
	SETB TR0
	
	JNB TF0, $
	CLR TR0
	CLR TF0
RET 
	

SERIALINT:
	JB TI, TRANS; if the interrupt is caused by T1 control is transferred to trans as the old data has been transferred and new data can be sent to the SBUF
	CLR AutoLED
        CLR RI; clears RI flag
        RETI; transfers control to main
        
TRANS:	RETI;  transfers control to main

END


