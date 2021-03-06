############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

############################## Do not .include any files! #############################

.text
eval: # (string AExp)
	# Preamble
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	sw $s7, 32($sp)

	lw $s0, 0($a1)		# Load AExp
	lbu $s1, 0($s0)		# Load one character from AExp, use $s1 as $t0 would just get overwritten
	li $s2, 0		# Use $s2 as tp argument for val_stack
	li $s3, 0		# Use $s3 as tp argument for op_stack
	la $s4, op_stack	# Use $s4 as op_stack address so I don't have to keep offsetting by 2000
	addi $s4, $s4, 2000

	iterateAExp:
	# Check if character is a digit
	move $a0, $s1		# Make first argument of is_digit the character
	jal is_digit
	bne $v0, $0, digitFound

	# Check if character is a (valid) operator
	move $a0, $s1	
	jal valid_ops
	bne $v0, $0, operatorFound
	
	# Check if character is left parentheses
	li $t0, '('
	beq $s1, $t0, leftParensFound
	
	# Check if character is right parentheses
	li $t0, ')'
	beq $s1, $t0, rightParensFound
	
	j badTokenError 		# Character is invalid
	
	digitFound:	# Find additional digits (if any), then push to val_stack
		li $v1, 1		# Length of string is 1 unless constructOperand condition runs
	
		# Quick optimization: don't call constructOperand if I know this is the only digit.
		lbu $a0, 1($s0)
		jal is_digit
		move $t0, $v0
		move $v0, $s1		# Use $v0 to conform with use of constructOperand
		addi $v0, $v0, -48	# Get numerical value of ASCII character
		beq $t0, $0, operandLength1
	
		move $a0, $s0			# constructOperand takes AExp
		jal constructOperand
		addi $v1, $v1, -1		# Advance AExp by (n - 1), n being length of returned val
		add $s0, $s0, $v1
		
		operandLength1:
		addi $t0, $s0, 1		# Check next element is not a left parens
		lbu $t1, 0($t0)
		li $t2, '('
		beq $t1, $t2, parseError
		
		# Push val to stack
		move $a0, $v0
		move $a1, $s2			# $s2 contains tp of val_stack
		la $a2, val_stack
		jal stack_push
		move $s2, $v0			# Update tp of val_stack
		
		j advanceLoop

	operatorFound: 
		addi $a0, $s3, -4		# Pass tp - 4 to is_stack_empty
		jal is_stack_empty
		bne $v0, $0, pushOp		# If op_stack is empty, simply push to it					
		loopThroughOpStack:		# Otherwise...		
			move $a0, $s1
			jal op_precedence
			move $s5, $v0		# $s5 now contains precedence of current character
		
			addi $a0, $s3, -4	# Peek at op_stack
			move $a1, $s4		# Address of op_stack + 2000
			jal stack_peek
			
			# If left parens is on stack, just push operand to val_stack as well
			li $t0, '('
			beq $v0, $t0, pushOp	
			
			move $a0, $v0		# $v0 contains the peeked operator from op_stack
			jal op_precedence
			move $s6, $v0		# $s6 now contains precedence of the operator on stack		
																				
			blt $s6, $s5, pushOp	# Operator stack's operator is less precedence, skip ahead
			# Step 4: "pop op, pop twice from val, apply bop, push result to val"
			move $a0, $s2
			move $a1, $s3
			move $a2, $s4		# $s4 contains op_stack offset-ed address
			jal calculateAndPushResultToStack
			move $s2, $v0		# Update tp of val and op_stack via return values
			move $s3, $v1
						
			addi $a0, $s3, -4			# Pass tp - 4 to is_stack_empty
			jal is_stack_empty		
			beq $v0, $0, loopThroughOpStack		# Stack is not empty yet
		
		pushOp:
		# Push operator onto stack
		move $a0, $s1			# Reminder that $s1 contains current character
		move $a1, $s3			# $s3 contains tp of op_stack
		move $a2, $s4
		jal stack_push
		move $s3, $v0			# Update tp after push
		
		j advanceLoop

	leftParensFound:
		# Check case of ()
		li $t0, ')'
		lbu $t1, 1($s0)
		beq $t0, $t1, parseError
	
		move $a0, $s1
		move $a1, $s3			# $s3 contains tp of op_stack
		move $a2, $s4
		jal stack_push
		move $s3, $v0			# Update tp of op_stack
	
		j advanceLoop

	rightParensFound:	
		# Pop second operand	
		addi $s2, $s2, -4	
		move $a0, $s2
		la $a1, val_stack
		jal stack_pop		
		move $s7, $v1		
			
		# Pop operator
		addi $s3, $s3, -4
		move $a0, $s3
		move $a1, $s4
		jal stack_pop
		move $s5, $v1		# Move operator into $s5
			
		# Check if popped operator is left parens, skip ahead if so
		li $t0, '('
		bne $s5, $t0, performBinop
		# Is left parens, so push operand... 
		move $a0, $s7
		move $a1, $s2
		la $a2, val_stack
		jal stack_push
		move $s2, $v0			# Update tp of val_stack
		j advanceLoop
			
		performBinop:
		# Pop first operand	
		addi $s2, $s2, -4	
		move $a0, $s2
		la $a1, val_stack
		jal stack_pop		
		move $s6, $v1		

		# Apply bop
		move $a0, $s6
		move $a1, $s5
		move $a2, $s7
		jal apply_bop
			
		# Push newly calculated value to val_stack
		move $a0, $v0		
		move $a1, $s2
		la $a2, val_stack
		jal stack_push
		move $s2, $v0		
			
		j rightParensFound	# Don't need a condition - must leave via the beq above.

	advanceLoop:
		addi $s0, $s0, 1		# Advance AExp forward by 1 character
		lbu $s1, 0($s0)			
		bnez $s1, iterateAExp		# Keep going until null terminator is reached
		
	finalCalculations: # By this point, I can merely pop and re-push result onto stack for the answer.
	# Check if operator stack is empty
	addi $a0, $s3, -4
	jal is_stack_empty		
	bne $v0, $0, returnResult
	
	move $a0, $s2
	move $a1, $s3
	move $a2, $s4				# $s4 contains op_stack offset-ed address
	jal calculateAndPushResultToStack
	move $s2, $v0				# Update tp of val and op_stack via return values
	move $s3, $v1
			
	# If stack is not empty, go back once more		
	addi $a0, $s3, -4			# Pass tp - 4 to is_stack_empty
	jal is_stack_empty	
	beq $v0, $0, finalCalculations		# Stack is not empty yet

	# =====================================================================================

	# Pop the final calculated result in val_stack.
	returnResult:		
	addi $s2, $s2, -4
	move $a0, $s2
	la $a1, val_stack
	jal stack_pop
	move $s0, $v1		# $s0 now contains calculated result.
	
	# However, if there are more in val_stack, must be ill-formed expression.
	addi $a0, $s2, -4		
	jal is_stack_empty
	beq $v0, $0, parseError
	
	move $a0, $s0
	li $v0, 1
	syscall
	# Restore $ra and $s registers
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)	
	lw $s7, 32($sp)
	addi $sp, $sp, 36
	jr $ra

calculateAndPushResultToStack:
	addi $sp, $sp, -28
	sw $ra, 0($sp)
	sw $s0, 4($sp)	# Store tp of val_stack
	sw $s1, 8($sp)  # Store tp of op_stack
	sw $s2, 12($sp)	# Store operator
	sw $s3, 16($sp) # Store operand 1
	sw $s4, 20($sp) # Store operand 2
	sw $s5, 24($sp)	# Store offset-ed address of op_stack
	move $s0, $a0
	move $s1, $a1
	move $s5, $a2

	# Pop operator		
	addi $s1, $s1, -4	# Actually modify tp of op_stack, unlike peek
	move $a0, $s1
	move $a1, $s5
	jal stack_pop		# If expression is ill-formed, this is where it should error out.
	move $s2, $v1		# $s2 now contains popped operator

	# Pop second operand
	addi $s0, $s0, -4	# Actually modify tp of val_stack, unlike peek
	move $a0, $s0
	la $a1, val_stack
	jal stack_pop		# If expression is ill-formed, this is where it should error out.
	move $s4, $v1		# $s4 now contains popped operand 2
		
	# Pop first operand	
	addi $s0, $s0, -4	# Actually modify tp of val_stack, unlike peek
	move $a0, $s0
	la $a1, val_stack
	jal stack_pop		# If expression is ill-formed, this is where it should error out.
	move $s3, $v1		# $s3 now contains popped operand 1
		
	# Apply bop
	move $a0, $s3
	move $a1, $s2
	move $a2, $s4
	jal apply_bop
	
	# Push newly calculated value to val_stack
	move $a0, $v0		# $v0 contains calculated value from apply_bop
	move $a1, $s0
	la $a2, val_stack
	jal stack_push
	move $s0, $v0		# Update tp of val_stack
	
	move $v0, $s0	# Return the new tps
	move $v1, $s1
	lw $ra, 0($sp)
	lw $s0, 4($sp)	
	lw $s1, 8($sp)  
	lw $s2, 12($sp)	
	lw $s3, 16($sp)
	lw $s4, 20($sp) 
	lw $s5, 24($sp)
	addi $sp, $sp, 28
	jr $ra

constructOperand: # Helper method for eval, takes the AExp as argument
	# First, find length of operand
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)		# Save AExp
	sw $s1, 8($sp)		# Save length of string
	
	move $s0, $a0		# ^
	li $s1, 0		# ^
	findLengthLoop:
		addi $s1, $s1, 1	# Increment length
		addi $s0, $s0, 1	# Advance AExp string pointer
		lbu $a0, 0($s0)		# Load next character in AExp
		jal is_digit
		bne $v0, $0, findLengthLoop	# As long as the digits continue being digits, keep going
		
	# By this point in the code, length of string is stored in $s1
	li $t0, 0		# findLengthLoop looped right, now loop left
	li $t1, 10		# Constant 10
	li $t2, 1		# Multiply this however many times by 10 for each digit
	li $t3, 0		# To store actual value of all the digits
	findValueLoop:
		addi $s0, $s0, -1	# Decrement AExp string pointer
		lbu $t4, 0($s0)		# Load next character in AExp (but backwards)
		addi $t4, $t4, -48	# Find actual value of digit
		mult $t4, $t2		# Multiply it by the appropriate power of 10
		mflo $t4		
		add $t3, $t3, $t4	# Add to total sum
		
		addi $t0, $t0, 1		# Move on to digit left of this one
		mult $t2, $t1			# Multiply $t2 by 10
		mflo $t2
		bne $t0, $s1, findValueLoop	# Once $t0 reaches the length, stop
	
	move $v0, $t3	# Actual value
	move $v1, $s1	# Length of that value	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
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
	
	add $t0, $a1, $a0		
	lw $v0, 0($t0)
	jr $ra	

stack_pop: # (int tp, int* addr)
	blt $a0, $0, emptyStackError	# $tp cannot be < 0 (i.e. caller provides -4)
	
	skipOffsetPop:
	add $t0, $a1, $a0		# Add tp to base address
	lw $v1, 0($t0)			# $v0 stays the same, return popped element in $v1
	jr $ra
	emptyStackError:
		j parseError

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
	beq $v0, $0, invalid_op

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
	# Swap signs of first arg to (+), balance it by swapping second arg
	sub $a0, $0, $a0
	sub $a2, $0, $a2
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
		sub $v0, $a0, $a2
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

parseError:
	li $v0, 4
	la $a0, ParseError
	syscall
	
	li $v0, 10
	syscall
