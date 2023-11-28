	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 14, 0
	.section	__TEXT,__literal8,8byte_literals
	.p2align	3                               ## -- Begin function main
LCPI0_0:
	.quad	0x401fa3d70a3d70a4              ## double 7.9100000000000001
LCPI0_1:
	.quad	0x3ff3ae147ae147ae              ## double 1.23
LCPI0_2:
	.quad	0x40091eb851eb851f              ## double 3.1400000000000001
LCPI0_3:
	.quad	0x3ff3333333333333              ## double 1.2
LCPI0_4:
	.quad	0x401b1eb851eb851f              ## double 6.7800000000000002
LCPI0_5:
	.quad	0x405edd2f1a9fbe77              ## double 123.456
LCPI0_6:
	.quad	0x3ff0000000000000              ## double 1
LCPI0_7:
	.quad	0x40c0156f5c28f5c3              ## double 8234.8700000000008
LCPI0_8:
	.quad	0x407c8bae147ae148              ## double 456.73000000000002
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_main
	.p2align	4, 0x90
_main:                                  ## @main
	.cfi_startproc
## %bb.0:                               ## %entry
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movl	$5, %edi
	movl	$4, %esi
	callq	__test.int.int
	leaq	L_fmt(%rip), %rbx
	movq	%rbx, %rdi
	movl	%eax, %esi
	xorl	%eax, %eax
	callq	_printf
	movl	$4, %edi
	movl	$5, %esi
	callq	__test.int.int
	movq	%rbx, %rdi
	movl	%eax, %esi
	xorl	%eax, %eax
	callq	_printf
	movl	$3, %edi
	movl	$6, %esi
	callq	__test.int.int
	movq	%rbx, %rdi
	movl	%eax, %esi
	xorl	%eax, %eax
	callq	_printf
	movl	$2, %edi
	movl	$7, %esi
	callq	__test.int.int
	movq	%rbx, %rdi
	movl	%eax, %esi
	xorl	%eax, %eax
	callq	_printf
	movl	$5, %edi
	movl	$1, %esi
	callq	__test.int.bool
	movq	%rbx, %rdi
	movl	%eax, %esi
	xorl	%eax, %eax
	callq	_printf
	movl	$3, %edi
	movl	$97, %esi
	callq	__test.int.char
	movq	%rbx, %rdi
	movl	%eax, %esi
	xorl	%eax, %eax
	callq	_printf
	movsd	LCPI0_0(%rip), %xmm0            ## xmm0 = mem[0],zero
	movl	$2, %edi
	callq	__test.int.float
	movq	%rbx, %rdi
	movl	%eax, %esi
	xorl	%eax, %eax
	callq	_printf
	leaq	L_string(%rip), %rsi
	movl	$8, %edi
	callq	__test.int.string
	movq	%rbx, %rdi
	movl	%eax, %esi
	xorl	%eax, %eax
	callq	_printf
	movl	$1, %edi
	movl	$4, %esi
	callq	__test.bool.int
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	movl	$1, %edi
	xorl	%esi, %esi
	callq	__test.bool.bool
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	movl	$1, %edi
	movl	$97, %esi
	callq	__test.bool.char
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	movsd	LCPI0_1(%rip), %xmm0            ## xmm0 = mem[0],zero
	xorl	%edi, %edi
	callq	__test.bool.float
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	leaq	L_string.4(%rip), %rsi
	xorl	%edi, %edi
	callq	__test.bool.string
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	movl	$97, %edi
	movl	$4, %esi
	callq	__test.char.int
	movzbl	%al, %esi
	leaq	L_fmt.3(%rip), %rbx
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	movl	$119, %edi
	movl	$1, %esi
	callq	__test.char.bool
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	movl	$97, %edi
	movl	$98, %esi
	callq	__test.char.char
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	movsd	LCPI0_2(%rip), %xmm0            ## xmm0 = mem[0],zero
	movl	$113, %edi
	callq	__test.char.float
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	leaq	L_string.5(%rip), %rsi
	movl	$98, %edi
	callq	__test.char.string
	movzbl	%al, %esi
	movq	%rbx, %rdi
	xorl	%eax, %eax
	callq	_printf
	movsd	LCPI0_3(%rip), %xmm0            ## xmm0 = mem[0],zero
	movl	$4, %edi
	callq	__test.float.int
	leaq	L_fmt.1(%rip), %rbx
	movq	%rbx, %rdi
	movb	$1, %al
	callq	_printf
	movsd	LCPI0_4(%rip), %xmm0            ## xmm0 = mem[0],zero
	movl	$1, %edi
	callq	__test.float.bool
	movq	%rbx, %rdi
	movb	$1, %al
	callq	_printf
	movsd	LCPI0_5(%rip), %xmm0            ## xmm0 = mem[0],zero
	movl	$121, %edi
	callq	__test.float.char
	movq	%rbx, %rdi
	movb	$1, %al
	callq	_printf
	movsd	LCPI0_6(%rip), %xmm0            ## xmm0 = mem[0],zero
	movaps	%xmm0, %xmm1
	callq	__test.float.float
	movq	%rbx, %rdi
	movb	$1, %al
	callq	_printf
	leaq	L_string.6(%rip), %rdi
	movsd	LCPI0_7(%rip), %xmm0            ## xmm0 = mem[0],zero
	callq	__test.float.string
	movq	%rbx, %rdi
	movb	$1, %al
	callq	_printf
	leaq	L_string.7(%rip), %rdi
	movl	$2, %esi
	callq	__test.string.int
	leaq	L_fmt.2(%rip), %rbx
	movq	%rbx, %rdi
	movq	%rax, %rsi
	xorl	%eax, %eax
	callq	_printf
	leaq	L_string.8(%rip), %rdi
	xorl	%esi, %esi
	callq	__test.string.bool
	movq	%rbx, %rdi
	movq	%rax, %rsi
	xorl	%eax, %eax
	callq	_printf
	leaq	L_string.9(%rip), %rdi
	movl	$33, %esi
	callq	__test.string.char
	movq	%rbx, %rdi
	movq	%rax, %rsi
	xorl	%eax, %eax
	callq	_printf
	leaq	L_string.10(%rip), %rdi
	movsd	LCPI0_8(%rip), %xmm0            ## xmm0 = mem[0],zero
	callq	__test.string.float
	movq	%rbx, %rdi
	movq	%rax, %rsi
	xorl	%eax, %eax
	callq	_printf
	leaq	L_string.11(%rip), %rdi
	leaq	L_string.12(%rip), %rsi
	callq	__test.string.string
	movq	%rbx, %rdi
	movq	%rax, %rsi
	xorl	%eax, %eax
	callq	_printf
	xorl	%eax, %eax
	popq	%rbx
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.int.int                  ## -- Begin function _test.int.int
	.p2align	4, 0x90
__test.int.int:                         ## @_test.int.int
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%edi, -4(%rsp)
	movl	%esi, -8(%rsp)
	movl	%edi, -12(%rsp)
	movl	%esi, -16(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.int.bool                 ## -- Begin function _test.int.bool
	.p2align	4, 0x90
__test.int.bool:                        ## @_test.int.bool
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%edi, -4(%rsp)
	andb	$1, %sil
	movb	%sil, -9(%rsp)
	movl	%edi, -8(%rsp)
	movb	%sil, -10(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.int.char                 ## -- Begin function _test.int.char
	.p2align	4, 0x90
__test.int.char:                        ## @_test.int.char
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%edi, -4(%rsp)
	movb	%sil, -9(%rsp)
	movl	%edi, -8(%rsp)
	movb	%sil, -10(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.int.float                ## -- Begin function _test.int.float
	.p2align	4, 0x90
__test.int.float:                       ## @_test.int.float
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%edi, -20(%rsp)
	movsd	%xmm0, -8(%rsp)
	movl	%edi, -24(%rsp)
	movsd	%xmm0, -16(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.int.string               ## -- Begin function _test.int.string
	.p2align	4, 0x90
__test.int.string:                      ## @_test.int.string
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%edi, -20(%rsp)
	movq	%rsi, -8(%rsp)
	movl	%edi, -24(%rsp)
	movq	%rsi, -16(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.bool.int                 ## -- Begin function _test.bool.int
	.p2align	4, 0x90
__test.bool.int:                        ## @_test.bool.int
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%eax, %ecx
	andb	$1, %cl
	movb	%cl, -9(%rsp)
	movl	%esi, -4(%rsp)
	movb	%cl, -10(%rsp)
	movl	%esi, -8(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.bool.bool                ## -- Begin function _test.bool.bool
	.p2align	4, 0x90
__test.bool.bool:                       ## @_test.bool.bool
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%eax, %ecx
	andb	$1, %cl
	movb	%cl, -1(%rsp)
	andb	$1, %sil
	movb	%sil, -2(%rsp)
	movb	%cl, -3(%rsp)
	movb	%sil, -4(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.bool.char                ## -- Begin function _test.bool.char
	.p2align	4, 0x90
__test.bool.char:                       ## @_test.bool.char
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%eax, %ecx
	andb	$1, %cl
	movb	%cl, -1(%rsp)
	movb	%sil, -2(%rsp)
	movb	%cl, -3(%rsp)
	movb	%sil, -4(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.bool.float               ## -- Begin function _test.bool.float
	.p2align	4, 0x90
__test.bool.float:                      ## @_test.bool.float
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%eax, %ecx
	andb	$1, %cl
	movb	%cl, -17(%rsp)
	movsd	%xmm0, -8(%rsp)
	movb	%cl, -18(%rsp)
	movsd	%xmm0, -16(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.bool.string              ## -- Begin function _test.bool.string
	.p2align	4, 0x90
__test.bool.string:                     ## @_test.bool.string
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movl	%eax, %ecx
	andb	$1, %cl
	movb	%cl, -17(%rsp)
	movq	%rsi, -8(%rsp)
	movb	%cl, -18(%rsp)
	movq	%rsi, -16(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.char.int                 ## -- Begin function _test.char.int
	.p2align	4, 0x90
__test.char.int:                        ## @_test.char.int
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movb	%al, -9(%rsp)
	movl	%esi, -4(%rsp)
	movb	%al, -10(%rsp)
	movl	%esi, -8(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.char.bool                ## -- Begin function _test.char.bool
	.p2align	4, 0x90
__test.char.bool:                       ## @_test.char.bool
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movb	%al, -1(%rsp)
	andb	$1, %sil
	movb	%sil, -2(%rsp)
	movb	%al, -3(%rsp)
	movb	%sil, -4(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.char.char                ## -- Begin function _test.char.char
	.p2align	4, 0x90
__test.char.char:                       ## @_test.char.char
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movb	%al, -1(%rsp)
	movb	%sil, -2(%rsp)
	movb	%al, -3(%rsp)
	movb	%sil, -4(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.char.float               ## -- Begin function _test.char.float
	.p2align	4, 0x90
__test.char.float:                      ## @_test.char.float
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movb	%al, -17(%rsp)
	movsd	%xmm0, -8(%rsp)
	movb	%al, -18(%rsp)
	movsd	%xmm0, -16(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.char.string              ## -- Begin function _test.char.string
	.p2align	4, 0x90
__test.char.string:                     ## @_test.char.string
	.cfi_startproc
## %bb.0:                               ## %entry
	movl	%edi, %eax
	movb	%al, -17(%rsp)
	movq	%rsi, -8(%rsp)
	movb	%al, -18(%rsp)
	movq	%rsi, -16(%rsp)
                                        ## kill: def $al killed $al killed $eax
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.float.int                ## -- Begin function _test.float.int
	.p2align	4, 0x90
__test.float.int:                       ## @_test.float.int
	.cfi_startproc
## %bb.0:                               ## %entry
	movsd	%xmm0, -8(%rsp)
	movl	%edi, -20(%rsp)
	movsd	%xmm0, -16(%rsp)
	movl	%edi, -24(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.float.bool               ## -- Begin function _test.float.bool
	.p2align	4, 0x90
__test.float.bool:                      ## @_test.float.bool
	.cfi_startproc
## %bb.0:                               ## %entry
	movsd	%xmm0, -8(%rsp)
	andb	$1, %dil
	movb	%dil, -17(%rsp)
	movsd	%xmm0, -16(%rsp)
	movb	%dil, -18(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.float.char               ## -- Begin function _test.float.char
	.p2align	4, 0x90
__test.float.char:                      ## @_test.float.char
	.cfi_startproc
## %bb.0:                               ## %entry
	movsd	%xmm0, -8(%rsp)
	movb	%dil, -17(%rsp)
	movsd	%xmm0, -16(%rsp)
	movb	%dil, -18(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.float.float              ## -- Begin function _test.float.float
	.p2align	4, 0x90
__test.float.float:                     ## @_test.float.float
	.cfi_startproc
## %bb.0:                               ## %entry
	movsd	%xmm0, -8(%rsp)
	movsd	%xmm1, -16(%rsp)
	movsd	%xmm0, -24(%rsp)
	movsd	%xmm1, -32(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.float.string             ## -- Begin function _test.float.string
	.p2align	4, 0x90
__test.float.string:                    ## @_test.float.string
	.cfi_startproc
## %bb.0:                               ## %entry
	movsd	%xmm0, -8(%rsp)
	movq	%rdi, -16(%rsp)
	movsd	%xmm0, -24(%rsp)
	movq	%rdi, -32(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.string.int               ## -- Begin function _test.string.int
	.p2align	4, 0x90
__test.string.int:                      ## @_test.string.int
	.cfi_startproc
## %bb.0:                               ## %entry
	movq	%rdi, %rax
	movq	%rdi, -8(%rsp)
	movl	%esi, -20(%rsp)
	movq	%rdi, -16(%rsp)
	movl	%esi, -24(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.string.bool              ## -- Begin function _test.string.bool
	.p2align	4, 0x90
__test.string.bool:                     ## @_test.string.bool
	.cfi_startproc
## %bb.0:                               ## %entry
	movq	%rdi, %rax
	movq	%rdi, -8(%rsp)
	andb	$1, %sil
	movb	%sil, -17(%rsp)
	movq	%rdi, -16(%rsp)
	movb	%sil, -18(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.string.char              ## -- Begin function _test.string.char
	.p2align	4, 0x90
__test.string.char:                     ## @_test.string.char
	.cfi_startproc
## %bb.0:                               ## %entry
	movq	%rdi, %rax
	movq	%rdi, -8(%rsp)
	movb	%sil, -17(%rsp)
	movq	%rdi, -16(%rsp)
	movb	%sil, -18(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.string.float             ## -- Begin function _test.string.float
	.p2align	4, 0x90
__test.string.float:                    ## @_test.string.float
	.cfi_startproc
## %bb.0:                               ## %entry
	movq	%rdi, %rax
	movq	%rdi, -8(%rsp)
	movsd	%xmm0, -16(%rsp)
	movq	%rdi, -24(%rsp)
	movsd	%xmm0, -32(%rsp)
	retq
	.cfi_endproc
                                        ## -- End function
	.globl	__test.string.string            ## -- Begin function _test.string.string
	.p2align	4, 0x90
__test.string.string:                   ## @_test.string.string
	.cfi_startproc
## %bb.0:                               ## %entry
	movq	%rdi, %rax
	movq	%rdi, -8(%rsp)
	movq	%rsi, -16(%rsp)
	movq	%rdi, -24(%rsp)
	movq	%rsi, -32(%rsp)
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

L_string:                               ## @string
	.asciz	"not"

L_string.4:                             ## @string.4
	.asciz	"false"

L_string.5:                             ## @string.5
	.asciz	"bee"

L_string.6:                             ## @string.6
	.asciz	"maybe yes"

L_string.7:                             ## @string.7
	.asciz	"hello"

L_string.8:                             ## @string.8
	.asciz	"hello"

L_string.9:                             ## @string.9
	.asciz	"world"

L_string.10:                            ## @string.10
	.asciz	"alive"

L_string.11:                            ## @string.11
	.asciz	"work"

L_string.12:                            ## @string.12
	.asciz	"please"

L_fmt.13:                               ## @fmt.13
	.asciz	"%d\n"

L_fmt.14:                               ## @fmt.14
	.asciz	"%g\n"

L_fmt.15:                               ## @fmt.15
	.asciz	"%s\n"

L_fmt.16:                               ## @fmt.16
	.asciz	"%c\n"

L_fmt.17:                               ## @fmt.17
	.asciz	"%d\n"

L_fmt.18:                               ## @fmt.18
	.asciz	"%g\n"

L_fmt.19:                               ## @fmt.19
	.asciz	"%s\n"

L_fmt.20:                               ## @fmt.20
	.asciz	"%c\n"

L_fmt.21:                               ## @fmt.21
	.asciz	"%d\n"

L_fmt.22:                               ## @fmt.22
	.asciz	"%g\n"

L_fmt.23:                               ## @fmt.23
	.asciz	"%s\n"

L_fmt.24:                               ## @fmt.24
	.asciz	"%c\n"

L_fmt.25:                               ## @fmt.25
	.asciz	"%d\n"

L_fmt.26:                               ## @fmt.26
	.asciz	"%g\n"

L_fmt.27:                               ## @fmt.27
	.asciz	"%s\n"

L_fmt.28:                               ## @fmt.28
	.asciz	"%c\n"

L_fmt.29:                               ## @fmt.29
	.asciz	"%d\n"

L_fmt.30:                               ## @fmt.30
	.asciz	"%g\n"

L_fmt.31:                               ## @fmt.31
	.asciz	"%s\n"

L_fmt.32:                               ## @fmt.32
	.asciz	"%c\n"

L_fmt.33:                               ## @fmt.33
	.asciz	"%d\n"

L_fmt.34:                               ## @fmt.34
	.asciz	"%g\n"

L_fmt.35:                               ## @fmt.35
	.asciz	"%s\n"

L_fmt.36:                               ## @fmt.36
	.asciz	"%c\n"

L_fmt.37:                               ## @fmt.37
	.asciz	"%d\n"

L_fmt.38:                               ## @fmt.38
	.asciz	"%g\n"

L_fmt.39:                               ## @fmt.39
	.asciz	"%s\n"

L_fmt.40:                               ## @fmt.40
	.asciz	"%c\n"

L_fmt.41:                               ## @fmt.41
	.asciz	"%d\n"

L_fmt.42:                               ## @fmt.42
	.asciz	"%g\n"

L_fmt.43:                               ## @fmt.43
	.asciz	"%s\n"

L_fmt.44:                               ## @fmt.44
	.asciz	"%c\n"

L_fmt.45:                               ## @fmt.45
	.asciz	"%d\n"

L_fmt.46:                               ## @fmt.46
	.asciz	"%g\n"

L_fmt.47:                               ## @fmt.47
	.asciz	"%s\n"

L_fmt.48:                               ## @fmt.48
	.asciz	"%c\n"

L_fmt.49:                               ## @fmt.49
	.asciz	"%d\n"

L_fmt.50:                               ## @fmt.50
	.asciz	"%g\n"

L_fmt.51:                               ## @fmt.51
	.asciz	"%s\n"

L_fmt.52:                               ## @fmt.52
	.asciz	"%c\n"

L_fmt.53:                               ## @fmt.53
	.asciz	"%d\n"

L_fmt.54:                               ## @fmt.54
	.asciz	"%g\n"

L_fmt.55:                               ## @fmt.55
	.asciz	"%s\n"

L_fmt.56:                               ## @fmt.56
	.asciz	"%c\n"

L_fmt.57:                               ## @fmt.57
	.asciz	"%d\n"

L_fmt.58:                               ## @fmt.58
	.asciz	"%g\n"

L_fmt.59:                               ## @fmt.59
	.asciz	"%s\n"

L_fmt.60:                               ## @fmt.60
	.asciz	"%c\n"

L_fmt.61:                               ## @fmt.61
	.asciz	"%d\n"

L_fmt.62:                               ## @fmt.62
	.asciz	"%g\n"

L_fmt.63:                               ## @fmt.63
	.asciz	"%s\n"

L_fmt.64:                               ## @fmt.64
	.asciz	"%c\n"

L_fmt.65:                               ## @fmt.65
	.asciz	"%d\n"

L_fmt.66:                               ## @fmt.66
	.asciz	"%g\n"

L_fmt.67:                               ## @fmt.67
	.asciz	"%s\n"

L_fmt.68:                               ## @fmt.68
	.asciz	"%c\n"

L_fmt.69:                               ## @fmt.69
	.asciz	"%d\n"

L_fmt.70:                               ## @fmt.70
	.asciz	"%g\n"

L_fmt.71:                               ## @fmt.71
	.asciz	"%s\n"

L_fmt.72:                               ## @fmt.72
	.asciz	"%c\n"

L_fmt.73:                               ## @fmt.73
	.asciz	"%d\n"

L_fmt.74:                               ## @fmt.74
	.asciz	"%g\n"

L_fmt.75:                               ## @fmt.75
	.asciz	"%s\n"

L_fmt.76:                               ## @fmt.76
	.asciz	"%c\n"

L_fmt.77:                               ## @fmt.77
	.asciz	"%d\n"

L_fmt.78:                               ## @fmt.78
	.asciz	"%g\n"

L_fmt.79:                               ## @fmt.79
	.asciz	"%s\n"

L_fmt.80:                               ## @fmt.80
	.asciz	"%c\n"

L_fmt.81:                               ## @fmt.81
	.asciz	"%d\n"

L_fmt.82:                               ## @fmt.82
	.asciz	"%g\n"

L_fmt.83:                               ## @fmt.83
	.asciz	"%s\n"

L_fmt.84:                               ## @fmt.84
	.asciz	"%c\n"

L_fmt.85:                               ## @fmt.85
	.asciz	"%d\n"

L_fmt.86:                               ## @fmt.86
	.asciz	"%g\n"

L_fmt.87:                               ## @fmt.87
	.asciz	"%s\n"

L_fmt.88:                               ## @fmt.88
	.asciz	"%c\n"

L_fmt.89:                               ## @fmt.89
	.asciz	"%d\n"

L_fmt.90:                               ## @fmt.90
	.asciz	"%g\n"

L_fmt.91:                               ## @fmt.91
	.asciz	"%s\n"

L_fmt.92:                               ## @fmt.92
	.asciz	"%c\n"

L_fmt.93:                               ## @fmt.93
	.asciz	"%d\n"

L_fmt.94:                               ## @fmt.94
	.asciz	"%g\n"

L_fmt.95:                               ## @fmt.95
	.asciz	"%s\n"

L_fmt.96:                               ## @fmt.96
	.asciz	"%c\n"

L_fmt.97:                               ## @fmt.97
	.asciz	"%d\n"

L_fmt.98:                               ## @fmt.98
	.asciz	"%g\n"

L_fmt.99:                               ## @fmt.99
	.asciz	"%s\n"

L_fmt.100:                              ## @fmt.100
	.asciz	"%c\n"

L_fmt.101:                              ## @fmt.101
	.asciz	"%d\n"

L_fmt.102:                              ## @fmt.102
	.asciz	"%g\n"

L_fmt.103:                              ## @fmt.103
	.asciz	"%s\n"

L_fmt.104:                              ## @fmt.104
	.asciz	"%c\n"

L_fmt.105:                              ## @fmt.105
	.asciz	"%d\n"

L_fmt.106:                              ## @fmt.106
	.asciz	"%g\n"

L_fmt.107:                              ## @fmt.107
	.asciz	"%s\n"

L_fmt.108:                              ## @fmt.108
	.asciz	"%c\n"

L_fmt.109:                              ## @fmt.109
	.asciz	"%d\n"

L_fmt.110:                              ## @fmt.110
	.asciz	"%g\n"

L_fmt.111:                              ## @fmt.111
	.asciz	"%s\n"

L_fmt.112:                              ## @fmt.112
	.asciz	"%c\n"

.subsections_via_symbols
