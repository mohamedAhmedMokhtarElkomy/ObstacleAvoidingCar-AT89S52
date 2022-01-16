MOV R3, #0H
MOV R2, #0H
MOV R1, #53H
MOV R0, #0B9H

MOV R5, #24H
MOV R4, #0H
ACALL UDIV32


;Subroutine UDIV32
;32-Bit / 16-Bit to 32-Bit Quotient & Remainder Unsigned Divide
;input: r3, r2, rl, r0 = Dividend X
;r5, r4 = Divisor Y
;output: r3, r2, rl1, r0 = quotient Q of division Q = X/ Y
;r7, r6, r5, r4 = remainder
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
	RET
END