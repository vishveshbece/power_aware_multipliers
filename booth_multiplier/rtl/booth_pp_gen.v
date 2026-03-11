`timescale 1ns/1ps

module booth_pp_gen(

input signed [15:0] A,
input signed [15:0] B,

output signed [31:0] pp0,
output signed [31:0] pp1,
output signed [31:0] pp2,
output signed [31:0] pp3,
output signed [31:0] pp4,
output signed [31:0] pp5,
output signed [31:0] pp6,
output signed [31:0] pp7

);

wire signed [31:0] A_ext;
wire signed [17:0] B_ext;

assign A_ext = {{16{A[15]}},A};
assign B_ext = {B,1'b0};

function signed [31:0] booth;

input [2:0] code;
input signed [31:0] x;

begin

case(code)

3'b000 : booth = 0;
3'b001 : booth = x;
3'b010 : booth = x;
3'b011 : booth = x << 1;
3'b100 : booth = -(x << 1);
3'b101 : booth = -x;
3'b110 : booth = -x;
3'b111 : booth = 0;

endcase

end
endfunction

assign pp0 = booth(B_ext[2:0],A_ext) << 0;
assign pp1 = booth(B_ext[4:2],A_ext) << 2;
assign pp2 = booth(B_ext[6:4],A_ext) << 4;
assign pp3 = booth(B_ext[8:6],A_ext) << 6;
assign pp4 = booth(B_ext[10:8],A_ext) << 8;
assign pp5 = booth(B_ext[12:10],A_ext) << 10;
assign pp6 = booth(B_ext[14:12],A_ext) << 12;
assign pp7 = booth(B_ext[16:14],A_ext) << 14;

endmodule
