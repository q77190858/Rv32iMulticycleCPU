//RISCV CPU
`timescale 1ns/1ps
`include "PC.v"
`include "IM_1M.v"
`include "PCADD4.v"
`include "MUX.v"
`include "Decoder.v"
`include "Registers.v"
`include "ALU.v"
`include "Compare.v"
`include "DM_1M.v"
`include "MUX8.v"

module RISCV_CPU (
    input clk,
    input reset
);
    wire[31:0] mux_pc_out;//PC寄存器对应多路选择器输出
    wire is_bj;//是否需要分支或jmp
    wire bj_finish;//是分支或jmp指令且已经执行完毕（无论是否跳转）
    wire[31:0] bj_addr;//分支jmp地址
    wire[31:0] ia;//指令地址
    reg[31:0] ia_ID;//译码阶段的 指令地址
    wire[31:0] ia_add4;//指令地址加4
    reg[31:0] ia_add4_ID;//译码阶段的 指令地址加4
    reg[31:0] ia_add4_EX;//执行阶段的 指令地址加4
    reg[31:0] ia_add4_MEM;//访存阶段的 指令地址加4
    wire[31:0] ir;//指令内容
    wire[31:0] ir_ID;//译码阶段的 ir连线

    wire[3:0] alu_op;//ALU操作码
    wire[2:0] comp_op;//比较器操作码
    wire[3:0] mem_op;//数据存储器操作码
    reg[3:0] mem_op_EX;//执行阶段的 数据存储器操作码
    wire[2:0] wb_op;//写回操作码
    reg[2:0] wb_op_EX;//执行阶段 写回操作码
    reg[2:0] wb_op_MEM;//访存阶段 写回操作码
    wire select1;//0：选择IA 1：选择rs1_val 作为alu的第1个运算数
    wire select2;//0：选择rs2_val 1:选择对应的立即数 作为alu的第2个运算数
    wire[31:0] imm_ext_32;//扩展到32位的立即数
    reg[31:0] imm_ext_32_EX;//执行阶段 扩展到32位的立即数
    reg[31:0] imm_ext_32_MEM;//访存阶段 扩展到32位的立即数
    wire jmp;//是否是无条件跳转指令
    reg jmp_EX;//执行阶段的 是否是无条件跳转指令
    wire branch;//是否是分支指令
    reg branch_EX;//执行阶段 是否是分支指令

    wire[31:0] wb_data;//要写回目的寄存器的数据

    wire[31:0] rs1_val;//源1寄存器的值
    wire[31:0] rs2_val;//源2寄存器的值
    reg[31:0] rs2_val_EX;//执行阶段的 源2寄存器的值
    reg[4:0] rd;//(可能的)目的寄存器ID
    reg[4:0] rd_EX;//执行阶段的 (可能的)目的寄存器ID
    reg[4:0] rd_MEM;//访存阶段的 (可能的)目的寄存器ID

    wire[31:0] alu_rand1;//alu的两个输出数据
    wire[31:0] alu_rand2;
    wire[31:0] comp_rand2;//比较器输入数2
    wire[31:0] alu_result;//ALU计算结果
    reg[31:0] alu_result_MEM;//访存阶段 ALU计算结果
    wire[31:0] comp_result;//比较器比较结果
    reg[31:0] comp_result_MEM;//访存阶段 比较器比较结果
    wire[31:0] data;//数据存储器读出的数据

    wire[4:0] rs1,rs2;

    wire[1:0] stall_op;//stall指令

    assign ir_ID=stall_op!=0?0:ir;//如果stall,则传入ID阶段的指令为0

    assign rs1=ir_ID[19:15];
    assign rs2=ir_ID[24:20];
    assign is_bj=jmp_EX | (branch_EX && comp_result==1);
    assign bj_finish=jmp_EX | branch_EX;
    assign bj_addr=alu_result;

    PC pc(
        .clk(clk),
        .reset(reset),
        .stall_op(stall_op),
        .result(mux_pc_out),
        .addr(ia)
    );
    IM_1M im_1m(
        .reset(reset),
        .addr(ia),
        .data_out(ir)
    );
    PCADD4 pcadd4 (
        .pc(ia),
        .result(ia_add4)
    );
    MUX mux_pc (
        .select(is_bj),
        .in0(ia_add4),
        .in1(bj_addr),
        .out(mux_pc_out)
    );
    Decoder decoder (
    .clk(clk),
    .reset(reset),
    .ir(ir_ID),
    .wb_op2(wb_op_MEM),
    .is_bj(is_bj),
    .bj_finish(bj_finish),
    .wb_rd(rd_MEM),
    .alu_op(alu_op),
    .comp_op(comp_op),
    .mem_op(mem_op),
    .wb_op(wb_op),
    .select1(select1),
    .select2(select2),
    .imm_ext_32(imm_ext_32),
    .jmp(jmp),
    .branch(branch),
    .stall_op(stall_op)
    );
    Registers registers (
    .clk(clk),
    .reset(reset),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd_MEM),
    .wb_op(wb_op_MEM),
    .wb_data(wb_data),
    .rs1_val(rs1_val),
    .rs2_val(rs2_val)
    );
    MUX mux1 (
        .select(select1),
        .in0(ia_ID),
        .in1(rs1_val),
        .out(alu_rand1)
    );
    MUX mux2 (
        .select(select2),
        .in0(rs2_val),
        .in1(imm_ext_32),
        .out(alu_rand2)
    );
    MUX mux_comp (
        .select(select2),
        .in0(imm_ext_32),
        .in1(rs2_val),
        .out(comp_rand2)
    );
    ALU alu (
        .clk(clk),
        .reset(reset),
        .oprand1(alu_rand1),
        .oprand2(alu_rand2),
        .alu_op(alu_op),
        .result(alu_result)
    );
    Compare compare (
        .clk(clk),
        .reset(reset),
        .rs1_val(rs1_val),
        .rs2_val(comp_rand2),
        .comp_op(comp_op),
        .result(comp_result)
    );
    DM_1M dm_1m (
        .clk(clk),
        .reset(reset),
        .addr(alu_result),
        .data_in(rs2_val_EX),
        .mem_op(mem_op_EX),
        .data_out(data)
    );
    MUX8 mux8 (
        .select(wb_op_MEM),
        .in0(alu_result_MEM),
        .in1(ia_add4_MEM),
        .in2(comp_result_MEM),
        .in3(data),
        .in4(imm_ext_32_MEM),
        .in5(7),
        .in6(7),
        .in7(7),
        .out(wb_data)
    );

    initial begin
        ia_ID<=0;
        ia_add4_ID<=0;
        ia_add4_EX<=0;
        ia_add4_MEM<=0;
        mem_op_EX<=0;
        wb_op_EX<=0;
        wb_op_MEM<=0;
        imm_ext_32_EX<=0;
        imm_ext_32_MEM<=0;
        jmp_EX<=0;
        branch_EX<=0;
        rs2_val_EX<=0;
        rd<=0;
        rd_EX<=0;
        rd_MEM<=0;
        alu_result_MEM<=0;
        comp_result_MEM<=0;
    end

    always @(posedge clk or negedge reset) begin
        if(~reset)begin
            ia_ID<=0;
            ia_add4_ID<=0;
            ia_add4_EX<=0;
            ia_add4_MEM<=0;
            mem_op_EX<=0;
            wb_op_EX<=`WBOP_NON;
            wb_op_MEM<=`WBOP_NON;
            imm_ext_32_EX<=0;
            imm_ext_32_MEM<=0;
            jmp_EX<=0;
            branch_EX<=0;
            rs2_val_EX<=0;
            rd<=0;
            rd_EX<=0;
            rd_MEM<=0;
            alu_result_MEM<=0;
            comp_result_MEM<=0;
        end
        else begin
            if(stall_op==0)begin
                ia_ID<=ia;
                ia_add4_ID<=ia_add4;
            end
            ia_add4_EX<=ia_add4_ID;
            ia_add4_MEM<=ia_add4_EX;
            mem_op_EX<=mem_op;
            wb_op_EX<=wb_op;
            wb_op_MEM<=wb_op_EX;
            imm_ext_32_EX<=imm_ext_32;
            imm_ext_32_MEM<=imm_ext_32_EX;
            jmp_EX<=jmp;
            branch_EX<=branch;
            rs2_val_EX<=rs2_val;
            rd<=ir_ID[11:7];
            rd_EX<=rd;
            rd_MEM<=rd_EX;
            alu_result_MEM<=alu_result;
            comp_result_MEM<=comp_result;
        end
    end
endmodule

module RISCV_CPU_tb;
    reg clk,reset;
    RISCV_CPU cpu (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        clk<=0;reset<=0;
        #7 reset<=1;
        #200 $stop;
    end

    always #5 clk=~clk;
    
endmodule