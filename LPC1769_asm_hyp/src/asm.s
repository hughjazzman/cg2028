/*
 * LPC1769_asm_basic : asm.s
 * CK Tham, ECE, NUS
 * June 2011
 *
 * Simple assembly language program to compute
 * ANSWER = floor(sqrt(A*A+B*B))
 */

@ Directives
		.thumb                  @ (same as saying '.code 16')
	 	.cpu cortex-m3
		.syntax unified
	 	.align 2

@ Equates
        .equ STACKINIT,   0x10008000

@ Vectors
vectors:
        .word STACKINIT         @ stack pointer value when stack is empty
        .word _start + 1        @ reset vector (manually adjust to odd for thumb)
        .word _nmi_handler + 1  @
        .word _hard_fault  + 1  @
        .word _memory_fault + 1 @
        .word _bus_fault + 1    @
        .word _usage_fault + 1  @
	    .word 0            		@ checksum

		.global _start

@ Start of executable code
.section .text

_start:

@ code starts
@ Calculate ANSWER = ceiling(sqrt(A*A+B*B))
	LDR R0, A @ PC-relative load
	MUL R1, R0, R0 @ R1 = A*A
	LDR R2, B @ R2 = B
	MLA R3, R2, R2, R1 @ R3 = A*A+B*B
	/*
	CMP R0, R2 @ B > A
	ITE GE		@ load higher number into R4
	MOVGE R4, R0 @ R4 = B
	MOVLT R4, R2 @ R4 = A
	B hyp
	*/
	LDR R4, C @ R4 = 0

@ Use R4 to search for answer
hyp:
	MUL R5, R4, R4 @ Get square
	CMP R3, R5 @ Compare with A*A+B*B
	BLE end @ end if R4*R4 >= A*A+B*B
	ADD R4, #1
	B hyp

end:
	LDR R6, =ANSWER
	STR R4, [R6]




@ Loop at the end to allow inspection of registers and memory
loop:
	b loop

@ Loop if any exception gets triggered
_exception:
_nmi_handler:
_hard_fault:
_memory_fault:
_bus_fault:
_usage_fault:
        b _exception

@ Define constant values
A:
	.word 3
B:
	.word 4
C:
	.word 0
D:
	.word 400
@ Store result in SRAM (4 bytes)
	.lcomm	ANSWER	4
	.end
