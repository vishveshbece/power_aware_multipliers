`timescale 1ns/1ps

module wallace_multiplier_16(

   input clk,
   input rst,

   input signed [15:0] A,
   input signed [15:0] B,
   
   output reg signed [31:0] P
);

wire signed [31:0] A_ext;
assign A_ext = {{16{A[15]}},A};

wire signed [31:0] pp [15:0];

genvar i;

generate
for(i=0;i<15;i=i+1) begin
   assign pp[i] = B[i] ? (A_ext <<< i) : 32'sd0;

end
endgenerate


assign pp[15] = B[15] ? -(A_ext <<< 15) : 32'sd0;


wire signed [31:0] s1 = pp[0]+pp[1];
wire signed [31:0] s2 = pp[2]+pp[3];
wire signed [31:0] s3 = pp[4]+pp[5];
wire signed [31:0] s4 = pp[6]+pp[7];
wire signed [31:0] s5 = pp[8]+pp[9];
wire signed [31:0] s6 = pp[10]+pp[11];
wire signed [31:0] s7 = pp[12]+pp[13];
wire signed [31:0] s8 = pp[14]+pp[15];


wire signed [31:0]  s9=s1+s2;
wire signed [31:0]  s10=s3+s4;
wire signed [31:0]  s11=s5+s6;
wire signed [31:0]  s12=s7+s8;


wire signed [31:0]  s13=s9+s10;
wire signed [31:0]  s14=s11+s12;

wire signed [31:0] result;
assign result=s13+s14;

always @(posedge clk or posedge rst)begin
  if(rst)
     P<=32'sd0;
  else
     P<= result;
end
endmodule












 
