
`timescale 1ns/1ps

module partial_product_generator #(
    parameter int WIDTH  = 16,
    parameter int PP_W   = WIDTH + 2,          // Width of each partial product
    parameter int NUM_PP = WIDTH / 2,          // Number of partial products (8)
    parameter int PROD_W = 2 * WIDTH           // Final product width (32)
) (
    input  logic signed [WIDTH-1:0]  A,        // Multiplicand
    input  logic        [WIDTH-1:0]  B,        // Multiplier

    // Partial products output – sign-extended to PROD_W, shifted per group
    output logic signed [PROD_W-1:0] pp [NUM_PP]
);

    // -------------------------------------------------------------------------
    // Internal Booth encoding signals (one per group)
    // -------------------------------------------------------------------------
    logic neg  [NUM_PP];
    logic two  [NUM_PP];
    logic one  [NUM_PP];
    logic zero [NUM_PP];
    genvar gi;
    generate
        for (gi = 0; gi < NUM_PP; gi++) begin : gen_booth_enc
            logic b_m1, b_i_, b_p1;

            assign b_m1 = (gi == 0) ? 1'b0       : B[2*gi - 1];
            assign b_i_ = B[2*gi];
            assign b_p1 = (2*gi+1 < WIDTH)        ? B[2*gi + 1] :
                          /* MSB sign extension */   B[WIDTH-1];

            booth_encoder #(.WIDTH(WIDTH)) u_enc (
                .group_idx (2'(gi)),
                .b_minus1  (b_m1),
                .b_i       (b_i_),
                .b_plus1   (b_p1),
                .neg       (neg[gi]),
                .two       (two[gi]),
                .one       (one[gi]),
                .zero      (zero[gi])
            );
        end
    endgenerate

    genvar pi;
    generate
        for (pi = 0; pi < NUM_PP; pi++) begin : gen_pp

            logic signed [WIDTH:0] mag;
            // One's complement or true value
            logic signed [WIDTH:0] raw_oc;  // before +neg correction
            // Sign-extended to PROD_W before shift
            logic signed [PROD_W-1:0] ext;

            always_comb begin
		logic signed [PROD_W-1:0] mag_ext;
                // 1. Magnitude selection
                if (zero[pi])
                    mag_ext = '0;
                else if (one[pi])
                    mag_ext = {{(PROD_W-WIDTH){A[WIDTH-1]}}, A};          // sign-extend A
                else // two[pi]
                    mag_ext = {{(PROD_W-WIDTH-1){A[WIDTH-1]}}, A, 1'b0};         // A << 1 (signed)

                // 2. Conditional one's-complement (neg correction via carry-in
                //    in the Dadda tree; here we fully negate for simplicity)
                if (neg[pi])
                    pp[pi] = -mag_ext;
                else
                    pp[pi] = mag_ext;


                // 4. Shift left by 2*pi (group position)
                pp[pi] = pp[pi] <<< (2 * pi);
            end
        end
    endgenerate

endmodule : partial_product_generator
