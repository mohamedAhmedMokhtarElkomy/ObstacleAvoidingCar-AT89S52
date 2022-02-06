ORG 0000H; location where execution of the program starts from
LJMP START; LJMP used to bypass the ISR

ORG 0023H; location for ISR for both TI and RI
LJMP SERIALINT

;R4 store received character
;R3 for storing value of TH from ultrasonic echo
ORG 30H
START:

LeftForward EQU P0.3
LeftBackward EQU P0.2
RightForward EQU P0.1
RightBackward EQU P0.0

AutoLED EQU P2.5	;LED indicate if Auto mode is on or not
OnLED EQU P2.7
DetectedPin EQU P2.6	;LED indicate if object detected or not

CLR DetectedPin
CLR OnLED
CLR AutoLED

TRIG EQU P2.3
ECHO EQU P2.4

CLR TRIG		; sets P2.0(TRIG) as output for sending trigger
SETB ECHO		; sets P2.1(ECHO) as input for receiving echo

CLR LeftForward		; sets P1.0(LeftForward) as output
CLR LeftBackward	; sets P1.1(LeftBackward) as output
CLR RightForward	; sets P1.2(RightForward) as output
CLR RightBackward	; sets P1.3(RightBackward) as output

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

;Setup serial port and timer 1 for bluetooth
MOV TMOD, #00100001B	;Mode 2 for timer 1 (8 bit auto reload)
MOV TH1, #0FDH		;setting baud rate 9600
MOV SCON, #01010000B	;Serial Mode 1, REN Enabled
SETB TR1		;Run timer 1

SETB OnLED		;Turn on LED that indicates that power is ON

NormalMode:
	;The following instructions to reset when returning from AutoDriveMode 
	CLR AutoLED
	ACALL StopCar
	MOV IE, #10010000B	;enables interrupt and Stop serial interrupt from auto mode
	
;TODO Make Normal mode work on serial interrupts for let ultrasonic works	
Main:	JB AutoLED, AutoDriveMode	;IF Auto LED turned on from the interrupt so jmp to auto drive mode
	SETB TRIG		; starts the trigger pulse
	ACALL Delay10M     	; Delay 10uS width for the trigger pulse
	CLR TRIG         	; ends the trigger pulse
	
	JNB ECHO,$    		; loops here until echo is received

	ACALL ECHOroutine
	ACALL DelayHalfSec		;TODO i think it is not useful
;SETB TRIG		; starts the trigger pulse
;	ACALL Delay10M     	; Delay 10uS width for the trigger pulse
;	CLR TRIG         	; ends the trigger pulse
	
;	JNB ECHO,$    		; loops here until echo is received

	;ACALL CalcDistance
	SJMP Main	;Jump back to Main for looping
;;;;;;TRY TO OPTIMIZE;;;;;;


;AutoDriveMode is mode for auto move and detect objects
AutoDriveMode:   
	MOV IE, #10010000B	;enables serial interrupt which can be caused by both TI/RI
	SETB AutoLED		;Turn on auto drive LED
	
TrigAgain:
	CLR C
	JNB AutoLED, NormalMode	;IF autoLed pin is 0 JMP to NormalMode
	
	SETB TRIG		; starts the trigger pulse
	ACALL Delay10M     	; Delay 10uS width for the trigger pulse
	CLR TRIG         	; ends the trigger pulse
	
	JNB ECHO,$    		; loops here until echo is received

	ACALL ECHOroutine
	;TODO when transistor be used
	;JB TF0, NoObj	
	;ACALL Detected
	
;	SJMP TrigAgain
	
	ACALL MoveForward	;Default for automode to move forward
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
	SETB RightForward	
	CLR LeftForward
	CLR RightBackward
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
	
;If object detected MoveBack for 1 sec then move right for 2 sec	
Detected:
	SETB DetectedPin
	JNB AutoLED, NormalDET	;If in normal form just give warning
	ACALL MoveBackward
	ACALL DelaySec
	ACALL MOVERight
	ACALL DelaySec
	ACALL DelaySec
	CLR DetectedPin 
	
NormalDET:
	RET
	
;R6 is the input for sub routine
;R7 is used as counter
;R5 as temp register for data poped from stack
;Display LOOP for printing input on LCD Screen
DLOOP:	PUSH 06H
	PUSH 07H
	
	;CLEAR LCD
	MOV A, #01H
	ACALL COMMANDWRT

	MOV A, R6
	MOV R7, #0D	;Counter to store count of numbers
	
;PrintDEC, print => for converting hex value to decimal then print each number	
	PrintDEC:
		INC R7
		MOV B, #10D
		DIV AB			;the quotient is stored in the accumulator and the remainder is stored in the B register
		PUSH B
		CJNE A, #0D, PrintDEC	;Compare the first two operands and branches to the specified destination if their values are not equal
	MOV B, #10D
	MOV R3, A
	DIV AB
	PUSH 03
	INC R7
	
	print:	POP 05H			;POP to 05H which is R5
		MOV A, R5
		ADD A, #'0'		;Add 0 hex value to print number from 0 to 9
		MOV R1, A;TODO REMOVE
		CALL SENDCHAR		;PRINTING A CHARACTER
		DJNZ R7, print		;decrements the byte indicated by the first operand and, if the resulting value is not zero, branches to the address specified in the second operand.
	
	
	POP 07H
	POP 06H	
RET	
		
ECHOroutine:
	;Loop until ECHO pin is low
	;Start counting ticks from 44103D => AC47
	;44103D for maximum distance from 44103D to 65536 equal 4 meters
	;
	MOV TL0, #47H
	MOV TH0, #0ACH

	CLR TF0
	
	SETB TR0	;start timer 0
	
	;TODO LOOP while ECHO 1 and TF0 is 0	
	JB ECHO, $	;While ECHO is while stay here
	CLR TR0
	CLR TF0
	
	;Calculate and print distance
	ACALL CalcDistance
	
	;Check if distance is less that 1 meter or not
	;C135H => over 98cm, C235H => over 101cm
;	MOV A, #0C2H	;
	MOV A, #0B1H	
	CLR C
	SUBB A, TH0
	ANL A, #10000000B	;Check first bit if 1 (-ve) Distance greater than 1 meter if 0 (+ve) Distance less than 1 meter
	CLR DetectedPin
	JNZ NoObj		;If 0 then no object in distance less than 1 meter
	
	;TODO not useful
	;MOV A, #35H
	;CLR C
	;SUBB A, TL0
	;ANL A, #10000000B
	;JNZ NoObj	

	;If else first bit is 1 then object detected in distance less than 1 meter
	ACALL Detected
		
	
	;TODO if transistor is needed
	;CheckECHO:JB ECHO, CheckOF
	;	JMP d
	;CheckOF: JNB TF0, CheckECHO
			;IF else
		;ACALL RestartUS
		
NoObj:	RET

;CalcDistance calculate distance in cm from number of tick by divide ticks / 58D
;Then print the distance
;R3, R2 = R1 R0 / R3 R2
CalcDistance:
	;Prepare R1 for div_16
	CLR C
	MOV A, TH0
	SUBB A, #0ACH	;Subtract ACH from TH0 which was the starting ticks
	MOV R1, A	;R1 used for div_16

	;Prepare R0 for div_16
	CLR C
	MOV A, TL0
	SUBB A, #47H
	MOV R0, A
	
	;Prepare R3 & R2 for div_16
	MOV R3, #0
	MOV R2, #58D
	
	ACALL DIV_16	;R3, R2 = R1 R0 / R3 R2
	MOV A, R2	;Store returned value in
	MOV R6, A	;Move a to R6 that is used in Printing
	
	;Print distance in decimal
	ACALL DLOOP
RET

;TODO if transistor is required
;restart ultrasonic sensor
;RestartUS:
;CLR TR0
;RET

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

DelayHalfSec:
PUSH 07H
    	MOV R7, #10D
    	;Timer Clk = 11.0592/12*1 = 0.9216 MHz
	;50000 uS / (1 / 0.9216)uS = 46080 [65536 - 46080 = 19456 => 4C00H]
	DelayhlfSecLoop:
    		MOV TL0, #00H
    		MOV TH0, #4CH
    		SETB TR0	;Start timer 0
    	
    		JNB TF0, $	;Loop until Timer 0 overflow = 1
    		CLR TR0		;Stop timer 0
    		CLR TF0		;Clear overFlow
    	
    		DJNZ R7, DelayhlfSecLoop ;Decrement A then if A != 0 jump to DelaySecLoop
    	
    	POP 07H
RET
DelaySec:
	PUSH 07H
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
    	
    	POP 07H
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

DELAY10Mreg:
	MOV R6,#2D	;10uS delay
	DJNZ R6, $
        RET  	
DELAY:
    	MOV R0, #10	;DELAY. HIGHER VALUE FOR FASTER CPUS
Y:	MOV R1, #255
	DJNZ R1, $
	DJNZ R0, Y

	RET
	
DELAY1m:
	MOV R7,#250D	;1mS delay
	DJNZ R7, $
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
	
	
SERIALINT:
	JB TI, TRANS; if the interrupt is caused by T1 control is transferred to trans as the old data has been transferred and new data can be sent to the SBUF
	JB AutoLED, AutoModeON
	
	MOV A, SBUF
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
	JZ TurnOnAuto;If A = 'a' then active auto drive
	
		
	MOV A, R4;	
	CLR C		;Clear carry flag befor using SUBB for comparing
	SUBB A, #'s'	;Compare A to 's'
	JZ Jstop	;If A = 's' stop the car


	;;;;;;TRY TO OPTIMIZE;;;;;;
	Jmvfwd:	ACALL MoveForward
	JMP TRANS
	Jmvbwd:ACALL MoveBackward
	JMP TRANS
	Jmvright:ACALL MoveRight
	JMP TRANS
	Jmvleft:ACALL MoveLeft
	JMP TRANS
	Jstop:ACALL StopCar
	JMP TRANS
	TurnOnAuto:SETB AutoLED
	JMP TRANS
	
	
	
	
	
	
	
	
	
	
	
	
		
AutoModeON:
	CLR AutoLED
        CLR RI; clears RI flag
        RETI; transfers control to main
        
TRANS:	RETI;  transfers control to main




END


