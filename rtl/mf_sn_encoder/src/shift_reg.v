`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:20:16 09/01/2020 
// Design Name: 
// Module Name:    shift_reg 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module shift_reg(data_in,clk,rstn,reg_out
    );
	 
parameter DISPARITY_BITS = 8;
parameter REG_BITS = DISPARITY_BITS * 3;

input clk,rstn;
input [ DISPARITY_BITS - 1:0]  data_in;

output reg [REG_BITS - 1:0] reg_out;
reg [REG_BITS - 1:0] reg_outNxt;


always @(posedge clk) reg_out <= reg_outNxt;

always @(*) begin
	if(rstn == 0) reg_outNxt = 0;
	else begin
		reg_outNxt = reg_out >> DISPARITY_BITS;
		reg_outNxt[ REG_BITS - 1: (DISPARITY_BITS *2)] = data_in;



	end	




end


endmodule
