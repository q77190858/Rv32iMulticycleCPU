//取指阶段
`timescale 1ns/1ps
module IF (
    //输入
    input clk,
    input reset,
    input is_bj,//是否需要分支或jmp
    input[31:0] bj_addr,//分支jmp地址
    //输出
    output[31:0] ia,//指令地址
    output[31:0] ia_add4,//指令地址加4
    output[31:0] ir//指令内容
);
    wire[31:0] mux_pc_out;//多路选择器输出
    PC pc(
        .clk(clk),
        .reset(reset),
        .result(mux_pc_out),
        .addr(ia)
    );
    IM_1M im_1m(
        .clk(clk),
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
endmodule

module IF_tb;
    reg clk,reset,is_bj;
    reg[31:0] bj_addr;
    wire[31:0] ia,ia_add4,ir;
    IF ins_fe (
        //输入
        .clk(clk),
        .reset(reset),
        .is_bj(is_bj),//是否需要分支或jmp
        .bj_addr(bj_addr),//分支jmp地址
        //输出
        .ia(ia),//指令地址
        .ia_add4(ia_add4),//指令地址加4
        .ir(ir)//指令内容
    );
    initial begin
        clk<=0;reset<=0;is_bj<=0;
        bj_addr<=0;
        #17 reset=1;
        #20
        #10 is_bj<=1;bj_addr<=0;
        #60 $stop;
    end
    always #5 clk<=~clk;
endmodule