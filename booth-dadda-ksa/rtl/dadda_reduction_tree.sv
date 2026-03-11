
`timescale 1ns/1ps

module dadda_reduction_tree #(
    parameter int WIDTH  = 16,
    parameter int NUM_PP = WIDTH / 2,       // 8
    parameter int PROD_W = 2 * WIDTH        // 32
) (
    input  logic signed [PROD_W-1:0] pp_in [NUM_PP],
    output logic        [PROD_W-1:0] sum_out,
    output logic        [PROD_W-1:0] carry_out
);

    // -------------------------------------------------------------------------
    // CSA (3:2 compressor) function – returns {carry, sum}
    // -------------------------------------------------------------------------
    function automatic logic [1:0] csa_bit (
        input logic a, b, c
    );
        csa_bit[0] = a ^ b ^ c;        // sum
        csa_bit[1] = (a & b) | (b & c) | (a & c);  // carry
    endfunction

    // -------------------------------------------------------------------------
    // We keep an array of rows; maximum rows at any stage = NUM_PP = 8
    // -------------------------------------------------------------------------
    localparam int MAX_ROWS = NUM_PP;   // 8

    // Working rows – indexed as rows[row][bit]
    logic [PROD_W-1:0] rows [MAX_ROWS];

    // -------------------------------------------------------------------------
    // Initialise rows from partial products
    // -------------------------------------------------------------------------
    integer r;
    always_comb begin
        for (r = 0; r < NUM_PP; r++)
            rows[r] = pp_in[r];
    end

    // -------------------------------------------------------------------------
    // Dadda reduction stages (unrolled for synthesis)
    // Stage 0: 8 rows  → 6 rows
    // Stage 1: 6 rows  → 4 rows
    // Stage 2: 4 rows  → 3 rows
    // Stage 3: 3 rows  → 2 rows
    //
    // Each stage is a separate set of signals so the tool can pipeline or
    // flatten as needed.
    // -------------------------------------------------------------------------

    // --- Stage 0: 8 → 6 ---
    // Dadda target = 6; we have 8, so reduce 2 triplets to (sum+carry)
    // i.e., for each bit, apply 2 CSA to reduce from 8 to 6 addends.
    // rows[0..7] → s0[0..5]
    logic [PROD_W-1:0] s0 [6];

    genvar b;
    generate
        for (b = 0; b < PROD_W; b++) begin : stage0
            logic [1:0] csa0_a, csa0_b;
            // CSA A: rows[0], rows[1], rows[2] → sum0a, carry0a
            assign csa0_a = csa_bit(rows[0][b], rows[1][b], rows[2][b]);
            // CSA B: rows[3], rows[4], rows[5] → sum0b, carry0b
            assign csa0_b = csa_bit(rows[3][b], rows[4][b], rows[5][b]);
            // rows[6] and rows[7] pass through
            // Result 6 rows: csa0_a[0], csa0_b[0], rows[6], rows[7],
            //                csa0_a[1](shifted), csa0_b[1](shifted)
            // Carries go to next bit position — we handle shift via
            // concatenation outside the generate (see post-gen assignments)
            assign s0[0][b] = csa0_a[0];
            assign s0[1][b] = csa0_b[0];
            assign s0[2][b] = rows[6][b];
            assign s0[3][b] = rows[7][b];
        end
    endgenerate

    // Carry outputs from stage0 CSAs must be shifted left by 1
    // We use intermediate carries
    logic [PROD_W-1:0] c0_a, c0_b;
    generate
        for (b = 0; b < PROD_W; b++) begin : stage0_carry
            assign c0_a[b] = csa_bit(rows[0][b], rows[1][b], rows[2][b])[1];
            assign c0_b[b] = csa_bit(rows[3][b], rows[4][b], rows[5][b])[1];
        end
    endgenerate

    assign s0[4] = {c0_a[PROD_W-2:0], 1'b0};   // carry shifted left 1
    assign s0[5] = {c0_b[PROD_W-2:0], 1'b0};

    // --- Stage 1: 6 → 4 ---
    logic [PROD_W-1:0] s1 [4];
    logic [PROD_W-1:0] c1_a, c1_b;

    generate
        for (b = 0; b < PROD_W; b++) begin : stage1
            assign s1[0][b] = csa_bit(s0[0][b], s0[1][b], s0[2][b])[0];
            assign s1[1][b] = csa_bit(s0[3][b], s0[4][b], s0[5][b])[0];
            assign c1_a[b]  = csa_bit(s0[0][b], s0[1][b], s0[2][b])[1];
            assign c1_b[b]  = csa_bit(s0[3][b], s0[4][b], s0[5][b])[1];
        end
    endgenerate

    assign s1[2] = {c1_a[PROD_W-2:0], 1'b0};
    assign s1[3] = {c1_b[PROD_W-2:0], 1'b0};

    // --- Stage 2: 4 → 3 ---
    logic [PROD_W-1:0] s2 [3];
    logic [PROD_W-1:0] c2_a;

    generate
        for (b = 0; b < PROD_W; b++) begin : stage2
            assign s2[0][b] = csa_bit(s1[0][b], s1[1][b], s1[2][b])[0];
            assign c2_a[b]  = csa_bit(s1[0][b], s1[1][b], s1[2][b])[1];
        end
    endgenerate

    assign s2[1] = s1[3];
    assign s2[2] = {c2_a[PROD_W-2:0], 1'b0};

    // --- Stage 3: 3 → 2 ---
    logic [PROD_W-1:0] c3_a;

    generate
        for (b = 0; b < PROD_W; b++) begin : stage3
            assign sum_out[b]  = csa_bit(s2[0][b], s2[1][b], s2[2][b])[0];
            assign c3_a[b]     = csa_bit(s2[0][b], s2[1][b], s2[2][b])[1];
        end
    endgenerate

    assign carry_out = {c3_a[PROD_W-2:0], 1'b0};

endmodule : dadda_reduction_tree
