

`timescale 1ns/1ps

module multiplier_top #(
    parameter int WIDTH  = 16,
    parameter int PROD_W = 2 * WIDTH    // 32
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  valid_in,
    output logic                  ready_out,
    input  logic [WIDTH-1:0]      operand_a,   // Multiplicand (signed)
    input  logic [WIDTH-1:0]      operand_b,   // Multiplier   (signed)
    output logic [PROD_W-1:0]     product,     // Signed result
    output logic                  valid_out    // Output valid
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam int NUM_PP = WIDTH / 2;

    // -------------------------------------------------------------------------
    // Internal wires
    // -------------------------------------------------------------------------
    logic signed [PROD_W-1:0] pp_array [NUM_PP];
    logic        [PROD_W-1:0] dadda_sum;
    logic        [PROD_W-1:0] dadda_carry;
    logic        [PROD_W-1:0] comb_product;

    // -------------------------------------------------------------------------
    // Partial product generation
    // -------------------------------------------------------------------------
    partial_product_generator #(
        .WIDTH  (WIDTH),
        .NUM_PP (NUM_PP),
        .PROD_W (PROD_W)
    ) u_ppg (
        .A   (operand_a),
        .B   (operand_b),
        .pp  (pp_array)
    );

    // -------------------------------------------------------------------------
    // Dadda reduction tree
    // -------------------------------------------------------------------------
    dadda_reduction_tree #(
        .WIDTH  (WIDTH),
        .NUM_PP (NUM_PP),
        .PROD_W (PROD_W)
    ) u_dadda (
        .pp_in     (pp_array),
        .sum_out   (dadda_sum),
        .carry_out (dadda_carry)
    );

    // -------------------------------------------------------------------------
    // Final Kogge-Stone adder
    // -------------------------------------------------------------------------
    final_adder #(
        .PROD_W (PROD_W)
    ) u_fa (
        .sum_in   (dadda_sum),
        .carry_in (dadda_carry),
        .result   (comb_product)
    );
    logic hold;

    assign ready_out = ~hold;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product   <= '0;
            valid_out <= 1'b0;
            hold      <= 1'b0;
        end else begin
            if (valid_in && ready_out) begin
                product   <= comb_product;
                valid_out <= 1'b1;
                hold      <= 1'b1;
            end else if (hold && !valid_in) begin
                // De-assert after one cycle (simple pulse model)
                valid_out <= 1'b0;
                hold      <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Concurrent Assertions
    // -------------------------------------------------------------------------
`ifdef ENABLE_SVA

    // 1. Reset correctness: product must be 0 after reset
    property p_reset_product;
        @(posedge clk) !rst_n |=> (product == '0);
    endproperty
    assert property (p_reset_product)
        else $error("[MULT] product not zero after reset at time %0t", $time);

    // 2. Reset: valid_out must be 0 after reset
    property p_reset_valid;
        @(posedge clk) !rst_n |=> (valid_out == 1'b0);
    endproperty
    assert property (p_reset_valid)
        else $error("[MULT] valid_out not de-asserted after reset at time %0t", $time);

    // 3. Valid/ready handshake: valid_out must follow accepted valid_in
    property p_valid_ready_handshake;
        @(posedge clk) disable iff (!rst_n)
        (valid_in && ready_out) |=> valid_out;
    endproperty
    assert property (p_valid_ready_handshake)
        else $error("[MULT] valid_out not set one cycle after accepted handshake");

    // 4. No unknown (X/Z) values on outputs when valid
    property p_no_x_product;
        @(posedge clk) disable iff (!rst_n)
        valid_out |-> !$isunknown(product);
    endproperty
    assert property (p_no_x_product)
        else $error("[MULT] X/Z on product when valid_out=1 at time %0t", $time);

    // 5. Product correctness (integer signed multiply reference)
    property p_product_correct;
        logic signed [PROD_W-1:0] exp;
        @(posedge clk) disable iff (!rst_n)
        (valid_in && ready_out,
            exp = signed'(operand_a) * signed'(operand_b))
        |=> (product == exp);
    endproperty
    assert property (p_product_correct)
        else $error("[MULT] Product mismatch at time %0t: got %0h", $time, product);

`endif

endmodule : multiplier_top
