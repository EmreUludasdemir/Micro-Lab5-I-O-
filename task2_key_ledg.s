.include "address_map_arm.s"
.equ bit_24_pattern, 0x01000000

/* Task 2 – KEY butonuyla LEDG Toggle
 * Herhangi bir KEY'e basıldığında LEDG yanıp söner.
 * EdgeCapture register'ı polling yöntemiyle okunur.
 * Offset'ler (KEY_BASE = 0xFF200050):
 *   +0x00 → Data register
 *   +0x08 → InterruptMask register
 *   +0x0C → EdgeCapture register  ← bunu kullanıyoruz
 */

.text
.global _start

_start:
    LDR R0, =HPS_GPIO1_BASE       // GPIO1 base adresi (LED ve KEY için)
    LDR R1, =KEY_BASE             // KEY base adresi (0xFF200050)

    /* LEDG (GPIO1 bit 24) çıkış olarak ayarla */
    LDR R2, =bit_24_pattern
    STR R2, [R0, #0x4]            // DDR register (offset +4): bit 24 = output

    MOV R2, #0                    // LEDG başlangıçta kapalı
    STR R2, [R0]                  // Data register'a yaz

    /* EdgeCapture register'ı temizle (tüm bitlere 1 yaz → sıfırla) */
    MOV R3, #0xF
    STR R3, [R1, #0xC]

KEYEE:
    LDR R3, [R1, #0xC]            // EdgeCapture register'ı oku
    CMP R3, #0
    BEQ KEYEE                     // 0 ise hiç tuşa basılmamış, bekle

    /* Tuşa basıldı: LEDG'yi toggle et */
    EOR R2, R2, #bit_24_pattern   // bit 24'ü tersle
    STR R2, [R0]                  // GPIO1 Data register'a yaz

    /* EdgeCapture'ı temizle: ilgili bit pozisyonuna 1 yazarak sıfırla */
    STR R3, [R1, #0xC]

    B KEYEE

.end
