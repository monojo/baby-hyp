#include "debug-exynos4210.inc"

#define PRINT(_s)       \
        adr   r0, 98f ; \
        bl    puts    ; \
		b 	  99f	  ; \
98:     .asciz _s     ; \
        .align 2      ; \
99:

	@.arm
	.text
	.code 32
	.global _start
	.func _start

        /* This must be the very first address in the loaded image.
         * It should be linked at XEN_VIRT_START, and loaded at any
         * 4K-aligned address.  All of text+data+bss must fit in 2MB,
         * or the initial pagetable code below will need adjustment. */
_start:
        /* zImage magic header, see:
         * http://www.simtec.co.uk/products/SWLINUX/files/booting_article.html#d0e309
         */
        .rept 8 /* repeat */
        mov   r0, r0
        .endr
        b     past_zImage

        @.word ZIMAGE_MAGIC_NUMBER    /* Magic numbers to help the loader */
        @.word 0x00000000             /* absolute load/run zImage address or
                                      * 0 for PiC */
        @.word (_end - start)         /* zImage end address */
past_zImage:
        cpsid aif                    /* Disable all interrupts */

        /* Save the bootloader arguments in less-clobberable registers */
        @mov   r8, r2                 /* r8 := DTB base address */
		@ldr   r8, =0x4fff0000		  /* direct load DTB addr */
        /* Find out where we are */
        ldr   r0, =_start
        adr   r9, _start              /* r9  := paddr (start) */
        sub   r10, r9, r0            /* r10 := phys-offset */

        mov   r12, #0                /* r12 := is_secondary_cpu */

        b     common_start

common_start:
        mov   r7, #0                 /* r7 := CPU ID. Initialy zero until we
                                      * find that multiprocessor extensions are
                                      * present and the system is SMP */      
1:

        /* Non-boot CPUs wait here until __cpu_up is ready for them */
        teq   r12, #0
        beq   1f

1:

        @ldr   r11, =EARLY_UART_BASE_ADDRESS  /* r11 := UART base address */
		ldr   r11, =0x12c20000  /* r11 := UART base address */
        teq   r12, #0                /* Boot CPU sets up the UART too */
        bleq  init_uart
        PRINT("- CPU ")
        mov   r0, r7
        bl    putn
        PRINT(" booting - \r\n")
		PRINT("- UART ADDRESS ")
		mov   r0, r11
		bl    putn
		PRINT("\r\n")
		@mov   r0, r8
		@bl    putn
		@PRINT(" dtb arg \r\n")

        /* Check that this CPU has Hyp mode */
        @mrc   CP32(r0, ID_PFR1)
        @and   r0, r0, #0xf000        /* Bits 12-15 define virt extensions */
        @teq   r0, #0x1000            /* Must == 0x1 or may be incompatible */
        @beq   1f
        @PRINT("- CPU doesn't support the virtualization extensions -\r\n")
        b     fail
@1:

        /* Check that we're already in Hyp mode */
        @mrs   r0, cpsr
        @and   r0, r0, #0x1f          /* Mode is in the low 5 bits of CPSR */
        @teq   r0, #0x1a              /* Hyp Mode? */
        @beq   hyp

        /* OK, we're boned. */
        @PRINT("- Xen must be entered in NS Hyp mode -\r\n" \
              "- Please update the bootloader -\r\n")
        @b     fail

/* Fail-stop */
fail:   PRINT("- Boot failed -\r\n")
1:      wfe
        b     1b

hyp:   PRINT("- hyp IN -\r\n")
1:      wfe
        b     1b

/* Bring up the UART.
 * r11: Early UART base address
 * Clobbers r0-r2 */
init_uart:
        adr   r0, 1f
        b     puts                  /* Jump to puts */
1:      .asciz "- UART enabled -\r\n"
        .align 4

/* Print early debug messages.
 * r0: Nul-terminated string to print.
 * r11: Early UART base address
 * Clobbers r0-r1 */
puts:
        early_uart_ready r11, r1
        ldrb  r1, [r0], #1           /* Load next char */
        teq   r1, #0                 /* Exit on nul */
        moveq pc, lr
        early_uart_transmit r11, r1
        b puts

/* Print a 32-bit number in hex.  Specific to the PL011 UART.
 * r0: Number to print.
 * r11: Early UART base address
 * Clobbers r0-r3 */
putn:
        adr   r1, hex
        mov   r3, #8
1:
        early_uart_ready r11, r2
        and   r2, r0, #0xf0000000    /* Mask off the top nybble */
        ldrb  r2, [r1, r2, lsr #28]  /* Convert to a char */
        early_uart_transmit r11, r2
        lsl   r0, #4                 /* Roll it through one nybble at a time */
        subs  r3, r3, #1
        bne   1b
        mov   pc, lr

hex:    .ascii "0123456789abcdef"
        .align 2
