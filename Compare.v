//比较器 用于branch 和 slt sltu指令
`timescale 1ns/1ps
`include "control_op_def.v"
module Compare (
    input clk,
    input reset,
    input[31:0] rs1_val,
    input[31:0] rs2_val,
    input[2:0] comp_op,//比较器操作码
    output reg[31:0] result//1:成立  0:不成立
);
    initial begin
        result<=0;
    end

    always @(posedge clk or negedge reset) begin
        if(~reset)begin
            result<=0;
        end
        else begin
            case(comp_op)
            `COMPOP_LT:begin//lt
                if(rs1_val[31]==rs2_val[31])result=rs1_val[30:0]<rs2_val[30:0]?1:0;
                else result=rs1_val[31]==1?1:0;
            end
            `COMPOP_LTU:result<=rs1_val<rs2_val?1:0;//ltu
            `COMPOP_EQ:result<=(rs1_val==rs2_val?1:0);//eq
            `COMPOP_NE:result=rs1_val!=rs2_val?1:0;//ne
            `COMPOP_GE:begin//ge
                if(rs1_val[31]==rs2_val[31])result=rs1_val[30:0]>=rs2_val[30:0]?1:0;
                else result=rs1_val[31]==0?1:0;
            end
            `COMPOP_GEU:result=rs1_val>=rs2_val?1:0;//geu
            `COMPOP_NON:result<=0;
            default:result<=0;
            endcase
        end
    end
endmodule

module Compare_tb;
    reg[31:0] rs1_val;
    reg[31:0] rs2_val;
    reg[2:0] comp_op;
    wire[31:0] result;
    Compare compare (
        .rs1_val(rs1_val),
        .rs2_val(rs2_val),
        .comp_op(comp_op),
        .result(result)
    );

    initial begin
        rs1_val<=32'hffffffff;rs2_val<=32'h00000000;comp_op<=3'b000;//1
        #10 rs1_val<=32'hffffffff;rs2_val<=32'h00000000;comp_op<=3'b001;//0
        #10 rs1_val<=32'hfff0ff0f;rs2_val<=32'hfff0ff0f;comp_op<=3'b010;//1
        #10 rs1_val<=32'hfff0ff0f;rs2_val<=32'hfff0ff0f;comp_op<=3'b011;//0
        #10 rs1_val<=32'hffffff0f;rs2_val<=32'hfff0ff0f;comp_op<=3'b011;//1
        #10 rs1_val<=32'hfff0ff0f;rs2_val<=32'hfff0ff00;comp_op<=3'b011;//1
        #30 $stop;
    end
endmodule