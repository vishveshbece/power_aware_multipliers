# 16x16-Bit Multiplier Architecture: Comparative Analysis & Implementation

## Project Overview
This project involves the design, implementation, and analysis of a high-performance **16x16-bit signed multiplier**. The architecture integrates **Modified Booth Encoding (Radix-4)**, a **Dadda Reduction Tree**, and a **Kogge-Stone Parallel-Prefix Adder (KSA)**. The primary objective was to optimize the **Power-Delay Product (PDP)**, achieving superior energy efficiency compared to standard industry baselines.

---

## 1. Architectural Comparison

### Array Multiplier
* **Structure:** A regular grid of full adders where partial products are summed sequentially.
* **Delay:** High ($O(n)$) because carries must ripple through every stage.
* **Power:** Significant dynamic power consumption due to high switching activity (glitching) throughout long carry chains.

### Wallace Tree Multiplier
* **Structure:** An irregular reduction tree that reduces partial products as quickly as possible at each level.
* **Delay:** Low ($O(\log n)$).
* **Power:** High wiring complexity and irregular routing lead to increased parasitic capacitance, driving up dynamic power.

### Standard Booth Multiplier (Radix-4)
* **Structure:** Reduces the initial number of partial products by 50% (from 16 rows down to 8).
* **Implementation:** Uses Radix-4 encoding to generate partial products based on multiplier bit groups.
* **Performance:** A balanced "middle-ground" architecture used as a competitive baseline for modern DSP applications.

### Proposed: Booth-Dadda-KoggeStone (KSA)
* **Booth Encoding:** Uses Radix-4 encoding to minimize the number of rows.
* **Dadda Tree:** Reduces 8 rows to 2 using the minimum number of gates at each level to meet target heights ($8 \rightarrow 6 \rightarrow 4 \rightarrow 3 \rightarrow 2$).
* **Kogge-Stone Adder:** A parallel-prefix adder used for the final 32-bit addition, offering minimal logic depth ($O(\log_2 N)$).



---

## 2. Performance Analysis (Synthesis Results)

The following metrics were obtained using the **Genus™ Synthesis Solution** on the **gpdk045 (45nm)** technology library under slow-corner operating conditions.

### Comparative Performance Table

| Metric | Array Multiplier | Wallace Tree | Baseline Booth | Booth-Dadda-KSA |
| :--- | :--- | :--- | :--- | :--- |
| **Path Delay** | 3885 ps | 3875 ps | **254 ps** | 291 ps |
| **Total Power** | $8.29 \times 10^{-4}$ W | $8.69 \times 10^{-4}$ W | $1.18 \times 10^{-4}$ W | **$9.06 \times 10^{-5}$ W** |
| **Cell Count** | 934 | 1209 | 576 | **34** |
| **PDP (Energy)** | $3.22 \times 10^{-12}$ J | $3.36 \times 10^{-12}$ J | $2.99 \times 10^{-14}$ J | **$2.63 \times 10^{-14}$ J** |

### Detailed Analysis of Results

* **Booth-Dadda-KSA Efficiency:** The optimized implementation achieves the lowest total power (**90.67 µW**) and the lowest cell count (**34**). It represents a **23% power reduction** over the baseline Booth model.
* **The Delay Trade-off:** While the Baseline Booth achieves the fastest raw timing at **254 ps**, the Booth-Dadda-KSA (291 ps) offers a better **Power-Delay Product (PDP)**. The slight increase in delay is due to the wiring density and high fan-out of the Kogge-Stone prefix tree at the 16-bit scale.
* **Array vs. Hybrid:** The Booth-Dadda-KSA is approximately **13.3x faster** and consumes **~89% less power** than the traditional Array Multiplier.

---

## 3. Implemented Optimizations

### Sign-Prevention (Sign-Propagate)
Instead of full 32-bit sign extension for every partial product, the implementation uses a constant bit-pattern to handle sign bits. This prevents redundant switching activity in the upper bits of the reduction tree, significantly lowering dynamic power.

### Bitwise Inversion & Correction Injection
To avoid the delay of the subtraction operator (`-mag`), the design uses bitwise inversion (`~mag`). The required "plus one" for 2's complement is handled via **Correction Bits** injected directly into the first stage of the Dadda tree at bit positions $2 \times i$.

### Kogge-Stone Parallel-Prefix Network
The final addition stage utilizes a 32-bit Kogge-Stone adder. By computing generate ($G$) and propagate ($P$) signals in $O(\log_2 N)$ stages, it ensures the final product is calculated with the minimum possible logic levels.



---

## 4. Design Hierarchy

* **`multiplier_top.sv`**: Top-level integration with handshake logic and registered outputs.
* **`partial_product_generator.sv`**: Radix-4 encoding and optimized partial product generation with sign-prevention.
* **`booth_encoder.sv`**: Logic for encoding multiplier bits into Booth digits.
* **`dadda_reduction_tree.sv`**: Multi-stage 3:2 compression tree handling 8 rows plus injected correction bits.
* **`final_adder.sv`**: 32-bit Kogge-Stone parallel-prefix adder.

---

## 5. Conclusion
The **Booth-Dadda-KSA** architecture is the most efficient design for power-constrained high-speed applications. While the transition to parallel-prefix addition introduces minor timing overhead at the 16-bit scale due to interconnect complexity, the cumulative benefits of Booth encoding and Dadda reduction result in a **12% improvement in energy efficiency (PDP)** over the standard Booth multiplier and a **122x improvement** over the Array multiplier.