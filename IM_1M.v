`timescale 1ns/1ps

module IM_1M (
    input reset,//复位信号
    input[31:0] addr,//32位地址线
    output reg[31:0] data_out//32位数据线
);
    reg[7:0] mem[0:1024*1024-1];

    initial begin
        // $readmemh("D:\\verilog\\riscv-cpu\\hello_text.hex",mem);
        $readmemb("D:\\verilog\\riscv-cpu\\dataHazard_text_bin.txt",mem);
        data_out<=0;
    end

    always @(addr or negedge reset) begin
        if(~reset)begin
            // $readmemh("D:\\verilog\\riscv-cpu\\hello_text.hex",mem);
            $readmemb("D:\\verilog\\riscv-cpu\\dataHazard_text_bin.txt",mem);
            data_out<={mem[addr[19:0]+3],mem[addr[19:0]+2],mem[addr[19:0]+1],mem[addr[19:0]]};
        end
        else begin
            data_out<={mem[addr[19:0]+3],mem[addr[19:0]+2],mem[addr[19:0]+1],mem[addr[19:0]]};
        end
    end
endmodule

module IM_1M_tb;
    reg clk,reset;
    reg[31:0] addr;
    wire[31:0] data_out;
    IM_1M im_1m (
    .reset(reset),
    .addr(addr),
    .data_out(data_out)
    );

    initial begin
        clk<=0;reset<=0;addr<=0;
        #17 reset<=1;
        #10 addr<=1;
        #10 addr<=2;
        #10 addr<=3;
        #10 addr<=4;
        #40 $stop;
    end

    always #5 clk=~clk;
endmodule