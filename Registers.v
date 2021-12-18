//寄存器文件 32个32位寄存器,其中reg[0]始终为0
`timescale 1ns/1ps
`include "control_op_def.v"
module Registers (
    input clk,//时钟信号
    input reset,//复位信号
    input[4:0] rs1,//源1寄存器ID
    input[4:0] rs2,//源2寄存器ID
    input[4:0] rd,//目的寄存器ID
    input[2:0] wb_op,//写回操作码 0-4:可写回数据 5-7:只读
    input[31:0] wb_data,//写回rd的数据
    output reg[31:0] rs1_val,//源1寄存器的值
    output reg[31:0] rs2_val//源2寄存器的值
);

    reg[31:0] regs[0:31];//寄存器数组

    integer i;
    initial begin
        rs1_val<=0;
        rs2_val<=0;
        //寄存器数组初始化0
        for (i = 0;i<32 ; i=i+1) begin
            regs[i]=0;
        end
    end

    always @(posedge clk or negedge reset) begin
        if(~reset)begin
            rs1_val<=0;
            rs2_val<=0;
            //寄存器数组初始化0
            for (i = 0;i<32 ; i=i+1) begin
                regs[i]=0;
            end
        end
        else begin
            //写数据
            if(wb_op<=4)regs[rd]<=wb_data;
            //读数据
            rs1_val<=rs1==0?0:regs[rs1];//0号寄存器始终为零
            rs2_val<=rs2==0?0:regs[rs2];//0号寄存器始终为零
        end
    end
endmodule

module Registers_tb;
    reg clk,reset;
    reg[4:0] rs1,rs2,rd;
    reg[2:0] wb_op;
    reg[31:0] wb_data;
    wire[31:0] rs1_val,rs2_val;
    Registers registers (
        .clk(clk),
        .reset(reset),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wb_op(wb_op),
        .wb_data(wb_data),
        .rs1_val(rs1_val),
        .rs2_val(rs2_val)
    );

    initial begin
        clk<=0;reset<=0;
        wb_op<=0;
        rs1<=0;rs2<=0;rd<=20;
        wb_data<=32'h55;
        #17 reset<=1;
        #10 wb_op<=1;wb_data<=32'hf5;rd<=10;
        #10 rs1<=20;
        #10 rs2<=10;
        #50 $stop;
    end

    always #5 clk<=~clk;
    
endmodule