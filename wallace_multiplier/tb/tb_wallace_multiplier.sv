`timescale 1ns/1ps

module multiplier_tb;

/* Testbench Signals */
reg clk;
reg rst;

reg signed [15:0] A;
reg signed [15:0] B;

wire signed [31:0] P;

integer i;
reg signed [31:0] expected;


/* DUT Instantiation */

wallace_multiplier_16 DUT(
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B),
    .P(P)
);

/*CLOCK*/ 

initial begin
   clk=0;
   forever #5 clk=~clk;
end

initial begin
           $monitor("time=%0t A=%d B=%d P=%d Expected=%d",$time,A,B,P,expected);           
end

/* Test */
initial begin
  rst = 1;
  A=0; 
  B=0;

  #20;
  rst=0;

  for(i=0;i<1000;i=i+1) begin
           A=$random;
           B=$random;


           @(posedge clk); //capture input
           expected = A * B;
           @(posedge clk); //register update

           if(P !== expected) begin
                $display("ERROR A=%d B=%d P=%d Expected=%d",A,B,P,expected);
                $stop;
           end

       end
  $display("WALLACE MULTIPLIER TEST PASSED");
  $finish;

end
endmodule

