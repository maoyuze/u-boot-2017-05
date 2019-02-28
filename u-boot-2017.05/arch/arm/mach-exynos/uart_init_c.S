/*
 * (C) Copyright 2011 Samsung Electronics Co. Ltd
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */


#include "tiny4412_val.h"
#define CONFIG_FASTBOOT

#define BOOT_ONENAND        0x1
#define BOOT_NAND       0x40000
#define BOOT_MMCSD      0x3
#define BOOT_NOR        0x4
#define BOOT_SEC_DEV        0x5
#define BOOT_EMMC       0x6
#define BOOT_EMMC_4_4       0x7

#define UFCON_OFFSET 0x8

#define ULCON_OFFSET            0x00
#define UCON_OFFSET         0x04
#define UFCON_OFFSET            0x08
#define UMCON_OFFSET            0x0C
#define UTRSTAT_OFFSET          0x10
#define UERSTAT_OFFSET          0x14
#define UFSTAT_OFFSET           0x18
#define UMSTAT_OFFSET           0x1C
#define UTXH_OFFSET         0x20
#define URXH_OFFSET         0x24
#define UBRDIV_OFFSET           0x28
#define UDIVSLOT_OFFSET         0x2C
#define UINTP_OFFSET            0x30
#define UINTSP_OFFSET           0x34
#define UINTM_OFFSET            0x38
//#define UTRSTAT_TX_EMPTY      BIT2
//#define UTRSTAT_RX_READY      BIT0
#define UART_ERR_MASK           0xF

#define S5PV310_UART_CONSOLE_BASE 0x13800000

#define S5PV310_CLOCK_BASE 0x10030000
#define  CONFIG_LL_DEBUG 1












@	bl	tzpc_init

@	b	load_uboot





	.globl uart_asm_init
uart_asm_init:

	/* set GPIO to enable UART */
	@ GPIO setting for UART for UART0/1/2/3
	ldr	r0, =0x11400000
	ldr	r1, =0x22222222
	str	r1, [r0]
	ldr	r0, =0x11400020
	ldr	r1, =0x222222
	str	r1, [r0]

	ldr	r0, =S5PV310_CLOCK_BASE
	ldr	r1, =CLK_SRC_PERIL0_VAL
	ldr	r2, =CLK_SRC_PERIL0_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =CLK_DIV_PERIL0_VAL
	ldr	r2, =CLK_DIV_PERIL0_OFFSET
	str	r1, [r0, r2]

	ldr	r0, =S5PV310_UART_CONSOLE_BASE
	ldr	r1, =0x111
	str	r1, [r0, #UFCON_OFFSET]

	mov	r1, #0x3
	str	r1, [r0, #ULCON_OFFSET]

	ldr	r1, =0x3c5
	str	r1, [r0, #UCON_OFFSET]

	ldr	r1, =UART_UBRDIV_VAL
	str	r1, [r0, #UBRDIV_OFFSET]

	ldr	r1, =UART_UDIVSLOT_VAL
	str	r1, [r0, #UDIVSLOT_OFFSET]

	@ldr	r1, =0x4f4f4f4f
	@str	r1, [r0, #UTXH_OFFSET]		@'O'

	@ldr	r1, =0x5b5b5b5b
	@str	r1, [r0, #UTXH_OFFSET]		@'K'

	mov	pc, lr





#if CONFIG_LL_DEBUG
	.globl uart_asm_putc
uart_asm_putc:
	push	{r9}

	ldr	r9, =S5PV310_UART_CONSOLE_BASE
	str	r0, [r9, #UTXH_OFFSET]
	ldr	r9, =0x20000				@delay

.Luartputc:
	sub	r9, r9, #1
	cmp	r9, #0
	bne	.Luartputc

	pop	{r9}
	mov	pc, lr

	.globl uart_asm_putx
uart_asm_putx:
	stmfd sp!, {r3, r4, r5, lr}

	mov	r5, r0
	mov	r4, #28

.Luartputx:
	mov	r0, r5, asr r4
	and	r0, r0, #15
	cmp	r0, #9
	addle	r0, r0, #48
	addgt	r0, r0, #55
	bl	uart_asm_putc
	sub	r4, r4, #4
	cmn	r4, #4
	bne	.Luartputx

	ldmfd sp!, {r3, r4, r5, pc}

#endif /* CONFIG_LL_DEBUG */


#ifdef CONFIG_ENABLE_MMU
enable_mmu:
	/* enable domain access */
	ldr	r5, =0x0000ffff
	mcr	p15, 0, r5, c3, c0, 0		@load domain access register

	/* Set the TTB register */
	ldr	r0, =mmu_table
	ldr	r1, =CONFIG_PHY_UBOOT_BASE
	ldr	r2, =0xfff00000
	bic	r0, r0, r2
	orr	r1, r0, r1
	mcr	p15, 0, r1, c2, c0, 0

	/* Enable the MMU */
mmu_on:
	mrc	p15, 0, r0, c1, c0, 0
	orr	r0, r0, #1
	mcr	p15, 0, r0, c1, c0, 0
	nop
	nop
	nop
	nop
	mov	pc, lr

/*
 * we assume that cache operation is done before. (eg. cleanup_before_linux())
 * actually, we don't need to do anything about cache if not use d-cache in U-Boot
 * So, in this function we clean only MMU. by scsuh
 *
 * void	theLastJump(void *kernel, int arch_num, uint boot_params);
 */
	.globl theLastJump
theLastJump:
	mov	r9, r0
	ldr	r3, =0xfff00000
	ldr	r4, =CONFIG_PHY_UBOOT_BASE
	adr	r5, phy_last_jump
	bic	r5, r5, r3
	orr	r5, r5, r4
	mov	pc, r5

phy_last_jump:
	/*
	 * disable MMU stuff
	 */
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, r0, #0x00002300	/* clear bits 13, 9:8 (--V- --RS) */
	bic	r0, r0, #0x00000087	/* clear bits 7, 2:0 (B--- -CAM) */
	orr	r0, r0, #0x00000002	/* set bit 2 (A) Align */
	orr	r0, r0, #0x00001000	/* set bit 12 (I) I-Cache */
	mcr	p15, 0, r0, c1, c0, 0

	mcr	p15, 0, r0, c8, c7, 0	/* flush v4 TLB */

	mov	r0, #0
	mov	pc, r9

/*
 * MMU Table for SMDKC210
 * 0x0000_0000 -- 0x1FFF_FFFF => A:0x0000_0000 -- 0x1FFF_FFFF
 * 0x2000_0000 -- 0x3FFF_FFFF => Not Allowed
 * 0x4000_0000 -- 0x5FFF_FFFF => A:0x4000_0000 -- 0x5FFF_FFFF
 * 0x6000_0000 -- 0xBFFF_FFFF => Not Allowed
 * 0xC000_0000 -- 0xDFFF_FFFF => A:0x4000_0000 -- 0X5FFF_FFFF
 * 0xE000_0000 -- 0xFFFF_FFFF => Not Allowed
 */

	/* form a first-level section entry */
.macro FL_SECTION_ENTRY base,ap,d,c,b
	.word (\base << 20) | (\ap << 10) | \
	      (\d << 5) | (1<<4) | (\c << 3) | (\b << 2) | (1<<1)
.endm

.section .mmudata, "a"
	.align 14

	// the following alignment creates the mmu table at address 0x4000.
	.globl mmu_table
mmu_table:

	.set __base,0
	// Access for iRAM
	.rept 0x200
	FL_SECTION_ENTRY __base,3,0,0,0
	.set __base,__base+1
	.endr

	// Not Allowed
	.rept 0x400 - 0x200
	.word 0x00000000
	.endr

	.set __base,0x400
	// 512MB for SDRAM with cacheable
	.rept 0x800 - 0x400
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base,__base+1
	.endr

	// access is not allowed.
	.rept 0xc00 - 0x800
	.word 0x00000000
	.endr

	.set __base,0x400
	// 512MB for SDRAM with cacheable
	.rept 0xE00 - 0xC00
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base,__base+1
	.endr

	// access is not allowed.
	.rept 0x1000 - 0xE00
	.word 0x00000000
	.endr

#endif /* CONFIG_ENABLE_MMU */

