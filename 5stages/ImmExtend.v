//立即数提取和扩展到32位
`timescale 1ns/1ps
module ImmExtend (
    input reset,
    input[31:0] ir,
    output reg[31:0] imm11_0,
    output reg[31:0] shamt,
    output reg[31:0] imm_11_0_store,
    output reg[31:0] imm_12_1,
    output reg[31:0] imm_20_1,
    output reg[31:0] imm_31_12
);
    initial begin
        imm11_0<=0;
        shamt<=0;
        imm_11_0_store<=0;
        imm_12_1<=0;
        imm_20_1<=0;
        imm_31_12<=0;
    end
    always @(ir or negedge reset) begin
        if(~reset)begin
            imm11_0<=0;
            shamt<=0;
            imm_11_0_store<=0;
            imm_12_1<=0;
            imm_20_1<=0;
            imm_31_12<=0;
        end
        else begin
            imm11_0<={{20{ir[31]}},ir[31:20]};
            shamt<={{27{1'b0}},ir[24:20]};
            imm_11_0_store<={{20{ir[31]}},ir[31:25],ir[11:7]};
            imm_12_1<={{20{ir[31]}},ir[7],ir[30:25],ir[11:8],1'b0};
            imm_20_1<={{12{ir[31]}},ir[19:12],ir[20],ir[30:21],1'b0};
            imm_31_12<={ir[31:12],{12{1'b0}}};
        end
    end
endmodule