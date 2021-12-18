//译码阶段，立即数功能未模块化直接写在里面了
`timescale 1ns/1ps
module ID (
    //输入
    input clk,
    input reset,
    input[31:0] ia,
    input[31:0] ia_add4,
    input[31:0] ir,
    input[4:0] wb_rd,
    input[31:0] wb_data,
    //输出
    output reg[31:0] ia_out,
    output reg[31:0] rs1_val,
    output reg[31:0] rs2_val,
    output reg[31:0] imm11_0,
    output reg[31:0] shamt,
    output reg[31:0] imm_11_0_store,
    output reg[31:0] imm_12_1,
    output reg[31:0] imm_20_1,
    output reg[31:0] imm_31_12,
    output reg[4:0] rd,
    output reg[2:0] alu_op,
    output reg[2:0] comp_op,
    output reg[2:0] mem_op,
    output reg select1,
    output reg[2:0] select2,
    output reg jmp,//是否是无条件跳转指令
    output reg wb_enable//写回使能
);
    wire[4:0] rs1;
    wire[4:0] rs2;

    //将rs1,rs2,rd从ir特定位数取出
    assign rs1=ir[19:15];
    assign rs2=ir[24:20];
    assign rd=ir[11:7];
    //立即数全部扩展为32位
    assign imm11_0={20{ir[31]},ir[31:20]};
    assign shamt={27{1'b0},ir[24:20]};
    assign imm_11_0_store={20{ir[31]},ir[31:25],ir[11:7]};
    assign imm_12_1={20{ir[31]},ir[7],ir[30:25],ir[11:8],1'b0};
    assign imm_20_1={12{ir[31]},ir[19:12],ir[20],ir[30:21],1'b0};
    assign imm_31_12={ir[31:12],12{1'b0}};

    Decoder decoder (
    .clk(clk),
    .reset(reset),
    .ir(ir),
    .alu_op(alu_op),
    .comp_op(comp_op),
    .select1(select1),
    .select2(select2),
    .jmp(jmp),
    .wb_enable(wb_enable)
    );
    Registers registers (
    .clk(clk),
    .reset(reset),
    .rs1(rs1),
    .rs2(rs2),
    .rd(wb_rd),
    .w_enable(wb_enable),
    .wb_data(wb_data),
    .rs1_val(rs1_val),
    .rs2_val(rs2_val)
    );

    //运行前初始化寄存器
    initial begin
        ia_out<=0;
        rs1_val<=0;
        rs2_val<=0;
        imm11_0<=0;
        shamt<=0;
        imm_11_0_store<=0;
        imm_12_1<=0;
        imm_20_1<=0;
        imm_31_12<=0;
        alu_op<=0;
        comp_op<=0;
        mem_op<=0;
        select1<=0;
        select2<=0;
    end

    //复位信号来了初始化
    always @(posedge clk or negedge reset) begin
        if(~reset)begin
            ia_out<=0;
            rs1_val<=0;
            rs2_val<=0;
            imm11_0<=0;
            shamt<=0;
            imm_11_0_store<=0;
            imm_12_1<=0;
            imm_20_1<=0;
            imm_31_12<=0;
            alu_op<=0;
            comp_op<=0;
            mem_op<=0;
            select1<=0;
            select2<=0;
        end
    end
endmodule