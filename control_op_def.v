//解码器控制编码定义

//ALU操作码alu_op
`define ALUOP_NON 4'b0000
`define ALUOP_ADD 4'b0001
`define ALUOP_SUB 4'b0010
`define ALUOP_AND 4'b0011
`define ALUOP_OR  4'b0100
`define ALUOP_XOR 4'b0101
`define ALUOP_SLL 4'b0110
`define ALUOP_SRL 4'b0111
`define ALUOP_SRA 4'b1000

//比较器操作码comp_op
`define COMPOP_NON 3'b000
`define COMPOP_LT  3'b001
`define COMPOP_LTU 3'b010
`define COMPOP_EQ  3'b011
`define COMPOP_NE  3'b100
`define COMPOP_GE  3'b101
`define COMPOP_GEU 3'b110

//数据存储器操作码mem_op
`define MEMOP_NON 4'b0000
`define MEMOP_LB  4'b0001
`define MEMOP_LH  4'b0010
`define MEMOP_LW  4'b0011
`define MEMOP_LBU 4'b0100
`define MEMOP_LHU 4'b0101
`define MEMOP_SB  4'b0110
`define MEMOP_SH  4'b0111
`define MEMOP_SW  4'b1000

//写回操作码wb_op
`define WBOP_ALU_RESULT  3'd0 //写回ALU运算结果
`define WBOP_IA_ADD4     3'd1 //写回IA+4
`define WBOP_COMP_RESULT 3'd2 //写回比较结果
`define WBOP_MEM_DATA    3'd3 //写回数据存储器数据
`define WBOP_IMM         3'd4 //写回立即数
`define WBOP_NON         3'd5 //不写回

//stall操作码stall_op
`define STALLOP_NON   2'd0 //不stall
`define STALLOP_DATA  2'd1 //因为读写寄存器stall 数据冲突
`define STALLOP_PC    2'd2 //因为PC指针stall 分支跳转指令