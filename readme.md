# 16x16-Bit Multiplier Architecture: Booth-Dadda-KoggeStone (Kogge-Stone)

## Project Overview
This project involves the design, implementation, and analysis of a high-performance **16x16-bit signed multiplier**. The architecture integrates **Modified Booth Encoding (Radix-4)**, a **Dadda Reduction Tree**, and a **Kogge-Stone Parallel-Prefix Adder (KSA)**. The primary objective was to optimize the **Power-Delay Product (PDP)** for energy-efficient ASIC applications.

---

## 1. Architectural Comparison

### Array Multiplier
* **Structure:** A regular grid of full adders where partial products are summed sequentially.
* **Delay:** High ($O(n)$); carries must ripple through every cell.
* **Power:** Significant dynamic power consumption due to heavy glitching throughout the carry chains.

### Wallace Tree Multiplier
* **Structure:** An irregular tree that reduces partial products as quickly as possible at each level.
* **Delay:** Low ($O(\log n)$).
* **Power:** High wiring complexity and irregular routing lead to high parasitic capacitance.

### Standard Booth Multiplier (Radix-4)
* **Structure:** Reduces the initial number of partial products by 50% (from 16 rows down to 8).
* **Implementation:** Usually relies on brute-force sign extension to handle signed values.
* **Performance:** A balanced middle-ground architecture used as the baseline for this analysis.

### Implemented: Booth-Dadda-KoggeStone (Kogge-Stone)
* **Booth Encoding:** Uses Radix-4 encoding to minimize the number of rows.
* **Dadda Tree:** Reduces 8 rows to 2 using the minimum number of gates at each level to meet target heights: $8 \rightarrow 6 \rightarrow 4 \rightarrow 3 \rightarrow 2$.
* **Kogge-Stone Adder:** A parallel-prefix adder used for the final 32-bit addition, offering the minimum possible logic depth ($O(\log_2 N)$).



---

## 2. Performance Analysis (Synthesis Results)

The analysis compares the **Baseline Booth** against the **Booth-Dadda-KSA** implementation.

| Metric | Baseline Booth | Booth-Dadda-KSA | Analysis |
| :--- | :--- | :--- | :--- |
| **Path Delay** | **254 ps** | 291 ps | KSA introduces wiring delay at 16-bit widths. |
| **Power** | $1.18 \times 10^{-4}$ W | **$9.06 \times 10^{-5}$ W** | **23% power reduction** in the hybrid model. |
| **PDP (Energy)** | $2.99 \times 10^{-14}$ J | **$2.63 \times 10^{-14}$ J** | **12% improvement** in energy efficiency. |

### Why the Time Increased (254ps to 291ps)
Despite using faster algorithms, the delay increased due to **Physical Design Overheads**:
* **Wiring Congestion:** The Kogge-Stone Adder is a dense prefix tree with long-distance interconnects.
* **High Fan-out:** Prefix nodes drive multiple gates, increasing capacitive loading and slowing signal propagation compared to "local" wiring in the baseline.
* **Overhead at Small Widths:** At 16 bits, the logarithmic advantage is partially offset by the routing complexity and fixed logic depth of the KSA.

---

## 3. Implemented Optimizations

### Sign-Prevention (Sign-Propagate)
* **Logic:** Instead of 32-bit sign extension, the implementation uses a constant bit-pattern to handle sign bits.
* **Benefit:** This prevents redundant switching activity in the upper bits of the reduction tree, significantly lowering dynamic power.

### Bitwise Inversion & Correction Injection
* **Logic:** To avoid the delay of the subtraction operator, the design uses bitwise inversion (`~mag`).
* **Implementation:** The required "plus one" for 2's complement is handled via **Correction Bits** injected directly into the first stage of the Dadda tree at bit positions $2 \times i$.

### Kogge-Stone Parallel-Prefix Network
* **Logic:** Computes generate ($G$) and propagate ($P$) signals in $O(\log_2 N)$ stages.
* **Structure:** For 32-bit width, it utilizes a 5-stage prefix tree to ensure the final product is calculated with minimum logic levels.



---

## 4. Design Hierarchy

* **`multiplier_top.sv`**: Top-level integration with handshake logic and registered outputs.
* **`partial_product_generator.sv`**: Radix-4 encoding and optimized partial product generation.
* **`booth_encoder.sv`**: Logic for encoding multiplier bits into Booth digits.
* **`dadda_reduction_tree.sv`**: Multi-stage 3:2 compression tree handling 8 rows plus correction bits.
* **`final_adder.sv`**: 32-bit Kogge-Stone parallel-prefix adder.

---

## 5. Conclusion
The **Booth-Dadda-KSA** architecture is a superior choice for low-power ASIC applications. Although the transition to parallel-prefix addition introduces minor timing overhead at the 16-bit scale due to wiring complexity, the combined benefits of **Sign-Prevention** and **Dadda reduction** result in a 12% improvement in the Power-Delay Product (PDP).