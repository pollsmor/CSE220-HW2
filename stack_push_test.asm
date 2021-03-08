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
	li $a0, 69000		# value to be pushed
	li $a1, 0		# tp
	la $a2, val_stack	# Base address of stack
	jal stack_push
	
	# Print new tp
	move $a0, $v0
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, Newline
	syscall
	
	# Print value at top of stack
	la $s0, val_stack
	lw $a0, 0($s0)
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, Newline
	syscall
	# ====================================
	li $a0, 1337
	li $a1, 4
	la $a2, val_stack
	jal stack_push
	
	move $a0, $v0
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, Newline
	syscall
	
	lw $a0, 4($s0)
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, Newline
	syscall
	# ====================================
	li $a0, 4	# Top element is from offset 4 to 7 (8 - 4)
	la $a1, val_stack
	jal stack_pop
	
	move $a0, $v1
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, Newline
	syscall
	# ====================================
	li $a0, 0	# Top element is from offset 09 to 3 (4 - 4)
	la $a1, val_stack
	jal stack_pop
	
	move $a0, $v1
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, Newline
	syscall
	# ====================================
	li $a0, -4	# Should error out. (0 - 4)
	la $a1, val_stack
	jal stack_pop
	
	move $a0, $v1
	li $v0, 1
	syscall
	
end:
  # Terminates the program
  li $v0, 10
  syscall

.include "hw2-funcs.asm"
