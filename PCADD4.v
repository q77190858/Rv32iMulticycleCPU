`timescale 1ns/1ps

module PCADD4 (
    input[31:0] pc,//输入的PC值
    output reg[31:0] result//输出PC+4
);
    initial begin
        result<=0;
    end
    always @(*) begin
        result=pc+4;
    end
    
endmodule