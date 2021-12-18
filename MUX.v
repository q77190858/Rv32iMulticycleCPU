//二路选择器，select=0则选择in0,否则选择in1输出

`timescale 1ns/1ps
module MUX (
    input select,//选择信号
    input[31:0] in0,//0号输入
    input[31:0] in1,//1好输入
    output[31:0] out//输出
);
    assign out=select?in1:in0;

endmodule

module MUX_tb;
    reg select;
    reg[31:0] in0,in1;
    wire[31:0] out;
    MUX mux (
    .select(select),
    .in0(in0),
    .in1(in1),
    .out(out)
    );

    initial begin
        select<=0;
        in0<=0;
        in1<=1;
        #10 select<=1;
        #10 $stop;
    end
    
endmodule