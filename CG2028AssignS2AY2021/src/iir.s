 	.syntax unified
 	.cpu cortex-m3
 	.thumb
 	.align 2
 	.global	iir
 	.thumb_func

@ CG2028 Assignment, Sem 2, AY 2020/21
@ (c) CG2028 Teaching Team, ECE NUS, 2021

@ Wira Azmoon Ahmad, A0149286R
@ R Ramana, A0197788X

@Register map
@R0 - N, returns y
@R1 - b
@R2 - a
@R3 - x_n
@R4 - x_store addresses, n_calls address
@R5 - y_store addresses
@R6 - a, b values
@R7 - x_store, y_store values
@R8 - N counter
@R9 - y_n
@R10 - no. of call, pointer to x_(n-1), N_MAX


iir:
@ PUSH / save (only those) registers which are modified by your function
@ parameter registers need not be saved.
	PUSH {R4-R10}
@ write asm function body here

@ Memory
@ X, op, X, P, U, X, W, L, Rn, Rd, X, imm8
@ 4, 2 , 1, 1, 1, 1, 1, 1,  4,  4, 4, 8
@ op = 01
@ PW = 0b00 -> Post index, 0b10 -> offset, 0b11 -> pre index
@ U = positive/negative offset 0b1/0b0
@ L = load/store 0b1/0b0
@ DP (Mul)
@ X, op, I, cmd, S, Rn, Rd, Rs, X, M, Rm
@ 4, 2 , 1,	  4, 1,  4,  4,  4, 3, 1,  4
@ op = 00
@ I = 0
@ cmd = 0000 -> MUL, 0001 -> MLA
@ S = set flag

	@ b[0]
	LDR R6, [R1], #4 @ Memory: 0b0000,0100,1001,0001,0110,0000,0000,0100 = 0x04916004
	@ b[0] * x_n
	MUL R9, R3, R6 @ DP: 0b0000,0000,0000,0000,1001,0110,0001,0011 = 0x00009613

	@ load current no. of call n
	LDR R4, =n_calls
	LDR R10, [R4]
	@ if N is greater than number of previous calls
	@ update N so loop doesn't get invalid values
	@ CMP: cmd=1010,S=1
	CMP R0, R10 @ DP: 0b0000,0001,0101,0000,0000,0000,0000,1010 = 0x0150000A
	IT GT
	MOVGT R0, R10
	@ MOV: cmd=1101,S=0
	MOV R8, R0 @ DP: 0b0000,0001,1010,0000,1000,0000,0000,0000 = 0x01A08000

	@ increment the no. of calls
	@ I=1,cmd=0100,S=0
	ADD R10, #1 @ DP: 0b0000,0010,1000,1010,1010,0000,0000,0001 = 0x028AA001
	STR R10, [R4]

	@ load start address to x_store, y_store
	LDR R4, =x_store
	LDR R5, =y_store

	@ load pointer to &x_(n-1)
	LDR R4, [R4]

	@ check if address exists in x_store yet
	@ I=1,cmd=1010,S=1
	CMP R4, #0 @ DP: 0b0000,0011,0101,0100,0000,0000,0000,0000 = 0x03540000
	@ op=10,U=1, 21 instructions after PC+4
	BEQ zero @ Branch: 0b0000,1000,1000,0000,0000,0000,0101,0100 = 0x08800054

	@ &x_(n-1) to compare later
	MOV R10, R4 @ DP: 0b0000,0001,1010,0000,1010,0000,0000,0100 = 0x01A0A004

	@ load &y_(n-1)
	LDR R5, [R5]

	@ if no need to enter loop
	CMP R8, #0 @ DP: 0b0000,0011,0101,1000,0000,0000,0000,0000 = 0x03580000
	@ 22 instructions after PC+4
	BEQ end @ Branch: 0b0000,1000,1000,0000,0000,0000,0101,1000 = 0x08800058

loop:

	@ load x[n-i] value
	@ op=01,PW=00,U=0,L=1
	LDR R7, [R4], #-4 @ Memory: 0b0000,0100,0001,0100,0111,0000,0000,0100 = 0x04147004
	@ check if value loaded is &x_n-1 -> need to circle back to end of array
	@ I=0,cmd=1010,S=1
	CMP R7, R10 @ DP: 0b0000,0001,0101,0111,0000,0000,0000,1010 = 0x0157000A
	@ 9 instructions from PC+4
	BEQ circle @ Branch: 0b0000,1000,1000,0000,0000,0000,0010,0100 = 0x08800024

	@ b[i]
	LDR R6, [R1], #4 @ Memory: 0b0000,0100,1001,0001,0110,0000,0000,0100 = 0x04916004

	@ y_n += b[i] * x[n-i]
	@ op=00,I=0,cmd=0001,S=0
	MLA R9, R6, R7, R9 @ DP: 0b0000,0000,0010,1001,1001,0111,0001,0110 = 0x00299716

	@ load y[n-i] value
	@ op=01,PW=00,U=0,L=1
	LDR R7, [R5], #-4 @ Memory: 0b0000,0100,0001,0101,0111,0000,0000,0100 = 0x04157004

	@ a[i]
	@ op=01,PW=11,U=1,L=1
	LDR R6, [R2, #4]! @ Memory: 0b0000,0101,1011,0010,0110,0000,0000,0100 = 0x05B26004

	@ y_n -= a[i] * y[n-i]
	MLS R9, R6, R7, R9

	@ decrement counter, check if need to enter loop
	@ op=00,I=1,cmd=0010,S=1
	SUBS R8, #1 @ DP: 0b0000,0010,0101,1000,1000,0000,0000,0001 = 0x02588001
	@ 10 instructions from PC+4
	BGT loop @ Branch: 0b1100,1000,0000,0000,0000,0000,0010,1000 = 0xC8000028
	@ get back start address of a
	SUB R2, R2, R0, LSL #2
	@ 10 instructions from PC+4
	B end @ Branch: 0b1110,1000,1000,0000,0000,0000,0010,1000 = 0xE8800028

@ load end addresses of x_store, y_store
@ N_MAX bytes from start addresses
circle:
	@ op=00,I=1,cmd=1101,S=0
	MOV R10, #N_MAX @ DP: 0b0000,0011,1010,0000,1010,0000,0000,1010 = 0x03A0A00A
	LDR R4, =x_store
	LDR R5, =y_store
	ADD R4, R4, R10, LSL #2
	ADD R5, R5, R10, LSL #2
	@ 18 instructions from PC+4
	B loop @ Branch: 0b1110,1000,0000,0000,0000,0000,0100,1000 = 0xE8000048

@ for x_0, y_0 no address yet in x_store, y_store
@ get address into x_store for consistency
zero:
	LDR R4, =x_store
	LDR R5, =y_store
	STR R4, [R4]
	STR R5, [R5]

end:
	@ load a[0]
	LDR R6, [R2]

	@ /a[0]
	SDIV R9, R6

	@ get next address to overwrite
	LDR R4, =x_store
	LDR R5, =y_store
	LDR R4, [R4]
	LDR R5, [R5]

	@ check if at end of array
	MOV R10, #N_MAX @ DP: 0b0000,0011,1010,0000,1010,0000,0000,1010 = 0x03A0A00A
	@ R6 used as temp register, no longer used for a value
	LDR R6, =y_store
	ADD R6, R6, R10, LSL #2
	@ I=0,cmd=1010,S=1
	CMP R6, R5 @ DP: 0b0000,0001,0101,0110,0000,0000,0000,0101 = 0x01560005

	@ 2 instructions from PC+4
	BNE store @ Branch: 0b0001,1000,1000,0000,0000,0000,0000,1000 = 0x18800008
	LDR R4, =x_store
	LDR R5, =y_store
store:

	@ store x_n, y_n into x_store, y_store
	@ op=01,PW=11,U=1,L=0
	STR R3, [R4, #4]! @ Memory: 0b0000,0101,1010,0100,0011,0000,0000,0100 = 0x05A43004
	STR R9, [R5, #4]! @ Memory: 0b0000,0101,1010,0101,1001,0000,0000,0100 = 0x05A59004

	@ store pointer to (n-1)th address for next n
	LDR R6, =x_store
	STR R4, [R6]
	LDR R6, =y_store
	STR R5, [R6]

	@ /100
	MOV R8, #100 @ DP: 0b0000,0011,1010,0000,1000,0000,0110,0100 = 0x03A08064
	SDIV R9, R8
	MOV R0, R9 @ DP: 0b0000,0001,1010,0000,0000,0000,0000,1001 = 0x01A00009



@ prepare value to return (y_n) to C program in R0

@ POP / restore original register values. DO NOT save or restore R0. Why?
	POP {R4-R10}
@ return to C program
		BX	LR

@label: .word value
.equ N_MAX, 10
@.lcomm label num_bytes
@ store at most N_MAX integers = 4 * N_MAX bytes
@ the first byte stores a pointer to (n-1)th value
.lcomm x_store, (N_MAX+1)*4
.lcomm y_store, (N_MAX+1)*4
.lcomm n_calls, 4
