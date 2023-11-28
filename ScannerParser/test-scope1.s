	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 14, 0
	.globl	_main                           ## -- Begin function main
	.p2align	4, 0x90
_main:                                  ## @main
	.cfi_startproc
## %bb.0:                               ## %entry
	pushq	%rax
	.cfi_def_cfa_offset 16
	movl	$3, %edi
	callq	_checkScope
	xorl	%eax, %eax
	popq	%rcx
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	_checkScope                     ## -- Begin function checkScope
	.p2align	4, 0x90
_checkScope:                            ## @checkScope
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%edi, -4(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.section	__TEXT,__cstring,cstring_literals
L_fmt:                                  ## @fmt
	.asciz	"%d\n"

L_fmt.1:                                ## @fmt.1
	.asciz	"%g\n"

L_fmt.2:                                ## @fmt.2
	.asciz	"%s\n"

L_fmt.3:                                ## @fmt.3
	.asciz	"%c\n"

L_fmt.4:                                ## @fmt.4
	.asciz	"%d\n"

L_fmt.5:                                ## @fmt.5
	.asciz	"%g\n"

L_fmt.6:                                ## @fmt.6
	.asciz	"%s\n"

L_fmt.7:                                ## @fmt.7
	.asciz	"%c\n"

.subsections_via_symbols
