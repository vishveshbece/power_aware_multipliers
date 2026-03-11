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
* [cite_start]**Structure:** Reduces the initial number of partial products by 50% (from 16 rows down to 8)[cite: 18].
* **Implementation:** Typically uses brute-force sign extension to handle signed values.
* [cite_start]**Performance:** A balanced "middle-ground" architecture used as the baseline for this analysis[cite: 59].

### Proposed: Booth-Dadda-KoggeStone (KSA)
* [cite_start]**Booth Encoding:** Uses Radix-4 encoding to minimize the number of rows[cite: 1, 74].
* [cite_start]**Dadda Tree:** Reduces 8 rows to 2 using the minimum number of gates at each level to meet target heights ($8 \rightarrow 6 \rightarrow 4 \rightarrow 3 \rightarrow 2$)[cite: 18].
* **Kogge-Stone Adder:** A parallel-prefix adder used for the final 32-bit addition, offering minimal logic depth ($O(\log_2 N)$).



---

## 2. Performance Analysis (Synthesis Results)

The comparison between the **Baseline Booth** and the **Booth-Dadda-KSA** reveals a strategic trade-off between raw speed and energy efficiency.

| Metric | Baseline Booth | Booth-Dadda-KSA | Analysis |
| :--- | :--- | :--- | :--- |
| **Path Delay** | **254 ps** | 291 ps | KSA introduces wiring delay at 16-bit widths. |
| **Power** | $1.18 \times 10^{-4}$ W | **$9.06 \times 10^{-5}$ W** | **23% power reduction** in the hybrid model. |
| **PDP (Energy)** | $2.99 \times 10^{-14}$ J | **$2.63 \times 10^{-14}$ J** | **12% improvement** in energy efficiency. |

### Why the Time Increased (254ps to 291ps)
Despite using faster algorithms, the delay increased due to **Physical Design Overheads**:
* [cite_start]**Wiring Congestion:** The Kogge-Stone Adder is a dense prefix tree with long-distance interconnects[cite: 46].
* **High Fan-out:** Prefix nodes drive multiple gates, increasing capacitive loading and slowing signal propagation compared to "local" wiring in the baseline.
* **Overhead at Small Widths:** At 16 bits, the logarithmic advantage is partially offset by the routing complexity and fixed logic depth of the KSA.

---

## 3. Implemented Optimizations

### Sign-Prevention (Sign-Propagate)
* [cite_start]**Logic:** Instead of 32-bit sign extension, the implementation uses a constant bit-pattern to handle sign bits[cite: 86, 87].
* [cite_start]**Benefit:** This prevents redundant switching activity in the upper bits of the reduction tree, significantly lowering dynamic power[cite: 86].

### Bitwise Inversion & Correction Injection
* [cite_start]**Logic:** To avoid the delay of the subtraction operator (`-mag`), the design uses bitwise inversion (`~mag`)[cite: 85, 86].
* [cite_start]**Implementation:** The required "plus one" for 2's complement is handled via **Correction Bits** injected directly into the first stage of the Dadda tree[cite: 24, 25, 63].

### Han-Carlson Prefix Network (Proposed Enhancement)
* [cite_start]**Hybridization:** To mitigate wiring delay, the design utilizes a **Han-Carlson** adder[cite: 46].
* [cite_start]**Benefit:** It combines the speed of Kogge-Stone with the area/power efficiency of Brent-Kung by using a sparser prefix network[cite: 46, 50, 53].



---

## 4. Design Hierarchy

* [cite_start]**`multiplier_top.sv`**: Top-level integration with handshake logic and registered outputs[cite: 59].
* **`partial_product_generator.sv`**: Radix-4 encoding and optimized partial product generation[cite: 74].
* [cite_start]**`booth_encoder.sv`**: Logic for encoding multiplier bits into Booth digits[cite: 1].
* **`dadda_reduction_tree.sv`**: Multi-stage 3:2 compression tree[cite: 18].
* [cite_start]**`final_adder.sv`**: 32-bit Han-Carlson parallel-prefix adder[cite: 44].

---

## 5. Conclusion
The **Booth-Dadda-KSA** architecture represents a superior design choice for low-power ASIC applications. While the transition to parallel-prefix addition introduces minor timing overhead at the 16-bit scale, the cumulative benefits of **Sign-Prevention** and **Dadda reduction** result in a significantly lower Power-Delay Product (PDP) and high energy efficiency.