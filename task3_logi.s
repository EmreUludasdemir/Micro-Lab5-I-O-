.include "address_map_arm.s"
.equ DELAY, 50000000              // 0.25 saniye

/* Task 3 (Logi) – HEX5-0 Knight Rider (6 ekran)
 *
 * HEX3_HEX0_BASE (0xFF200020):
 *   Bit [6:0]   → HEX0  (pos 0)
 *   Bit [14:8]  → HEX1  (pos 1)
 *   Bit [22:16] → HEX2  (pos 2)
 *   Bit [30:24] → HEX3  (pos 3)
 *
 * HEX5_HEX4_BASE (0xFF200030):
 *   Bit [6:0]   → HEX4  (pos 4)
 *   Bit [14:8]  → HEX5  (pos 5)
 *
 * Hareket dizisi: 0→1→2→3→4→5→4→3→2→1→0→...
 *
 * Lookup tablosu kullanılır:
 *   Her giriş 8 byte: [HEX3_HEX0 değeri, HEX5_HEX4 değeri]
 */

.text
.global _start

_start:
    LDR R4, =HEX3_HEX0_BASE      // HEX3-0 port adresi
    LDR R8, =HEX5_HEX4_BASE      // HEX5-4 port adresi
    LDR R1, =MPCORE_PRIV_TIMER   // Timer adresi

    /* Timer kurulumu */
    LDR R3, =DELAY
    STR R3, [R1]
    MOV R3, #0b011
    STR R3, [R1, #0x8]

Logi:
    /* Sağdan sola: pos 0 → pos 5 */
    MOV R5, #0
LOGI_RIGHT:
    BL LOGI_SHOW_WAIT
    ADD R5, R5, #1
    CMP R5, #6
    BNE LOGI_RIGHT               // pos == 6 olunca dur (5'i gösterdik)

    /* Soldan sağa: pos 4 → pos 0 */
    MOV R5, #4
LOGI_LEFT:
    BL LOGI_SHOW_WAIT
    SUBS R5, R5, #1
    BPL LOGI_LEFT

    B Logi

/* ---------------------------------------------------
 * Alt Program: LOGI_SHOW_WAIT
 * Giriş: R5 = pozisyon (0-5)
 *        R4 = HEX3_HEX0_BASE, R8 = HEX5_HEX4_BASE
 *        R1 = Timer base
 * --------------------------------------------------- */
LOGI_SHOW_WAIT:
    /* Lookup tablosundan değerleri al */
    LDR R9, =hex_table
    LSL R7, R5, #3                // R7 = R5 * 8 (her giriş 8 byte: 2 word)
    ADD R9, R9, R7                // R9 = &hex_table[R5]

    LDR R2, [R9]                  // HEX3-0 değeri
    LDR R3, [R9, #4]              // HEX5-4 değeri

    STR R2, [R4]                  // HEX3-0 register'a yaz
    STR R3, [R8]                  // HEX5-4 register'a yaz

    /* Timer bekle */
WAIT_L:
    LDR R3, [R1, #0xC]
    CMP R3, #0
    BEQ WAIT_L
    STR R3, [R1, #0xC]
    BX LR

/* ---------------------------------------------------
 * Lookup Tablosu: 6 pozisyon x 2 word
 * Format: .word HEX3_HEX0_val, HEX5_HEX4_val
 * --------------------------------------------------- */
.data
hex_table:
    .word 0x00000040, 0x00000000   // pos 0: HEX0 orta segment
    .word 0x00004000, 0x00000000   // pos 1: HEX1 orta segment
    .word 0x00400000, 0x00000000   // pos 2: HEX2 orta segment
    .word 0x40000000, 0x00000000   // pos 3: HEX3 orta segment
    .word 0x00000000, 0x00000040   // pos 4: HEX4 orta segment
    .word 0x00000000, 0x00004000   // pos 5: HEX5 orta segment

.end
