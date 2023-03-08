`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/30 22:55:15
// Design Name: 
// Module Name: FP16_div_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FP16_div_tb(

    );
    reg clk;
    reg rst;
    reg input_valid;
    reg [15:0]data_dividend;
    reg [15:0]data_divisor;
    wire output_update;
    wire idle;
    wire [15:0]data_q;
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 1;
        rst = 1;
        input_valid = 0;
        data_dividend = 16'h5543;//84.1875 / 1.626953 = 0x5278£¬pass
        data_divisor = 16'h3e82;
//        data_dividend = 16'h5543;   //84.1875 / 0.000801 = overflow(0x7fff),pass
//        data_divisor = 16'h128f;
        //data_dividend = 16'hd543;   //-84.1875 / 0xffff = 0xffff,pass;
        //data_divisor = 16'hffff;
//        data_dividend = 16'hd543;   //-84.1875 / 2.529297 = 0xd029,pass
//        data_divisor = 16'h410f;
//        data_dividend = 16'h0001;
//        data_divisor = 16'h0001;
        #10 input_valid = 1;
        rst = 0;
        #11 input_valid = 0;
        #9
        #500
        input_valid = 1;
        data_dividend = 16'h0000;   //0x0000
        data_divisor = 16'h0001;
        #1
        input_valid = 0;
        #450
        rst = 1; 
    end
    
    FP16_div U1 (
    .clk(clk),
    .rst(rst),
    .input_valid(input_valid),
    .data_dividend(data_dividend),
    .data_divisor(data_divisor),
    .output_update(output_update),
    .idle(idle),
    .data_q(data_q)
    );
    
endmodule
