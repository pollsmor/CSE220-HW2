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
	li $a0, 4		# value to be pushed
	li $a1, 0		# tp
	la $a2, val_stack	# Base address of stack
	jal stack_push
	
	li $a0, 3		# value to be pushed
	li $a1, 4		# tp
	la $a2, val_stack	# Base address of stack
	jal stack_push
	
	li $a0, '+'		# value to be pushed
	li $a1, 0		# tp
	la $a2, op_stack	# Base address of stack
	jal stack_push
	
	# Print new tp for op_stack
	move $a0, $v0
	li $v0, 1
	syscall
	jal print_newline
	
	# Print value at top of val_stack
	li $a0, 4		# 1-4 is the second element
	la $a1, val_stack
	jal stack_peek
	move $a0, $v0
	li $v0, 1
	syscall
	jal print_newline
	
	# Print value at top of op_stack
	li $a0, 0		# 0-3 is the third element
	la $a1, op_stack
	jal stack_peek
	move $a0, $v0
	li $v0, 1
	syscall
	jal print_newline
	
	# Check if stack is empty (hint: no)
	li $a0, 8
	jal is_stack_empty
	move $a0, $v0
	li $v0, 1
	syscall
	jal print_newline

	# Pop the single element in op_stack
	li $a0, 0	# Element at 0-3
	la $a1, op_stack
	jal stack_pop
	move $a0, $v1
	li $v0, 1
	syscall
	jal print_newline

	# Check if stack is empty (hint: yes)
	li $a0, -4
	jal is_stack_empty
	move $a0, $v0
	li $v0, 1
	syscall
	jal print_newline

	# Try popping an empty stack	
	li $a0, -4	# Should error out. (0 - 4)
	la $a1, val_stack
	jal stack_pop
	move $a0, $v1 	# Code from this point on doesn't even run
	li $v0, 1
	syscall

print_newline:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $v0, 4
	la $a0, Newline
	syscall
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
			
end:
  # Terminates the program
  li $v0, 10
  syscall

.include "hw2-funcs.asm"
