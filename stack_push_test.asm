.data
Newline: .asciiz "\n"
WrongArgMsg: .asciiz "You must provide exactly one argument"
BadToken: .asciiz "Unrecognized Token"
ParseError: .asciiz "Ill Formed Expression"
ApplyOpError: .asciiz "Operator could not be applied"

val_stack : .word 0
op_stack : .word 0

.text
.globl main
main:
	li $a0, 69000
	li $a1, 0
	la $a2, val_stack
	jal stack_push
	
	move $a0, $v0
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, Newline
	syscall
	
	la $s0, val_stack
	lw $s1, 0($s0)
	move $a0, $s1
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, Newline
	syscall
	# ====================================
	li $a0, 1337
	li $a1, 1996
	la $a2, val_stack
	jal stack_push
	
	move $a0, $v0
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, Newline
	syscall
	
	la $s0, val_stack
	lw $s1, 1996($s0)
	move $a0, $s1
	li $v0, 1
	syscall
end:
  # Terminates the program
  li $v0, 10
  syscall

.include "hw2-funcs.asm"
