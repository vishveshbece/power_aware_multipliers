`timescale 1ns/1ps

module wallace_multiplier_16(

   input clk,
   input rst,

   input signed [15:0] A,
   input signed [15:0] B,
   
   output reg signed [31:0] P
);

wire [31:0] partial [15:0];
wire [31:0] result;
/*
integer i;

wire signed [31:0] A_ext;
wire signed [31:0] B_ext;


assign A_ext = {{16{A[15]}},A};
assign B_ext = {{16{B[15]}},B};

wire signed [31:0] pp [15:0];
*/
genvar k;

generate
for(k=0;k<16;k=k+1) begin
   assign partial[k] = B[k] ? (A <<< k) : 32'd0;

end
endgenerate


wire signed [31:0] s1,s2,s3,s4,s5,s6,s7,s8;


assign s1 = partial[0]+partial[1];
assign s2 = partial[2]+partial[3];
assign s3 = partial[4]+partial[5];
assign s4 = partial[6]+partial[7];
assign s5 = partial[8]+partial[9];
assign s6 = partial[10]+partial[11];
assign s7 = partial[12]+partial[13];
assign s8 = partial[14]+partial[15];

wire signed [31:0] s9,s10,s11,s12;


assign s9=s1+s2;
assign s10=s3+s4;
assign s11=s5+s6;
assign s12=s7+s8;


wire signed [31:0] s13,s14;

assign s13=s9+s10;
assign s14=s11+s12;
assign result=s13+s14;

always @(posedge clk or posedge rst)begin
  if(rst)
     P<=32'd0;
  else
     P<= result;
end
endmodule












 
