`timescale 1ns / 1ps

module PC(
    input clk,//时钟信号
    input reset,//复位信号
    input[1:0] stall_op,//stall操作码
    input[31:0] result,//输入地址
    output reg[31:0] addr//保存并输出的地址
);

    reg[31:0] addr_prev;
    initial begin
        addr<=0;
        addr_prev<=0;
    end

    always @(posedge clk or negedge reset) begin
        if(~reset)begin
            addr<=0;
            addr_prev<=0;
        end
        else begin
            case(stall_op)
            2'd0:begin
                addr_prev<=addr;
                addr<=result;
            end
            2'd1:begin
                addr<=addr_prev;
            end
            endcase
        end
    end
endmodule

module PC_tb;
    reg clk;
    reg reset;
    reg[31:0] result;
    wire[31:0] addr;
    PC pc(
        .clk(clk),
        .reset(reset),
        .result(result),
        .addr(addr)
    );
    initial begin
        clk<=0;reset<=0;result<=0;
        #17 reset<=1;
        #10 result<=32'hff550055;
        #10 result<=0;
        #50 $stop;
    end

    always #5 clk=~clk;
    
endmodule