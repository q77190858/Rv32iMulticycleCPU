//写回阶段
`timescale 1ns/1ps
module WB (
    //输入
    input wb_enable,//写回使能(有的指令不需要写回寄存器文件 如分支jmp)
    input[31:0] alu_or_ia4,//可能是alu的运算结果或者是(jmp使用的)IAadd4
    input[31:0] data,//load从存储器读出的数据
    input is_load,//是否是load指令
    input[4:0] rd,//要写回的目的寄存器
    //输出
    output wb_enable_out;//直接将写回使能输出
    output wire[4:0] rd_out,//目的寄存器也直接输出
    output wire[31:0] wb_data//写回数据
);
    assign wb_enable_out=wb_enable;
    assign rd_out=rd;

    MUX mux (
        .select(is_load),
        .in0(alu_or_ia4),
        .in1(data),
        .out(wb_data)
    );
    
endmodule