`timescale 1ns/1ps
module tb_top;

    localparam int WIDTH  = 16;
    localparam int PROD_W = 32;

    // DUT signals
    logic clk;
    logic rst_n;
    logic valid_in, valid_out;
    logic ready_out;
    logic [WIDTH-1:0] operand_a, operand_b;
    logic [PROD_W-1:0] product;

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instance
    multiplier_top #(
        .WIDTH(WIDTH),
        .PROD_W(PROD_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .product(product),
        .valid_out(valid_out)
    );

    // Task: Apply one input
    task automatic apply_input(input logic signed [WIDTH-1:0] a,
                               input logic signed [WIDTH-1:0] b,
                               output bit passed);
        logic signed [PROD_W-1:0] exp;
        begin
            @(posedge clk);
            while (!ready_out) @(posedge clk);

            operand_a <= a;
            operand_b <= b;
            valid_in  <= 1;
            @(posedge clk);
            valid_in  <= 0;

            @(posedge clk);
            while (!valid_out) @(posedge clk);

            exp = $signed(a) * $signed(b);

            if (product === exp) passed = 1;
            else passed = 0;
        end
    endtask

    // Main testbench
    integer block, ia, ib;
    integer pass_count, fail_count;
    integer file_fail, file_main;
    logic passed;
    integer block_size;
    logic signed [WIDTH-1:0] start_a, end_a;

    initial begin
        // Reset
        rst_n = 0;
        valid_in = 0;
        operand_a = 0;
        operand_b = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Open main log
        file_main = $fopen("main_log.txt", "w");
        $fdisplay(file_main, "==== Multiplier Test Report ====");

        block_size = (2**WIDTH)/10000; // ~3276 values per block

        // Loop over 20 blocks
        for (block = 5000; block < 5500; block++) begin
            pass_count = 0;
            fail_count = 0;

            start_a = -32768 + block*block_size;
            end_a   = start_a + block_size - 1;
            // Open temporary fail log
            file_fail = $fopen($sformatf("fail_block_%0d.log", block), "w");

            for (ia = start_a; ia <= end_a; ia++) begin
                for (ib = -32768; ib <= 32767; ib++) begin
                    apply_input(ia, ib, passed);
                    if (passed) begin
			 pass_count++;
			$fdisplay(file_fail,"pass");
		    end
                    else begin
                        fail_count++;
                        $fdisplay(file_fail, "FAIL: A=%0d B=%0d Got=%0d Exp=%0d",
                                  ia, ib, $signed(product), $signed($signed(ia)*$signed(ib)));
                    end
                end
            end

            $fclose(file_fail); // Close temp fail file

            // Append block summary to main log
            $display("Block %0d: PASS=%0d, FAIL=%0d", block, pass_count, fail_count);

            // Optional: delete fail file after reading
            $system($sformatf("rm -f fail_block_%0d.log", block));
        end

        $fdisplay(file_main, "==== End of Test ====");
        $fclose(file_main);

        $display("All blocks done. See main_log.txt for summary.");
        $finish;
    end
endmodule
