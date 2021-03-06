############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

############################## Do not .include any files! #############################

.text
eval:
  jr $ra

is_digit:
	li $v0, 0	# Assume character isn't digit initially
	li $t0, 48	# ASCII '0'
	li $t1, 58	# ASCII value 1 above '9'
	digit_loop:
		beq $a0 $t0, yes_digit
		addi $t0, $t0, 1
		bne $t0 $t1, digit_loop
		
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
  jr $ra

op_precedence:
  jr $ra

apply_bop:
  jr $ra
