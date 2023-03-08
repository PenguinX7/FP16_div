`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/30 17:56:22
// Design Name: 
// Module Name: FP16_div
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


module FP16_div(
    input data_dividend,
    input data_divisor,
    input input_valid,
    input clk,
    input rst,
    output data_q,
    output output_update,
    output idle
    );
    
    wire [15:0]data_dividend;
    wire [15:0]data_divisor;
    wire input_valid;
    wire clk;
    wire rst;
    reg [15:0]data_q;
    reg output_update;
    reg idle;
    
    reg [2:0]state;
    reg overflow;
    reg sign_x;
    reg sign_d;
    reg sign_q;
    reg signed [6:0]exp_x;
    reg signed [6:0]exp_d;
    reg signed [6:0]exp_q;
    reg [44:0]rm_x;
//    reg [44:0]rm_x_cache1;
//    reg [44:0]rm_x_cache2;
    wire [44:0]rm_x_cache1;
    wire [44:0]rm_x_cache2;
    reg [43:0]rm_d;
    reg [11:0]rm_q;
    reg [11:0]rm_q_cache;
    reg round_flag;
    reg [5:0]n;
    reg debug;
    
    assign rm_x_cache1 = rm_x << 1;
    assign rm_x_cache2 = rm_x[44] ? rm_x_cache1 + rm_d : rm_x_cache1 - rm_d;
    
    always@(posedge clk or posedge rst) begin       //state control
        if(rst) begin
            state <= 3'd0;
        end
        else    begin
            case (state)
                3'd0 : begin               //input_check =>E,S,cal
                    if(input_valid)
                        state <= 1;
                    else
                        state <= 0;
                end
                3'd1 : begin               //E,S,cal =>output or M,cal
                    if(overflow)
                        state <= 6;
                    else
                        state <= 2;
                end
                3'd2 : begin               //M,cal
                    if(n == 0)
                        state <= 3;
                    else
                        state <= 2;
                end
                3'd3 : state <= 4;         //nor_pre =>denormal_operation
                3'd4 : state <= 5;         //denormal_operation =>round and carry
                3'd5 : state <= 6;         //round and carry =>output
                3'd6 : state <= 0;         //output =>idle
            endcase
        end
    end
    
    
    always@(posedge clk)    begin
      if(rst)   begin
        output_update <= 1'b0;
        idle <= 1'b0;
        data_q <= 16'h0000;
        overflow <= 1'b0;
        sign_x <= 1'b0;
        sign_d <= 1'b0;
        exp_x <= 0;
        exp_d <= 0;
        rm_d <= 44'd0;
        rm_x <= 45'd0;
        round_flag <= 1'b0;
        n <= 6'd32;
      end
      else  begin
        case(state)
            3'd0 : begin
                output_update <= 1'b0;
                if(input_valid) begin
                    idle <= 1'b0;
                    sign_x <= data_dividend[15];
                    rm_x <= data_dividend[9:0];
                    if(data_dividend[14:10] == 5'd0)    begin
                        if(data_dividend[9:0] == 10'd0) begin   //0
                            exp_x <= data_dividend[14:10];
                            rm_x[10] <= 1'b0;
                        end
                        else    begin                           //denormal
                            exp_x <= 7'd1;
                            rm_x[10] <= 1'b0;
                        end
                    end
                    else    begin                               //normal
                        exp_x <= data_dividend[14:10];
                        rm_x[10] <= 1'b1;
                    end
                    sign_d <= data_divisor[15];
                    rm_d  <= data_divisor[9:0];
                    if(data_divisor[14:10] == 5'd0)    begin
                        if(data_divisor[9:0] == 10'd0) begin   //0
                            exp_d <= data_divisor[14:10];
                            rm_d[10] <= 1'b0;
                            overflow <= 1'b1;
                        end
                        else    begin                           //denormal
                            exp_d <= 7'd1;
                            rm_d[10] <= 1'b0;
                            overflow <= 1'b0;
                        end
                    end
                    else    begin                               //normal
                        exp_d <= data_divisor[14:10];
                        rm_d[10] <= 1'b1;
                        overflow <= 1'b0;
                    end
                end
                else    begin
                    idle <= 1'b1;
                    sign_x <= sign_x;
                    exp_x <= exp_x;
                    rm_x <= rm_x;
                    sign_d <= sign_d;
                    exp_d <= exp_d;
                    rm_d <= rm_d;
                    overflow <= overflow;
                end
            end
            3'd1 : begin
                exp_q <= exp_x - exp_d + 15;
                sign_q <= sign_x ^ sign_d;
                rm_x <= rm_x << 22;
                rm_d <= rm_d << 33;
                n <= 6'd32;
            end
            3'd2 : begin
//                if(rm_x[44])    begin
//                    rm_x_cache1 = rm_x << 1;
//                    rm_x_cache2 = rm_x_cache1 + rm_d;
//                end
//                else    begin
//                    rm_x_cache1 = rm_x << 1;
//                    rm_x_cache2 = rm_x_cache1 - rm_d;
//                end
//                if(rm_x_cache2[44]) begin
//                    debug <= 1'b1;
//                    rm_x[44:1] <= rm_x_cache2[44:1];
//                    rm_x[0] <= 1'b0;
//                end
//                else    begin
//                    debug <= 1'b0;
//                    rm_x[44:1] <= rm_x_cache2[44:1];
//                    rm_x[0] <= 1'b1;
//                end
                rm_x[44:1] <= rm_x_cache2[44:1];
                rm_x[0] <= ~rm_x_cache2[44];
                n <= n - 1;
            end
            3'd3 : begin
                casex(rm_x[32:0])
                    33'b1_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[32:22];
                        round_flag <= rm_x[21];
                        exp_q <= exp_q + 10;
                    end
                    33'b0_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[31:21];
                        round_flag <= rm_x[20];
                        exp_q <= exp_q + 9;
                    end
                    33'b0_01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[30:20];
                        round_flag <= rm_x[19];
                        exp_q <= exp_q + 8;
                    end
                    33'b0_001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[29:19];
                        round_flag <= rm_x[18];
                        exp_q <= exp_q + 7;
                    end
                    33'b0_0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[28:18];
                        round_flag <= rm_x[17];
                        exp_q <= exp_q + 6;
                    end
                    33'b0_0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[27:17];
                        round_flag <= rm_x[16];
                        exp_q <= exp_q + 5;
                    end
                    33'b0_0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[26:16];
                        round_flag <= rm_x[15];
                        exp_q <= exp_q + 4;
                    end
                    33'b0_0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[25:15];
                        round_flag <= rm_x[14];
                        exp_q <= exp_q + 3;
                    end
                    33'b0_0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[24:14];
                        round_flag <= rm_x[13];
                        exp_q <= exp_q + 2;
                    end
                    33'b0_0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[23:13];
                        round_flag <= rm_x[12];
                        exp_q <= exp_q + 1;
                    end
                    33'b0_0000_0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[22:12];
                        round_flag <= rm_x[11];
                        exp_q <= exp_q;
                    end
                    33'b0_0000_0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[21:11];
                        round_flag <= rm_x[10];
                        exp_q <= exp_q - 1;
                    end
                    33'b0_0000_0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[20:10];
                        round_flag <= rm_x[9];
                        exp_q <= exp_q - 2;
                    end
                    33'b0_0000_0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[19:9];
                        round_flag <= rm_x[8];
                        exp_q <= exp_q - 3;
                    end
                    33'b0_0000_0000_0000_01xx_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[18:8];
                        round_flag <= rm_x[7];
                        exp_q <= exp_q - 4;
                    end
                    33'b0_0000_0000_0000_001x_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[17:7];
                        round_flag <= rm_x[6];
                        exp_q <= exp_q - 5;
                    end
                    33'b0_0000_0000_0000_0001_xxxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[16:6];
                        round_flag <= rm_x[5];
                        exp_q <= exp_q - 6;
                    end
                    33'b0_0000_0000_0000_0000_1xxx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[15:5];
                        round_flag <= rm_x[4];
                        exp_q <= exp_q - 7;
                    end
                    33'b0_0000_0000_0000_0000_01xx_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[14:4];
                        round_flag <= rm_x[3];
                        exp_q <= exp_q - 8;
                    end
                    33'b0_0000_0000_0000_0000_001x_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[13:3];
                        round_flag <= rm_x[2];
                        exp_q <= exp_q - 9;
                    end
                    33'b0_0000_0000_0000_0000_0001_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[12:2];
                        round_flag <= rm_x[1];
                        exp_q <= exp_q - 10;
                    end
                    33'b0_0000_0000_0000_0000_0001_xxxx_xxxx_xxxx :begin
                        rm_q <= rm_x[11:1];
                        round_flag <= rm_x[0];
                        exp_q <= exp_q - 11;
                    end
                    default : begin
                        rm_q <= 12'd0;
                        round_flag <= 1'b0;
                        exp_q <= 0;
                    end
                endcase
            end
            3'd4 : begin
                if(exp_q < 1)   begin
                    case(exp_q) 
                        0 : begin
                            round_flag <= exp_q[0];
                            rm_q <= rm_q >> 1;
                        end
                        -1 : begin
                            round_flag <= exp_q[1];
                            rm_q <= rm_q >> 2;
                        end
                        -2 : begin
                            round_flag <= exp_q[2];
                            rm_q <= rm_q >> 3;
                        end
                        -3 : begin
                            round_flag <= exp_q[3];
                            rm_q <= rm_q >> 4;
                        end
                        -4 : begin
                            round_flag <= exp_q[4];
                            rm_q <= rm_q >> 5;
                        end
                        -5 : begin
                            round_flag <= exp_q[5];
                            rm_q <= rm_q >> 6;
                        end
                        -6 : begin
                            round_flag <= exp_q[6];
                            rm_q <= rm_q >> 7;
                        end
                        -7 : begin
                            round_flag <= exp_q[7];
                            rm_q <= rm_q >> 8;
                        end
                        -8 : begin
                            round_flag <= exp_q[8];
                            rm_q <= rm_q >> 9;
                        end
                        -9 : begin
                            round_flag <= exp_q[9];
                            rm_q <= rm_q >> 10;
                        end
                        -10 : begin
                            round_flag <= exp_q[10];
                            rm_q <= rm_q >> 11;
                        end
                        default : begin
                            round_flag <= 1'b0;
                            rm_q <= 12'd0;
                        end
                    endcase
                    exp_q <= 0;
                end
                else    begin
                    exp_q <= exp_q;
                    rm_q <= rm_q;
                    round_flag <= round_flag;
                end
            end
            3'd5 : begin
                rm_q_cache = rm_q + round_flag;
                if(exp_q == 0)  begin
                    rm_q <= rm_q_cache;
                    if(rm_q_cache[10])   //denormal to normal
                        exp_q <= 1;
                    else
                        exp_q <= exp_q;
                end
                else    begin
                    if(rm_q_cache[11])  begin   //normal
                        exp_q <= exp_q + 1;
                        rm_q <= rm_q_cache >> 1;
                    end
                    else    begin
                        exp_q <= exp_q;
                        rm_q <= rm_q_cache;
                    end
                end
            end
            3'd6 : begin
                if((exp_q > 30) || overflow)
                    data_q <= {sign_q,15'h7bff};
                else if(rm_q == 12'd0)
                    data_q <= 16'h0000;
                else
                    data_q <= {sign_q,exp_q[4:0],rm_q[9:0]};
                output_update <= 1'b1;
                idle <= 1'b1;
            end
        endcase
      end
    end
    
endmodule
