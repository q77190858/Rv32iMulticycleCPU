//ALU算术逻辑单元
`timescale 1ns/1ps
`include "control_op_def.v"
module ALU (
    input clk,//时钟信号
    input reset,//复位信号
    input[31:0] oprand1,//ALU第1个操作数
    input[31:0] oprand2,//ALU第2个操作数
    input[3:0] alu_op,//ALU运算操作码
    output reg[31:0] result//运算结果
);
    initial begin
        result<=0;
    end

    always @(posedge clk or negedge reset) begin
        if(~reset)begin
            result<=0;
        end
        else begin
            case(alu_op)
            `ALUOP_ADD:result<=oprand1 + oprand2;//add
            `ALUOP_SUB:result<=oprand1 - oprand2;//sub
            `ALUOP_AND:result<=oprand1 & oprand2;//and
            `ALUOP_OR:result<=oprand1 | oprand2;//or
            `ALUOP_XOR:result<=oprand1 ^ oprand2;//xor
            `ALUOP_SLL:result<=oprand1 << oprand2[4:0];//sll
            `ALUOP_SRL:result<=oprand1 >> oprand2[4:0];//srl
            `ALUOP_SRA:result<=oprand1 >>> oprand2[4:0];//sra
            `ALUOP_NON:result<=0;//not work
            default:result<=0;//not work
            endcase
        end
    end
endmodule

module ALU_tb;
    reg clk,reset;
    reg[31:0] oprand1;
    reg[31:0] oprand2;
    reg[3:0] alu_op;
    wire[31:0] result;
    ALU alu (
        .clk(clk),
        .reset(reset),
        .oprand1(oprand1),
        .oprand2(oprand2),
        .alu_op(alu_op),
        .result(result)
    );

    initial begin
        clk<=0;reset<=0;
        oprand1<=32'b11001010;
        oprand2<=32'b01011101;
        alu_op<=3'b000;
        #17 reset<=1;
        #5 alu_op<=3'b001;
        #5 alu_op<=3'b010;
        #5 alu_op<=3'b011;
        #5 alu_op<=3'b100;
        #5 alu_op<=3'b101;
        #5 alu_op<=3'b110;
        #5 alu_op<=3'b111;
        #10 $stop;
    end

    always #5 clk=~clk;
endmodule