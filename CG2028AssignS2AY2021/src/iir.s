 	.syntax unified
 	.cpu cortex-m3
 	.thumb
 	.align 2
 	.global	iir
 	.thumb_func

@ CG2028 Assignment, Sem 2, AY 2020/21
@ (c) CG2028 Teaching Team, ECE NUS, 2021

@Register map
@R0 - N, returns y
@R1 - b
@R2 - a
@R3 - x_n
@R4 - x_store address
@R5 - y_store address
@R6 - x_store tracking pointer
@R7 - y_store tracking pointer
@R8 - a, b values
@R9 - x_store, y_store values
@R10 - N counter
@R11 - y_n


iir:
@ PUSH / save (only those) registers which are modified by your function
@ parameter registers need not be saved.
	PUSH {R4-R11}
@ write asm function body here
	MOV R10, R0

	@ b[0]
	LDR R8, [R1], #4
	@ b[0] * x_n
	MUL R11, R3, R8

	@ load start address to x_store, y_store
	LDR R4, =x_store
	LDR R5, =y_store
	@ load pointer to (n-1)th values of x and y
	LDR R6, [R4]
	@ check if address exists in x_store yet
	CMP R6, #0
	BEQ zero

	@ increment to reference a[1]
	@ divide by a[0] at the end
	ADD R2, #4

	LDR R7, [R5]
	@ update x_store, y_store first byte to their own address
	@ as a flag for the loop
	STR R4, [R4]
	STR R5, [R5]

loop:

	@ load x[n-i] value
	LDR R9, [R6], #-4
	@ check if value loaded is the start address
	CMP R9, R4
	BEQ circle


	@ b[i]
	LDR R8, [R1], #4

	@ y_n += b[i] * x[n-i]
	MLA R11, R8, R9, R11

	@ load y[n-i] value
	LDR R9, [R7], #-4

	@ a[i]
	LDR R8, [R2], #4

	@ y_n -= a[i] * y[n-i]
	MLS R11, R8, R9, R11

	@ decrement counter
	SUB R10, #1
	CMP R10, #0
	BGT loop
	B end

@ load end addresses of x_store, y_store
@ N bytes from start addresses
circle:
	ADD R6, R4, R0, LSL #2
	ADD R7, R5, R0, LSL #2
	@MLA R6, R0, #4, R4
	@MLA R7, R0, #4, R5
	B loop

@ for x_0, y_0 no address yet in x_store, y_store
@ get address
zero:
	MOV R6, R4
	MOV R7, R5
	@ just so that i = 0 is consistent
	ADD R2, R2, R0, LSL #2
	ADD R2, #4

end:
	@ get back start address of a
	SUB R2, R2, R0, LSL #2
	SUB R2, #4
	LDR R8, [R2]

	@ /a[0]
	SDIV R11, R8

	@ store x_n, y_n into x_store, y_store
	STR R3, [R6, #4]!
	STR R11, [R7, #4]!

	@ store pointer to (n-1)th address for next n
	STR R6, [R4]
	STR R7, [R5]

	@ /100
	MOV R10, #100
	@SDIV R11, R10
	MOV R0, R11



@ prepare value to return (y_n) to C program in R0

@ POP / restore original register values. DO NOT save or restore R0. Why?
	POP {R4-R11}
@ return to C program
		BX	LR

@label: .word value
.equ N_MAX, 10
@.lcomm label num_bytes
@ store at most N_MAX integers = 4 * N_MAX bytes
@ the first byte stores a pointer to (n-1)th value
.lcomm x_store, 40
.lcomm y_store, 40
