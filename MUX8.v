//8路选择器，select=0则选择in0,select=1则选择in1,select=2则选择in2,以此类推
`timescale 1ns/1ps
module MUX8 (
    input[2:0] select,
    input[31:0] in0,
    input[31:0] in1,
    input[31:0] in2,
    input[31:0] in3,
    input[31:0] in4,
    input[31:0] in5,
    input[31:0] in6,
    input[31:0] in7,
    output reg[31:0] out
);
    
    always @(*) begin
        case(select)
        3'd0:out=in0;
        3'd1:out=in1;
        3'd2:out=in2;
        3'd3:out=in3;
        3'd4:out=in4;
        3'd5:out=in5;
        3'd6:out=in6;
        3'd7:out=in7;
        endcase
    end
endmodule

module MUX8_tb;
    reg[2:0] select;
    reg[31:0] in0,in1,in2,in3,in4,in5,in6,in7;
    wire[31:0] out;
    MUX8 mux8 (
    .select(select),
    .in0(in0),
    .in1(in1),
    .in2(in2),
    .in3(in3),
    .in4(in4),
    .in5(in5),
    .in6(in6),
    .in7(in7),
    .out(out)
    );

    initial begin
        select<=0;
        in0<=0;
        in1<=1;
        in2<=2;
        in3<=3;
        in4<=0;
        in5<=1;
        in6<=2;
        in7<=3;
        #10 select<=1;
        #10 select<=2;
        #10 select<=3;
        #30 $stop;
    end
    
endmodule