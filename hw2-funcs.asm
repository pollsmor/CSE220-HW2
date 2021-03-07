############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

############################## Do not .include any files! #############################

.text
eval:
  jr $ra

is_digit:
	li $v0, 0	# Assume character isn't digit initially
	li $t0, '0'
	li $t1, 58	# ASCII value 1 above '9'
	digit_loop:
		beq $a0, $t0, yes_digit
		addi $t0, $t0, 1
		bne $t0, $t1, digit_loop
		
	no_digit:	# If loop passes without yes_digit being called, char must not be a digit.
		li $v0, 0
		jr $ra
	yes_digit:
		li $v0, 1
  		jr $ra

stack_push:
  jr $ra

stack_peek:
  jr $ra

stack_pop:
  jr $ra

is_stack_empty:
  jr $ra

valid_ops:
	li $v0, 0	# Assume character is invalid initially
	
	li $t0, '+'
	beq $a0, $t0, isValid
	li $t0, '-'
	beq $a0, $t0, isValid
	li $t0, '*'
	beq $a0, $t0, isValid
	li $t0, '/'
	beq $a0, $t0, isValid
	jr $ra		# Invalid operator, simply return with 0
	
	isValid:
		li $v0, 1
		jr $ra

op_precedence:
	addi $sp, $sp, -4	# Save $ra as I will be calling a secondary function
	sw $ra, 0($sp)
	
	jal valid_ops		# $a0 is already the correct argument for valid_ops
	li $t0, 1		# Valid operator return value is 1
	bne $v0, $t0, invalid_op

	li $t0, '*'
	beq $a0, $t0, precedence_2
	li $t0, '/'
	beq $a0, $t0, precedence_2
	li $v0, 1		# Is '+' or '-' so precedence is lower (1)
	j return_op_precedence
	
	precedence_2:
		li $v0, 2
		j return_op_precedence

	invalid_op:
		j applyoperror_msg
		
	return_op_precedence:
		lw $ra, 0($sp)		# Restore $ra
		addi $sp, $sp, 4
		jr $ra

apply_bop:
	li $t0, '+'
	beq $v1, $t0, addition		
	li $t0, '-'
	beq $v1, $t0, subtraction	
	li $t0, '*'
	beq $v1, $t0, multiplication	
	
	# Last valid operation is division
	beq $a2, $0, dividebyzero	# Can't divide by 0
	bgez $a2, skip_sign_swap	# The way I handle floor division requires the first arg to be (+)
	li $t0, -1			# Swap signs of first arg to (+), balance it by swapping second arg
	mult $a0, $t0
	mflo $a0
	mult $a2, $t0
	mflo $a2
	skip_sign_swap:
		div $a0, $a2
	
	mflo $v0			# Get quotient
	mfhi $t0			# Get remainder - for cases like -1/2 where you want -1, not 0
	bgez $t0, return_apply_bop
	addi $v0, $v0, -1		# For the aforementioned case like -1/2
	
	return_apply_bop:
		j return_bop_result
	
	addition:
		j return_bop_result
	subtraction:
		j return_bop_result
	multiplication:
		j return_bop_result
	
	return_bop_result:
		jr $ra
	dividebyzero:
		j applyoperror_msg
	
applyoperror_msg:
	li $v0, 4
	la $a0, ApplyOpError
	syscall
	
	li $v0, 10
	syscall