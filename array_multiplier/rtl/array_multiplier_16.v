`timescale 1ns/1ps

module array_multiplier_16(

input clk,
input rst,

input signed [15:0] A,
input signed [15:0] B,
output reg signed [31:0] P
 
);

reg signed [31:0] mult_result;

always @(*) begin
  mult_result=A*B;
end

always @(posedge clk or posedge rst) begin
  if(rst)
    P <= 0;
  else
    P <= mult_result;
end

endmodule


