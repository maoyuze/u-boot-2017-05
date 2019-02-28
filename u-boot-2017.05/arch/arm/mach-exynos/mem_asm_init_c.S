
mem_ctrl_asm_init:
	ldr	r0, =0x110002C0
	ldr	r1, [r0, #0x04]
	lsr	r1, r1, #5
	cmp	r1, #5
	beq	mem_ctrl_asm_init_r1
	cmp	r1, #1
	beq	mem_ctrl_asm_init_r1
	cmp	r1, #2
	beq	mem_ctrl_asm_init_r2
	b	mem_ctrl_asm_init_r0
