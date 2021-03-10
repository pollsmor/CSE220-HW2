############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

############################## Do not .include any files! #############################

.text
eval: # (string AExp)
	lw $s0, 0($a1)		# Load AExp
	lbu $s1, 0($s0)		# Load one character from AExp, use $s1 as $t0 would just get overwritten
	li $s2, 0		# Use $s2 as tp argument
	iterateAExp:
		# Check if character is a digit
		addi $sp, $sp, -4	# Save $ra as I will be calling a secondary function
		sw $ra, 0($sp)
		move $a0, $s1		# Make first argument of is_digit the character
		jal is_digit
		lw $ra, 0($sp)		# Restore $ra
		addi $sp, $sp, 4
		bne $v0, $0, digitFound	# is_digit returned 1, jump ahead and add to value stack
		
		j advanceLoop
		
		digitFound:	# Find additional digits (if any), then push to val_stack
			addi $sp, $sp, -4
			sw $ra, 0($sp)
			move $a0, $s0
			jal constructOperand
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			
			# Push val to stack
			addi $sp, $sp, -4
			sw $ra, 0($sp)
			move $a0, $v0
			move $a1, $s2
			la $a2, val_stack
			jal stack_push
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			
			addi $v1, $v1, -1		# Advance AExp by (n - 1), n being length of val
			add $s0, $s0, $v1
			j advanceLoop

		advanceLoop:
			addi $s0, $s0, 1		# Advance AExp forward by 1 character
			lbu $s1, 0($s0)		
			bnez $s1, iterateAExp		# Keep going until null terminator is reached
		
	moveForward:
		jr $ra

constructOperand: # Helper method for eval, takes the AExp as argument
	# First, find length of operand
	addi $sp, $sp, -16
	sw $s0, 0($sp)		# Need to save $a0 before calling findLengthLoop
	sw $s1, 4($sp)		# Need to save length of string before calling findLengthLoop
	sw $s2, 8($sp)		# Need to save current character before calling findLengthLoop
	sw $s3, 12($sp)		# Need to store actual value of all the digits
	
	move $s0, $a0		# ^
	li $s1, 0		# ^
	findLengthLoop:
		addi $s1, $s1, 1	# Increment length
		addi $s0, $s0, 1	# Advance AExp string pointer
		lbu $s2, 0($s0)		# Load next character in AExp
		
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		move $a0, $s2
		jal is_digit
		lw $ra, 0($sp)		# Restore $ra
		addi $sp, $sp, 4
		
		bne $v0, $0, findLengthLoop	# As long as the digits continue being digits, keep going
		
	# By this point in the code, length of string is stored in $s1
	li $s3, 0		# To store actual value of all the digits
	li $t0, 0		# findLengthLoop looped right, now loop left
	li $t1, 10		# Constant 10
	findValueLoop:
		addi $s0, $s0, -1	# Decrement AExp string pointer
		lbu $s2, 0($s0)		# Load next character in AExp (but backwards)
	
		li $t2, 1	# Multiply this however many times by 10 for each digit
		move $t3, $t0	# Don't want to modify the amount of times to apply x10 in this next loop
		exponent10:
			beq $t3, $0, goOnToNextLoop
			mult $t2, $t1
			mflo $t2
			addi $t3, $t3, -1
			bne $t3, $0, exponent10
			
		goOnToNextLoop:
		addi $s2, $s2, -48	# Find actual value of digit
		mult $s2, $t2		# Multiply it by the appropriate power of 10
		mflo $t2		# $t2 doesn't matter now so store result here
		add $s3, $s3, $t2	# Add to total sum
		
		addi $t0, $t0, 1		# Move on to digit left of this one
		bne $t0, $s1, findValueLoop	# Once $t0 reaches the length, stop
	
	move $v0, $s3	# Actual value
	move $v1, $s1	# Length of that value
	lw $s0, 0($sp)	
	lw $s1, 4($sp)		
	lw $s2, 8($sp)		
	lw $s3, 12($sp)	# Deallocate
	addi $sp, $sp, 16
	jr $ra	
	
# ======================================================================================================

is_digit: # (char c)
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

stack_push: # (int x, int tp, int* addr)
	la $t0, op_stack
	bne $t0, $a2, skipOffsetPush	# Check that the base address is op_stack or val_stack
	# op_stack must be > 2000 bytes higher in address to prevent overlapping with val_stack
	addi $a2, $a2, 2000		

	skipOffsetPush:
	li $t0, 2000			# 500 * 4
	bge $a1, $t0, stackTooLarge	# Stack will pass 500 elements, so error out
	add $t0, $a2, $a1		# Add tp ($a1) to base address ($a2) and store in $t0
	sw $a0, 0($t0)

	addi $v0, $a1, 4		# Size of element is 4, so return top + 4
	jr $ra
	stackTooLarge:
		j badTokenError

# Basically a carbon copy of stack_pop's body
stack_peek: # (int tp, int* addr)
	blt $a0, $0, emptyStackError 
	la $t0, op_stack
	bne $t0, $a1, skipOffsetPeek	# Check that the base address is op_stack or val_stack
	# op_stack must be > 2000 bytes higher in address to prevent overlapping with val_stack
	addi $a1, $a1, 2000	
	
	skipOffsetPeek:
	add $t0, $a1, $a0		
	lw $v0, 0($t0)
	jr $ra	

stack_pop: # (int tp, int* addr)
	blt $a0, $0, emptyStackError	# $tp cannot be < 0 (i.e. caller provides -4)
	la $t0, op_stack
	bne $t0, $a1, skipOffsetPop	# Check that the base address is op_stack or val_stack
	# op_stack must be > 2000 bytes higher in address to prevent overlapping with val_stack
	addi $a1, $a1, 2000	
	
	skipOffsetPop:
	add $t0, $a1, $a0		# Add tp to base address
	lw $v1, 0($t0)			# $v0 stays the same, return popped element in $v1
	jr $ra
	emptyStackError:
		j badTokenError

is_stack_empty: # (int tp)
	blt $a0, $0, emptyStack
	li $v0, 0
	jr $ra
	emptyStack:
		li $v0, 1
		jr $ra

valid_ops: # (char c)
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

op_precedence: # (char c)
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

apply_bop: # (int v1, char op, int v2)
	li $t0, '+'
	beq $a1, $t0, addition		
	li $t0, '-'
	beq $a1, $t0, subtraction	
	li $t0, '*'
	beq $a1, $t0, multiplication	
	
	# Last valid operation is division
	beq $a2, $0, dividebyzero	# Can't divide by 0
	bgez $a2, skip_sign_swap	# The way I handle floor division requires the second operand to be (+)
	li $t0, -1			# Swap signs of first arg to (+), balance it by swapping second arg
	mult $a0, $t0
	mflo $a0
	mult $a2, $t0
	mflo $a2
	
	skip_sign_swap:
		div $a0, $a2
		mflo $v0			# Get quotient
		mfhi $t0			# Get remainder - for cases like -1/2 where you want -1, not 0
		bgez $t0, return_division
		addi $v0, $v0, -1		# For the aforementioned cases like -1/2, -5/3, etc.
	return_division:
		j return_bop_result
	
	addition:
		add $v0, $a0, $a2
		j return_bop_result
	subtraction:
		li $t0, -1		# Flip sign to add a negative number
		mult $a2, $t0
		mflo $a2
		add $v0, $a0, $a2
		j return_bop_result
	multiplication:
		mult $a0, $a2
		mflo $v0
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
	
badTokenError:
	li $v0, 4
	la $a0, BadToken
	syscall
		
	li $v0, 10
	syscall
