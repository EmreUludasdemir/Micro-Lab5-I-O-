.include    "address_map_arm.s" 
.include    "interrupt_ID.s" 



.section    .vectors, "ax" 

            B       _start                  // reset vector
            B       SERVICE_UND             // undefined instruction vector
            B       SERVICE_SVC             // software interrupt vector
            B       SERVICE_ABT_INST        // aborted prefetch vector
            B       SERVICE_ABT_DATA        // aborted data vector
.word       0                               // unused vector
            B       SERVICE_IRQ             // IRQ interrupt vector
            B       SERVICE_FIQ             // FIQ interrupt vector

.text        
.global     _start 
_start:                                     
/* Set up stack pointers for IRQ and SVC processor modes */
            MOV     R1, #0b11010010         // interrupts masked, MODE = IRQ
            MSR     CPSR_c, R1              // change to IRQ mode
            LDR     SP, =A9_ONCHIP_END - 3  // set IRQ stack to top of A9 onchip memory

/* Change to SVC (supervisor) mode with interrupts disabled */
            MOV     R1, #0b11010011         // interrupts masked, MODE = SVC
            MSR     CPSR, R1                // change to supervisor mode
            LDR     SP, =DDR_END - 3        // set SVC stack to top of DDR3 memory

            BL      CONFIG_GIC              // configure the ARM generic interrupt controller

/* Configure the pushbutton KEYs port to generate interrupts */
            LDR     R0, =KEY_BASE           // pushbutton KEY base address
            MOV     R1, #0xF                // set interrupt mask bits for KEY0..KEY3
            STR     R1, [R0, #0x8]          // interrupt mask register is (base + 8)

/* ------------------------------------------------------------------------------
 * Task II step 2: initialize the KEY-press counter (KPRSS) to 0
 * ----------------------------------------------------------------------------*/
            LDR     R0, =KPRSS              // address of the KEY-press counter
            MOV     R1, #0                  // start the counter at 0
            STR     R1, [R0]                // KPRSS = 0

/* ------------------------------------------------------------------------------
 * Task II step 1: pre-load the HEX display with "00" so that all four digits
 * have a defined value before the first KEY press happens.
 * ----------------------------------------------------------------------------*/
            LDR     R0, =HEX3_HEX0_BASE     // base address of HEX3..HEX0 display
            LDR     R1, =SEG_TABLE          // address of seven-segment lookup table
            LDRB    R2, [R1]                // R2 = SEG_TABLE[0] = code for digit '0'
            ORR     R2, R2, R2, LSL #8      // place digit '0' on both HEX0 and HEX1
            STR     R2, [R0]                // display "00" initially

/* Enable IRQ interrupts in the ARM processor */
            MOV     R0, #0b01010011         // IRQ unmasked, MODE = SVC
            MSR     CPSR_c, R0              


IDLE:                                       
            LDR     R0, =KPRSS              // pointer to KEY-press counter
            LDR     R1, [R0]                // R1 = current count value

/* Reduce the value modulo 100 in case KPRSS is ever larger than 99.
 * (Cortex-A9 in the DE1-SoC has no UDIV, so we use repeated subtraction.) */
MOD_100:                                    
            CMP     R1, #100                // value still >= 100 ?
            BLT     EXTRACT_DIGITS          // no -> we have a 2-digit number
            SUB     R1, R1, #100            // strip one hundred
            B       MOD_100                 

EXTRACT_DIGITS:                             
            MOV     R3, #0                  // R3 = tens digit accumulator
TENS_LOOP:                                  
            CMP     R1, #10                 // remaining value >= 10 ?
            BLT     TENS_DONE               // no -> R1 already holds the ones digit
            SUB     R1, R1, #10             // peel off another ten
            ADD     R3, R3, #1              // and bump the tens digit
            B       TENS_LOOP               
TENS_DONE:                                  
                                            // R1 = ones digit (0..9)
                                            // R3 = tens digit (0..9)

/* Look up the 7-segment patterns for both digits */
            LDR     R4, =SEG_TABLE          // base of the lookup table
            LDRB    R5, [R4, R1]            // R5 = 7-seg code for the ones digit
            LDRB    R6, [R4, R3]            // R6 = 7-seg code for the tens digit

/* Concatenate the codes into a single 32-bit word:
 *   bits [ 7:0] -> HEX0 (ones)
 *   bits [15:8] -> HEX1 (tens)
 *   bits [31:16] = 0     -> HEX2 and HEX3 stay blank */
            ORR     R5, R5, R6, LSL #8      // R5 = (tens << 8) | ones

/* Write the combined pattern to the HEX display */
            LDR     R0, =HEX3_HEX0_BASE     // base address of HEX3..HEX0
            STR     R5, [R0]                // show the two-digit count on HEX1-HEX0

            B       IDLE                    // main program keeps idling

/* ============================================================================
 * Define the exception service routines
 * ==========================================================================*/

/*--- Undefined instructions --------------------------------------------------*/
SERVICE_UND:                                
            B       SERVICE_UND             

/*--- Software interrupts -----------------------------------------------------*/
SERVICE_SVC:                                
            B       SERVICE_SVC             

/*--- Aborted data reads ------------------------------------------------------*/
SERVICE_ABT_DATA:                           
            B       SERVICE_ABT_DATA        

/*--- Aborted instruction fetch -----------------------------------------------*/
SERVICE_ABT_INST:                           
            B       SERVICE_ABT_INST        

/*--- IRQ ---------------------------------------------------------------------*/
SERVICE_IRQ:                                
            PUSH    {R0-R7, LR}             

/* Read the ICCIAR from the CPU interface */
            LDR     R4, =MPCORE_GIC_CPUIF   
            LDR     R5, [R4, #ICCIAR]       // read from ICCIAR

FPGA_IRQ1_HANDLER:                          
            CMP     R5, #KEYS_IRQ           // is this the KEYs interrupt?
UNEXPECTED: BNE     UNEXPECTED              // if not recognized, stop here

            BL      KEY_ISR                 // service the KEYs interrupt
EXIT_IRQ:                                   
/* Write to the End of Interrupt Register (ICCEOIR) */
            STR     R5, [R4, #ICCEOIR]      // write to ICCEOIR

            POP     {R0-R7, LR}             
            SUBS    PC, LR, #4              

/*--- FIQ ---------------------------------------------------------------------*/
SERVICE_FIQ:                                
            B       SERVICE_FIQ             

.align 2
.global     KPRSS
KPRSS:      .word   0                       // KEY press counter (initial value 0)

.global     SEG_TABLE
SEG_TABLE:  .byte   0x3F, 0x06, 0x5B, 0x4F  // codes for 0, 1, 2, 3
            .byte   0x66, 0x6D, 0x7D, 0x07  // codes for 4, 5, 6, 7
            .byte   0x7F, 0x6F, 0x00, 0x00  // codes for 8, 9, blank, blank
.align 2

.end         
