.include "address_map_arm.s"
.equ DELAY, 50000000              // 0.25 saniye = 200MHz / 4

/* Task 3 (Three) – HEX3-0 Knight Rider
 *
 * Her 7-segment ekranın orta segmenti (segment 6 = bit 6 = 0x40) kullanılır.
 *
 * HEX3_HEX0_BASE (0xFF200020) register bit dağılımı:
 *   Bit [6:0]   → HEX0  (en sağ)
 *   Bit [14:8]  → HEX1
 *   Bit [22:16] → HEX2
 *   Bit [30:24] → HEX3  (en sol)
 *
 * Orta segment her ekran için: 0x40 << (ekran_no * 8)
 *   HEX0 → 0x00000040
 *   HEX1 → 0x00004000
 *   HEX2 → 0x00400000
 *   HEX3 → 0x40000000
 *
 * Hareket dizisi: 0→1→2→3→2→1→0→1→... (sağdan sola, geri gel)
 */

.text
.global _start

_start:
    LDR R4, =HEX3_HEX0_BASE      // HEX3-0 port adresi
    LDR R1, =MPCORE_PRIV_TIMER   // A9 Private Timer adresi

    /* Timer kurulumu: otomatik yeniden yükleme (A=1) + etkin (E=1) */
    LDR R3, =DELAY
    STR R3, [R1]                  // Load register'a gecikme değerini yaz
    MOV R3, #0b011                // bit1=A (auto-reload), bit0=E (enable)
    STR R3, [R1, #0x8]            // Control register

Three:
    /* Sağdan sola: HEX0 (R5=0) → HEX3 (R5=3) */
    MOV R5, #0
RIGHT:
    BL SHOW_WAIT                  // R5 pozisyonunu göster ve timer bekle
    ADD R5, R5, #1
    CMP R5, #4
    BNE RIGHT                    // R5 == 4 olunca dur (3'ü gösterdik)

    /* Soldan sağa: HEX2 (R5=2) → HEX0 (R5=0) */
    /* Not: HEX3 tekrar gösterilmiyor (zaten gösterildi) */
    MOV R5, #2
LEFT:
    BL SHOW_WAIT
    SUBS R5, R5, #1               // R5-- ve flag güncelle
    BPL LEFT                      // R5 >= 0 ise devam (BPL: branch if plus/zero)

    B Three                       // Döngüyü yeniden başlat

/* ---------------------------------------------------
 * Alt Program: SHOW_WAIT
 * Giriş: R5 = gösterilecek HEX pozisyonu (0-3)
 *        R4 = HEX3_HEX0_BASE
 *        R1 = Timer base
 * Bozulan registerlar: R2, R3, R7
 * --------------------------------------------------- */
SHOW_WAIT:
    /* Pattern hesapla: R2 = 0x40 << (R5 * 8) */
    MOV R2, #0x40
    LSL R7, R5, #3                // R7 = R5 * 8  (shift miktarı)
    LSL R2, R2, R7                // R2 = 0x40 << R7

    STR R2, [R4]                  // HEX3-0 register'a yaz

    /* Timer flag'i bekle (Interrupt Status register, offset +0xC) */
WAIT_T:
    LDR R3, [R1, #0xC]            // F bitini oku
    CMP R3, #0
    BEQ WAIT_T                   // F=0 ise hâlâ sayıyor, bekle

    STR R3, [R1, #0xC]            // F bitini temizle (1 yazarak sıfırla)
    BX LR                        // Alt programdan dön

.end
