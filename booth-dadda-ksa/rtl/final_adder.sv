`timescale 1ns/1ps

module final_adder #(
    parameter int PROD_W = 32
) (
    input  logic [PROD_W-1:0] sum_in,
    input  logic [PROD_W-1:0] carry_in,
    output logic [PROD_W-1:0] result
);


    // Pre-processing: bit-level generate & propagate
    logic [PROD_W-1:0] G0, P0;    // Initial generate / propagate

    assign G0 = sum_in & carry_in;
    assign P0 = sum_in ^ carry_in;


    localparam int STAGES = $clog2(PROD_W);  // 5

    logic [PROD_W-1:0] G [STAGES+1];
    logic [PROD_W-1:0] P [STAGES+1];

    assign G[0] = G0;
    assign P[0] = P0;

    genvar s, i;
    generate
        for (s = 0; s < STAGES; s++) begin : prefix_stage
            localparam int DIST = 1 << s;   // 1, 2, 4, 8, 16
            for (i = 0; i < PROD_W; i++) begin : prefix_bit
                if (i >= DIST) begin
                    assign G[s+1][i] = G[s][i] | (P[s][i] & G[s][i-DIST]);
                    assign P[s+1][i] = P[s][i] & P[s][i-DIST];
                end else begin
                    assign G[s+1][i] = G[s][i];
                    assign P[s+1][i] = P[s][i];
                end
            end
        end
    endgenerate

    generate
        for (i = 0; i < PROD_W; i++) begin : sum_bits
            if (i == 0)
                assign result[i] = P0[i];   // no carry into LSB
            else
                assign result[i] = P0[i] ^ G[STAGES][i-1];
        end
    endgenerate

endmodule : final_adder
