//执行阶段
`timescale 1ns/1ps
module EX (
    //输入
    input clk,//时钟信号
    input reset,//复位信号
    input[31:0] ia,//当前指令地址,branch和auipc需要
    input[31:0] ia_add4,//当前指令地址+4,jmp需要
    input[31:0] rs1_val,//源1寄存器的值
    input[31:0] rs2_val,//源2寄存器的值
    input[31:0] imm11_0,//[11:0]格式的立即数,立即数加 判断 位运算 和load jalr指令使用
    input[31:0] shamt,//[4:0]格式的立即数,立即数移位指令使用
    input[31:0] imm_11_0_store,//[11:0]格式的立即数，store指令使用
    input[31:0] imm_12_1,//[12:1]格式的立即数,因为地址都是2byte倍数所以左移1位，branch指令使用
    input[31:0] imm_20_1,//[20:1]格式的立即数,jal使用，因为地址都是2byte倍数所以左移1位
    input[31:0] imm_31_12,//[31:12]格式的高20位立即数,低位补0，lui和auipc指令使用
    input[4:0] rd,//(可能的)目的寄存器ID
    input[2:0] alu_op,//ALU操作码
    input[2:0] comp_op,//比较器操作码
    input[2:0] mem_op,//数据存储器操作码
    input select1,//0：选择IA 1：选择rs1_val 作为alu的第1个运算数
    input[2:0] select2,//3位，0：选择rs2_val 其他：选择对应的立即数 作为alu的第2个运算数
    input jmp,//是否是跳转指令
    input wb_enable,//写回使能
    //输出
    output reg jmp_out,//是否是跳转指令,直接输出
    output reg[2:0] mem_op_out,//数据存储器操作码 直接输出
    output reg[31:0] ia_add4_out,//当前指令地址+4,jmp需要 直接输出
    output reg[31:0] alu_result,//ALU计算结果
    output reg[31:0] rs2_val_out,//源2寄存器的值，store用来写入数据存储器 直接输出
    output reg[31:0] comp_result,//比较器比较结果
    output reg[31:0] rd_out//(可能的)目的寄存器ID 直接输出
    output reg wb_enable_out//写回使能直接传递
);
    assign jmp_out=jmp;
    assign mem_op_out=mem_op;
    assign ia_add4_out=ia_add4;
    assign rs2_val_out=rs2_val;
    assign rd_out=rd;
    assign wb_enable_out=wb_enable;

    //内部变量 alu的两个输出数据
    wire[31:0] alu_rand1;
    wire[31:0] alu_rand2;

    MUX mux (
        .select(select1),
        .in0(ia),
        .in1(rs1_val),
        .out(alu_rand1)
    );
    MUX8 mux8 (
        .select(select2),
        .in0(rs2_val),
        .in1(imm11_0),
        .in2(shamt),
        .in3(imm_11_0_store),
        .in4(imm_12_1),
        .in5(imm_20_1),
        .in6(imm_31_12),
        .out(alu_rand2)
    );
    ALU alu (
        .oprand1(alu_rand1),
        .oprand2(alu_rand2),
        .alu_op(alu_op),
        .result(alu_result)
    );
    Compare compare (
        .rs1_val(rs1_val),
        .rs2_val(rs2_val),
        .comp_op(comp_op),
        .result(comp_result)
    );
    
endmodule