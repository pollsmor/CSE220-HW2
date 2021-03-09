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
	li $a0, 0		# 0-3 is the first element
	la $a1, val_stack
	jal stack_peek
	move $a0, $v0
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, Newline
	syscall
	# Push operators onto another stack, verify stacks do not overlap
	li $a0, '+'		# value to be pushed
	li $a1, 0		# tp
	la $a2, op_stack	# Base address of stack
	jal stack_push
	
	li $a0, '-'		# value to be pushed
	li $a1, 4		# tp
	la $a2, op_stack	# Base address of stack
	jal stack_push
	
	li $a0, '*'		# value to be pushed
	li $a1, 8		# tp
	la $a2, op_stack	# Base address of stack
	jal stack_push
	
	li $a0, 0		# Should contain 69000 instead of '+'
	la $a1, val_stack
	jal stack_peek
	move $a0, $v0
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, Newline
	syscall
	
	li $a0, 0		# Should contain '+' instead of 69000
	la $a1, op_stack
	jal stack_peek
	move $a0, $v0
	li $v0, 11
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
	
	li $a0, 4		# 4-7 is the second element
	la $a1, val_stack
	jal stack_peek
	move $a0, $v0
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, Newline
	syscall
	# ====================================
	# Check if stack is empty (hint: no)
	li $a0, 8
	jal is_stack_empty
	move $a0, $v0
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
	# Check if stack is empty (hint: yes)
	li $a0, -4
	jal is_stack_empty
	move $a0, $v0
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
