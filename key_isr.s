.include    "address_map_arm.s" 

/****************************************************************************************
 * Pushbutton - Interrupt Service Routine (Lab 6 Task II)
 *
 * Behavior:
 *   1. Increment the global KPRSS counter (wraps to 0 after 99).
 *   2. Light the LED that matches the pressed KEY (KEY0 -> LEDR0, ..., KEY3 -> LEDR3).
 *      This preserves the original example's LED behavior.
 ***************************************************************************************/

.global     KPRSS                           // declared (and stored) in interrupt_example.s

.global     KEY_ISR 
KEY_ISR:                        
        LDR     R0, =KEY_BASE           // base address of pushbutton KEY port
        LDR     R1, [R0, #0xC]          // read edge capture register (which KEY caused IRQ)
        MOV     R2, #0xF        
        STR     R2, [R0, #0xC]          // clear the edge-capture flags (acknowledge KEY)

        /* ------------------------------------------------------------
         * Increment KPRSS by 1 on every KEY interrupt; wrap at 100 so
         * the value always fits in two decimal digits.
         * (R0..R7 are already saved by SERVICE_IRQ, so R6/R7 are free.)
         * ----------------------------------------------------------*/
        LDR     R7, =KPRSS              // address of KEY-press counter
        LDR     R6, [R7]                // R6 = current count
        ADD     R6, R6, #1              // count = count + 1
        CMP     R6, #100                // reached 100 ?
        MOVEQ   R6, #0                  // if so, wrap back to 0
        STR     R6, [R7]                // save updated count

        LDR     R0, =LED_BASE           // base address of LED display
CHECK_KEY0:                     
        MOV     R3, #0x1        
        ANDS    R3, R3, R1              // check for KEY0
        BEQ     CHECK_KEY1      
        MOV     R2, #0b1                // LEDR0 on
        B       END_KEY_ISR     
CHECK_KEY1:
        MOV     R3, #0x2
        ANDS    R3, R3, R1              // check for KEY1
        BEQ     CHECK_KEY2                     
        MOV     R2, #0b10               // LEDR1 on
        B       END_KEY_ISR
CHECK_KEY2:
        MOV     R3, #0x4
        ANDS    R3, R3, R1              // check for KEY2
        BEQ     CHECK_KEY3                     
        MOV     R2, #0b100              // LEDR2 on
        B       END_KEY_ISR
CHECK_KEY3:                     
        MOV     R2, #0b1000             // LEDR3 on
END_KEY_ISR:                    
        STR     R2, [R0]                // display KEY pressed on LED
        BX      LR              

.end         
