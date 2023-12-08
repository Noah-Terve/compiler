	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 13, 0
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #16
	.cfi_def_cfa_offset 16
Lloh0:
	adrp	x8, _e@PAGE
	adrp	x9, _d@PAGE
	adrp	x10, _c@PAGE
	adrp	x11, _b@PAGE
Lloh1:
	ldr	w8, [x8, _e@PAGEOFF]
	str	w8, [x9, _d@PAGEOFF]
	str	w8, [x10, _c@PAGEOFF]
	str	w8, [x11, _b@PAGEOFF]
LBB0_1:                                 ; %while
                                        ; =>This Inner Loop Header: Depth=1
	str	w8, [sp, #12]
	mov	w8, w8
	cmp	w8, #5
	b.ge	LBB0_3
; %bb.2:                                ; %while_body
                                        ;   in Loop: Header=BB0_1 Depth=1
	ldr	w8, [sp, #12]
	add	w8, w8, #1
	b	LBB0_1
LBB0_3:                                 ; %merge
	adrp	x8, _z@PAGE
	mov	w9, #5                          ; =0x5
	adrp	x10, _y@PAGE
	adrp	x11, _x@PAGE
	mov	w0, wzr
	str	w9, [x8, _z@PAGEOFF]
	str	w9, [x10, _y@PAGEOFF]
	str	w9, [x11, _x@PAGEOFF]
	add	sp, sp, #16
	ret
	.loh AdrpLdr	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.globl	_b                              ; @b
.zerofill __DATA,__common,_b,4,2
	.globl	_c                              ; @c
.zerofill __DATA,__common,_c,4,2
	.globl	_d                              ; @d
.zerofill __DATA,__common,_d,4,2
	.globl	_e                              ; @e
.zerofill __DATA,__common,_e,4,2
	.globl	_y                              ; @y
.zerofill __DATA,__common,_y,4,2
	.globl	_z                              ; @z
.zerofill __DATA,__common,_z,4,2
	.globl	_x                              ; @x
.zerofill __DATA,__common,_x,4,2
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
