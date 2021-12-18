//数据存储器，兼具执行load store功能
`timescale 1ns/1ps
`include "control_op_def.v"
module DM_1M (
    input clk,//时钟信号
    input reset,//复位信号
    input[31:0] addr,//32位地址线
    input[31:0] data_in,//要写入的数据
    input[3:0] mem_op,//数据存储器操作码
    output reg[31:0] data_out//读出数据
);
    reg[7:0] mem[0:1024*1024-1];//1MB存储器

    initial begin
        $readmemh("D:\\verilog\\riscv-cpu\\hello_data.hex",mem);
        data_out<=0;
    end

    always @(posedge clk or negedge reset) begin
        if(~reset)begin
            $readmemh("D:\\verilog\\riscv-cpu\\hello_data.hex",mem);
            data_out<=0;
        end
        else begin
            case(mem_op)
            //load指令
            `MEMOP_LB:begin//lb
                data_out<={{24{mem[addr[19:0]][7]}},mem[addr[19:0]]};
            end
            `MEMOP_LH:begin//lh
                data_out<={{16{mem[addr[19:0]+1][7]}},mem[addr[19:0]+1],mem[addr[19:0]]};
            end
            `MEMOP_LW:begin//lw
                data_out<={mem[addr[19:0]+3],mem[addr[19:0]+2],mem[addr[19:0]+1],mem[addr[19:0]]};
            end
            `MEMOP_LBU:begin//lbu
                data_out<={{24{1'b0}},mem[addr[19:0]]};
            end
            `MEMOP_LHU:begin//lhu
                data_out<={{16{1'b0}},mem[addr[19:0]+1],mem[addr[19:0]]};
            end
            //store指令
            `MEMOP_SB:begin//sb
                if(addr==32'h13000000)$write("%c",data_in);
                else begin
                    mem[addr[19:0]]<=data_in[7:0];
                end 
            end
            `MEMOP_SH:begin//sh
                mem[addr[19:0]]<=data_in[7:0];mem[addr[19:0]+1]=data_in[15:8];
            end
            `MEMOP_SW:begin//sw
                mem[addr[19:0]]<=data_in[7:0];mem[addr[19:0]+1]=data_in[15:8];
                mem[addr[19:0]+3]<=data_in[23:16];mem[addr[19:0]+4]=data_in[31:24];
            end
            `MEMOP_NON:data_out<=0;
            default:data_out<=0;
            endcase
        end
    end
endmodule

module DM_1M_tb;
reg clk;
reg reset;
reg[3:0] mem_op;
reg[31:0] addr;
reg[31:0] data_in;
wire[31:0] data_out;
DM_1M memory (
    .clk(clk),
    .reset(reset),
    .mem_op(mem_op),
    .addr(addr),
    .data_in(data_in),
    .data_out(data_out)
);

always #5 clk=~clk;

initial begin
    clk<=0;
    reset<=0;
    mem_op<=0;
    addr<=0;
    data_in<=32'b11110000;
    #17 reset<=1;
    #10 $display("data_out = %h",data_out);
    addr<=1;
    #10 $display("data_out = %h",data_out);
    #10 addr<=32'h13000000;mem_op<=1;
    #50 $stop;
end
    
endmodule