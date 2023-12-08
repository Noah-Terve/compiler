	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 13, 0
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #16
	.cfi_def_cfa_offset 16
	adrp	x8, _b@PAGE
	mov	w9, #2                          ; =0x2
	str	w9, [x8, _b@PAGEOFF]
	str	w9, [sp, #12]
LBB0_1:                                 ; %while
                                        ; =>This Inner Loop Header: Depth=1
	ldr	w8, [sp, #12]
	cmp	w8, #5
	b.ge	LBB0_3
; %bb.2:                                ; %while_body
                                        ;   in Loop: Header=BB0_1 Depth=1
	ldr	w8, [sp, #12]
	add	w8, w8, #1
	str	w8, [sp, #12]
	b	LBB0_1
LBB0_3:                                 ; %merge
	mov	w0, wzr
	add	sp, sp, #16
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	_b                              ; @b
.zerofill __DATA,__common,_b,4,2
	.section	__TEXT,__cstring,cstring_literals
l_fmt:                                  ; @fmt
	.asciz	"%d"

l_fmt.1:                                ; @fmt.1
	.asciz	"%g"

l_fmt.2:                                ; @fmt.2
	.asciz	"%s"

l_fmt.3:                                ; @fmt.3
	.asciz	"%c"

.subsections_via_symbols
