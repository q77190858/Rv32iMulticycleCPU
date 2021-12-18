//访存阶段
`timescale 1ns/1ps
module MEM (
    //输入
    input clk,//时钟信号
    input reset,//复位信号
    input jmp,//是否为无条件跳转指令
    input[2:0] mem_op,//数据存储器操作码
    input[31:0] ia_add4,//当前指令地址+4的值
    input[31:0] alu_result,//ALU计算结果
    input[31:0] rs2_val,//源2寄存器的值，store用来写入数据存储器
    input comp_result,//比较器比较结果
    input[4:0] rd,//目的寄存器id
    input wb_enable,//写回使能
    //输出
    output wire is_bj,//是否是branch或者jmp指令,控制多路选择器
    output wire[31:0] bj_addr,//branch或者jmp指令的跳转目的地址
    output reg[31:0] alu_or_ia4,//alu结果或者是当前指令地址+4的值
    output reg[31:0] data,//数据存储器读出的数据
    output reg is_load,//是否是load指令
    output reg[4:0] rd_out,//目的寄存器id，直接输出
    output reg wb_enable_out//写回使能直接传递
);
    assign is_bj=jmp | comp_result;
    assign bj_addr=alu_result;
    assign rd_out=rd;
    
    DM_1M dm_1m (
        .clk(clk),
        .reset(reset),
        .addr(alu_result),
        .data_in(rs2_val),
        .mem_op(mem_op),
        .data_out(data),
        .is_load(is_load)
    );

    MUX mux (
        .select(jmp),
        .in0(alu_result),
        .in1(ia_add4),
        .out(alu_or_ia4)
    );
endmodule