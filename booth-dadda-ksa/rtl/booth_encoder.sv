`timescale 1ns/1ps

module booth_encoder #(
    parameter int WIDTH = 16          // Multiplicand width (must be even)
) (
    // Radix-4 groups: 9 groups for 16-bit multiplier (bits + guard)
    input  logic [1:0] group_idx,     // Not used here; encoding is combinational
    input  logic       b_minus1,      // b[i-1]  (previous or 0 for group 0)
    input  logic       b_i,           // b[i]
    input  logic       b_plus1,       // b[i+1]
    // Encoded outputs
    output logic       neg,           // Negate partial product
    output logic       two,           // Magnitude = 2× multiplicand
    output logic       one,           // Magnitude = 1× multiplicand
    output logic       zero           // Magnitude = 0
);

    // -------------------------------------------------------------------------
    // Combinational Booth encoding
    // -------------------------------------------------------------------------
    always_comb begin
        // Default
        neg  = 1'b0;
        two  = 1'b0;
        one  = 1'b0;
        zero = 1'b0;

        unique case ({b_plus1, b_i, b_minus1})
            3'b000: zero = 1'b1;               //  0
            3'b001: one  = 1'b1;               // +M
            3'b010: one  = 1'b1;               // +M
            3'b011: two  = 1'b1;               // +2M
            3'b100: begin two = 1'b1; neg = 1'b1; end  // -2M
            3'b101: begin one = 1'b1; neg = 1'b1; end  // -M
            3'b110: begin one = 1'b1; neg = 1'b1; end  // -M
            3'b111: zero = 1'b1;               //  0
            default: zero = 1'b1;
        endcase
    end

    // -------------------------------------------------------------------------
    // Assertions (disabled when ENABLE_ASSERTIONS=0 via plusarg)
    // -------------------------------------------------------------------------
`ifdef ENABLE_SVA
    // Exactly one of {zero, one, two} must be set
    property p_one_hot_sel;
        @($global_clock) (zero + one + two) == 1;
    endproperty
    assert property (p_one_hot_sel)
        else $error("[BOOTH_ENC] Encoding one-hot violation: z=%0b o=%0b t=%0b",
                     zero, one, two);
`endif

endmodule : booth_encoder
