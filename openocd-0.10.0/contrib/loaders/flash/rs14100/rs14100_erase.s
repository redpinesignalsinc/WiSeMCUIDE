/********************************************************************/

	.text
	.syntax unified
	.arch armv7-m
	.cpu cortex-m4
	.thumb
	.thumb_func
/*
 * Params :
 * r0 - first
 * r1 - last
 *
 * Clobbered:
 * r6 - temp
 */
/*
 * This code is embedded within: src/flash/nor/rs14100.c as a "C" array.
 *
 * To rebuild:
 *   arm-none-eabi-gcc -c rs14100_erase.s
 *   arm-none-eabi-objcopy -O binary rs14100_erase.o rs14100_erase.bin
 *   xxd -c 8 -i rs14100_erase.bin > rs14100_erase.txt
 *
 * Then read and edit this result into the "C" source.
 */

set_manual:
	mov.w	r4, #0x0000	 		/* store QSPI base addr in R4 */
	movt	r4, #0x1200	
	mov.w	r6, #0x0C00	 		/* Disable automode and select manual mode (clear 6th bit) */
	movt	r6, #0x0001
	str.w	r6, [r4, #0x04]
	bl	wait_auto_mode_disable
	mov.w	r6, #0x0001			/* Set bus mode to single */
	movt	r6, #0x0208
	str.w	r6, [r4, #0x10]
	mov.w	r6, #0x0C00	 		
	movt	r6, #0x0001 			
	str.w	r6, [r4, #0x04]
	mov.w	r7, #0x2000
	movt	r7, #0x0001
write_enable:
	mov.w 	r6, #8 
	str.w	r6, [r4, #0x80]		
	mov.w 	r6, #0x6	
	str.w	r6, [r4, #0x40]	
	mov.w	r6, #0x0002			
	movt	r6, #0x0208	
	str.w	r6, [r4, #0x10]
	bl	wait_flash_busy
	mov.w	r6, #0x0001			/* DEASSERT_CSN    */
	movt	r6, #0x0208
	str.w	r6, [r4, #0x10]
sector_erase_command:
	mov.w 	r6, #8 
	str.w	r6, [r4, #0x80]		
	mov.w 	r6, #0x20	       		/* Send the sector erase command */
	str.w	r6, [r4, #0x40]
	mov.w	r6, #0x0002			
	movt	r6, #0x0208	
	str.w	r6, [r4, #0x10]
	bl	wait_flash_busy
write_address:	
	mov.w 	r6, #24 
	str.w	r6, [r4, #0x80]			
	mov 	r6, r7				/* Give target address */
	add	r2, r7, #0x1000			/* Increment target address by 4k */
	str.w	r6, [r4, #0x40]
	mov.w	r6, #0x0002			
	movt	r6, #0x0208	
	str.w	r6, [r4, #0x10]
	bl	wait_flash_busy
	mov.w	r6, #0x0001			
	movt	r6, #0x0208
	str.w	r6, [r4, #0x10]
	bl	dowait
	add	r0, r0, #1
	cmp 	r0, r1
	it	eq
	beq 	write_disable
	b	write_enable
wait_flash_busy:				/* Wait for the flash to finish the previous page write */
	ldr 	r6, [r4, #0x20]	 		/* Get status register */
	tst 	r6, #0x01 			/* If it isn't done, keep waiting */
	bne 	wait_flash_busy
	bx 	lr
dowait:
   	mov.w 	r6, #0x1000
dowaitloop:
   	subs 	r6,#1
   	bne 	dowaitloop
   	bx 	lr  
wait_auto_mode_disable:
	ldr 	r6, [r4, #0x20]	 		/* Get status register */
	tst 	r6, #0x2000 			/* Check 12th bit for Auto_Mode disable, keep waiting */
	bne 	wait_auto_mode_disable
	bx 	lr
write_disable:
	mov.w 	r6, #0x8 
	str.w	r6, [r4, #0x80]		
	mov.w 	r6, #0x4			/* Give write disable */
	str.w	r6, [r4, #0x40]	
	mov.w	r6, #0x0002			
	movt	r6, #0x0208
	str.w	r6, [r4, #0x10]	
	bl	wait_flash_busy
	mov.w	r6, #0x0001			
	movt	r6, #0x0208
	str.w	r6, [r4, #0x10]
	mov.w	r6, #0x0c40			
	movt	r6, #0x0001 			
	str.w	r6, [r4, #0x04]
	mov.w	r6, #0x0001			
	movt	r6, #0x0208
	str.w	r6, [r4, #0x10]
exit:
	bkpt 	#0x00
