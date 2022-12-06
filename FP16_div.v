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
    reg [1:0]state_QSD;
    reg overflow;
    reg sign_x;
    reg sign_d;
    reg sign_q;
    reg signed [6:0]exp_x;
    reg signed [6:0]exp_d;
    reg signed [6:0]exp_q;
    reg signed [33:0]rm_x;
    reg signed [33:0]rm_d;
    reg signed [32:0]threshold;
    reg signed [11:0]rm_q;
    reg [4:0]n;
    
    always@(posedge clk or posedge rst) begin       //state control
        if(rst) begin
            state <= 3'd0;
        end
        else    begin
            case (state)
                3'd0 : state <= 3'd1;            //rst
                3'd1 : begin            //idle
                    if(input_valid)
                        state <= 3'd2;
                    else
                        state <= 3'd1;
                end
                3'd2 : state <= 3'd3;            //input check
                3'd3 : begin            //cal sign,exp
                    if(overflow)
                        state <= 3'd7;
                    else
                        state <= 3'd4;
                end 
                3'd4 : state <= 3'd5;            //cal rm,1
                3'd5 : begin            //cal rm,2
                    if(n == 5'd21)
                        state <= 3'd6;
                    else 
                        state <= 3'd4;
                end
                3'd6 : state <= 3'd7;           //normalize
                3'd7 : state <= 3'd1;             //output
                default : state <= 3'd0;
            endcase
        end
    end
    
    always@(state)  begin           //overflow
        case(state) 
            3'd0 : overflow = 1'b0;
            3'd2 : begin
                if((data_divisor[14:0] == 15'd0) || (data_divisor[14:10] == 5'b11111) || (data_dividend[14:10] == 5'b11111))
                    overflow = 1'b1;
                else
                    overflow = 1'b0;
            end
            default : overflow = overflow;    
        endcase
    end
    
    always@(state)  begin           //state_QSD
        case(state)
            3'd0 : state_QSD = 2'b0;
            3'd4 : begin
                if(rm_x < (-1 * threshold)) begin
                    state_QSD = 2'd0;
                end
                else if(rm_x > threshold)   begin
                    state_QSD = 2'd1;
                end
                else    begin
                    state_QSD = 2'd2;
                end
            end
            default : state_QSD = state_QSD;
        endcase
    end
    
    always@(state)  begin           //sign_x
        case(state)
            3'd0 : sign_x = 1'b0;
            3'd2 : sign_x = data_dividend[15];
            default : sign_x = sign_x;
        endcase
    end
    
    always@(state) begin            //sign_d
        case(state)
            3'd0 : sign_d = 1'b0;
            3'd2 : sign_d = data_divisor[15];
            default : sign_d = sign_d;
        endcase
    end
    
    always@(state) begin            //sign_q
        case(state)
            3'd0 : sign_q = 1'b0;
            3'd3 : sign_q = sign_d ^ sign_x;
            default : sign_q = sign_q;
        endcase
    end
    
    always@(state) begin            //exp_x
        case(state)
            3'd0 : exp_x = 7'd0;
            3'd2 : exp_x = data_dividend[14:10];
            default : exp_x = exp_x;
        endcase
    end
    
    always@(state) begin            //exp_x
        case(state)
            3'd0 : exp_x = 7'd0;
            3'd2 : exp_x = data_dividend[14:10];
            default : exp_x = exp_x;
        endcase
    end
    
    always@(state) begin            //exp_d
        case(state)
            3'd0 : exp_d = 7'd0;
            3'd2 : exp_d = data_divisor[14:10];
            default : exp_d = exp_d;
        endcase
    end
    
    always@(state) begin            //exp_q
        case(state)
            3'd0 : exp_q = 7'd0;
            3'd3 : exp_q = exp_x - exp_d + 7'd15;
            3'd6 : begin
                if(rm_q[10])
                    exp_q = exp_q;
                else if(rm_q[9])
                    exp_q = exp_q - 7'd1;
                else
                    exp_q = 7'd0;
            end
            default : exp_q = exp_q;
        endcase
    end
    
    always@(state) begin            //rm_x
        case(state)
            3'd0 : rm_x = 23'd0;
            3'd2 : begin
                if((data_divisor[14:0] == 15'd0) || (data_divisor[14:10] == 5'b11111) || (data_dividend[14:10] == 5'b11111))
                    rm_x = rm_x;
                else if(data_dividend[14:0] == 15'd0)
                    rm_x = 23'd0;
                else
                    rm_x = {1'b1,data_dividend[9:0],10'd0};
            end
            3'd4 : rm_x = rm_x <<< 1;
            3'd5 : begin
                case(state_QSD)
                    2'd0 : rm_x = rm_x + rm_d;
                    2'd1 : rm_x = rm_x - rm_d;
                    2'd2 : rm_x = rm_x;
                    default : rm_x = rm_x;
                endcase
            end
            default : rm_x = rm_x;
        endcase
    end
    
    always@(state) begin            //rm_d
        case(state)
            3'd0 : rm_d = 34'd0;
            3'd2 : begin
                if((data_divisor[14:0] == 15'd0) || (data_divisor[14:10] == 5'b11111) || (data_dividend[14:10] == 5'b11111))
                    rm_d = rm_d;
                else    begin
                    rm_d = {1'b1,data_divisor[9:0],21'd0};
                end
            end
            default : rm_d = rm_d;
        endcase
    end
    
    always@(state) begin            //threshold
        case(state)
            3'd0 : threshold = 33'd0;
            3'd2 : begin
                if((data_divisor[14:0] == 15'd0) || (data_divisor[14:10] == 5'b11111) || (data_dividend[14:10] == 5'b11111))
                    threshold = threshold;
                else
                    threshold = {1'b1,data_divisor[9:0],20'd0};
            end
            default : threshold = threshold;
        endcase
    end
    
    always@(state) begin            //rm_q
        case(state)
            3'd0 : rm_q = 12'd0;
            3'd4 : rm_q = rm_q <<< 1;
            3'd5 : begin
                case(state_QSD)
                    2'd0 : rm_q = rm_q - 12'd1;
                    2'd1 : rm_q = rm_q + 12'd1;
                    2'd2 : rm_q = rm_q;
                    default : rm_q = rm_q;
                endcase
            end
            3'd6 : begin
                if(rm_q[10])
                    rm_q = rm_q;
                else if(rm_q[9])
                    rm_q = rm_q << 1;
                else
                    rm_q = 12'd0;
            end
            default : rm_q = rm_q;
        endcase
    end
    
    always@(state) begin            //n
        case(state)
            3'd0 : n = 5'd0;
            3'd1 : n = 5'd0;
            3'd4 : n = n + 1;
            default : n = n;
        endcase
    end
    
    always@(state) begin            //idle
        case(state)
            3'd0 : idle = 1'b1;
            3'd1 : idle = 1'b1;
            3'd2 : idle = 1'b0;
            3'd7 : idle = 1'b1;
            default : idle = idle;
        endcase
    end
    
    always@(state) begin            //output_update
        case(state)
            3'd7 : output_update = 1'b1;
            3'd0 : output_update = 1'b0;
            3'd1 : output_update = 1'b0;
            default : output_update = output_update;
        endcase
    end
    
    always @(state) begin
        case(state)
            3'd0 : data_q = 16'd0;
            3'd7 :  begin
                if(overflow || (exp_q > 30))
                    data_q = {sign_q,15'h7fff};
                else if((exp_q < 1) || (rm_q == 12'd0))
                    data_q = 16'd0;
                else
                    data_q = {sign_q,exp_q[4:0],rm_q[9:0]};
            end
            default : data_q = data_q;
        endcase
    end
    
endmodule
