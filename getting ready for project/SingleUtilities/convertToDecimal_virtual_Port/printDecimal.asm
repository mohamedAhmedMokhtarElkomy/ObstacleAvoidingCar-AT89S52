ORG 0

MOV TMOD, #20H	; or 00100000B => Mode 2 for Timer1 (8bit Auto Reload)
MOV TH1, #0FDH	;Setting BaudRate of 9600 (-3). SMOD is 0 by default
MOV SCON, #50H	;Serial Mode 1, REN Enabled or 01010000B
SETB TR1

MOV A, #250D
MOV R7, #0D
PrintDEC:
	INC R7
	MOV B, #10D
	DIV AB ;the quotient is stored in the accumulator and the remainder is stored in the B register
	PUSH B
	CJNE A, #0D, PrintDEC ;the first two operands and branches to the specified destination if their values are not equal
	
print:	POP 06H	;POP to 06H which is R6
	MOV A, R6
	ADD A, #'0'
	MOV SBUF, A
	JNB TI, $
	CLR TI
	ACALL DELAY
	DJNZ R7, print	;decrements the byte indicated by the first operand and, if the resulting value is not zero, branches to the address specified in the second operand.
	JMP close
	
RET

DELAY:
    	MOV R0, #255 ;DELAY. HIGHER VALUE FOR FASTER CPUS
Y:	MOV R1, #255
	DJNZ R1, $
	DJNZ R0, Y
RET
close:
	END