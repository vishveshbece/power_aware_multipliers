`timescale 1ns/1ps

module booth_dadda_multiplier_16(

input clk,
input rst,

input  signed [15:0] A,
input  signed [15:0] B,
output reg signed [31:0] P

);

wire signed [31:0] pp0;
wire signed [31:0] pp1;
wire signed [31:0] pp2;
wire signed [31:0] pp3;
wire signed [31:0] pp4;
wire signed [31:0] pp5;
wire signed [31:0] pp6;
wire signed [31:0] pp7;

booth_pp_gen PPGEN(

.A(A),
.B(B),

.pp0(pp0),
.pp1(pp1),
.pp2(pp2),
.pp3(pp3),
.pp4(pp4),
.pp5(pp5),
.pp6(pp6),
.pp7(pp7)

);

/* Correct reduction */
always @(posedge clk or posedge rst)
begin

if(rst)
P<=0;

else 
P<=pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7;

end

endmodule
