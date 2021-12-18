//译码器 兼控制器
`timescale 1ns/1ps
`include "control_op_def.v"
module Decoder (
    input clk,//时钟信号
    input reset,//复位信号
    input[31:0] ir,//指令内容
    input[2:0] wb_op2,//写回阶段输入的操作码
    input[4:0] wb_rd,//写回的目的寄存器ID
    input is_bj,//分支jmp指令是否要跳转(写回PC)
    input bj_finish,//分支jmp指令是否执行完毕
    output reg[3:0] alu_op,//ALU操作码
    output reg[2:0] comp_op,//比较器操作码
    output reg[3:0] mem_op,//数据存储器操作码
    output reg[2:0] wb_op,//0:写回alu_result 1:写回ia_add4 2:写回comp_result 3:写回data 4:写回立即数 5:不写回
    output reg select1,//0:mux1选择ia  1:mux1选择rs1_val
    output reg select2,//0:mux2选择rs2_val 1:mux2选择imm_ext_32
    output reg[31:0] imm_ext_32,//扩展到32位的立即数
    output reg jmp,//是否是无条件跳转指令
    output reg branch,//是否是分支指令
    output reg[1:0] stall_op//0:不需要stall 1:由于数据冲突需要停止 2:由于分支跳转需要停止
);
    reg rra[0:31];//寄存器就绪数组 rra[i]=0表示i寄存器未就绪,1表示就绪
    reg[1:0] stall_op_prev;//上一拍stall_op的值

    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;
    wire[4:0] rs1;
    wire[4:0] rs2;
    wire[4:0] rd;
    integer i;

    assign opcode=ir[6:0];
    assign funct3=ir[14:12];
    assign funct7=ir[31:25];
    assign rs1=ir[19:15];
    assign rs2=ir[24:20];
    assign rd=ir[11:7];

    initial begin
        alu_op<=0;
        comp_op<=0;
        mem_op<=0;
        wb_op<=0;
        select1<=0;
        select2<=0;
        imm_ext_32<=0;
        jmp<=0;
        branch<=0;
        for (i = 0;i<32 ; i=i+1) rra[i]<=1;//初始状态全部就绪
        stall_op<=0;
        stall_op_prev<=0;
    end

    always @(bj_finish) begin
        if(bj_finish)begin//分支跳转指令执行完毕，解除stall
                stall_op_prev<=stall_op;
                stall_op<=0;
                $display("unstall bj");
            end 
    end

    always @(posedge clk or negedge reset) begin
        if(~reset)begin
            alu_op<=0;
            comp_op<=0;
            mem_op<=0;
            wb_op<=`WBOP_NON;
            select1<=0;
            select2<=0;
            imm_ext_32<=0;
            jmp<=0;
            branch<=0;
            for (i = 0;i<32 ; i=i+1) rra[i]<=1;//初始状态全部就绪
            stall_op<=0;
            stall_op_prev<=0;
        end
        else begin
            if(wb_op2<=4)begin//寄存器写回操作
                rra[wb_rd]<=1;
                stall_op_prev<=stall_op;
                stall_op<=0;//解除stall
                $display("unstall datahazard");
            end
            //如果解码后发现是跳转pc前的一个无效指令，则舍去
            if(stall_op==`STALLOP_NON && stall_op_prev==`STALLOP_PC && bj_finish && is_bj)begin
                $display("discard instruction");
                alu_op=`ALUOP_NON;
                comp_op=`COMPOP_NON;
                mem_op<=`MEMOP_NON;
                wb_op<=`WBOP_NON;
                imm_ext_32<=0;
                jmp<=0;branch<=0;
            end
            else begin
                case(opcode)
                7'b0010011:begin//立即数类型 I-type
                    case(funct3)
                    3'b000:begin//addi
                        if(rra[rs1]==1 && rra[rd]==1)begin//如果寄存器都就绪，正常执行
                            alu_op<=`ALUOP_ADD;
                            comp_op<=`COMPOP_NON;
                            mem_op<=`MEMOP_NON;
                            wb_op<=`WBOP_ALU_RESULT;
                            select1<=1;//mux1选择rs1_val
                            select2<=1;//mux2选择imm
                            imm_ext_32<={{20{ir[31]}},ir[31:20]};
                            jmp<=0;branch<=0;
                            rra[rd]<=0;
                        end
                        else begin//否则stall流水线
                            stall_op_prev<=stall_op;
                            stall_op<=1;
                            alu_op<=`ALUOP_NON;
                            comp_op<=`COMPOP_NON;
                            mem_op<=`MEMOP_NON;
                            wb_op<=`WBOP_NON;
                            jmp<=0;branch<=0;
                        end 
                    end
                    3'b010:begin//slti
                        alu_op<=`ALUOP_NON;
                        comp_op=`COMPOP_LT;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_COMP_RESULT;
                        select1<=0;//mux1不需要
                        select2<=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b011:begin//sltiu
                        alu_op<=`ALUOP_NON;
                        comp_op=`COMPOP_LTU;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_COMP_RESULT;
                        select1<=0;//mux1不需要
                        select2<=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b100:begin//xori
                        alu_op<=`ALUOP_XOR;
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_ALU_RESULT;
                        select1<=1;//mux1选择rs1_val
                        select2<=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b110:begin//ori
                        alu_op<=`ALUOP_OR;
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_ALU_RESULT;
                        select1<=1;//mux1选择rs1_val
                        select2<=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b111:begin//andi
                        alu_op<=`ALUOP_AND;
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_ALU_RESULT;
                        select1<=1;//mux1选择rs1_val
                        select2<=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b001:begin//slli
                        alu_op<=`ALUOP_SLL;
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_ALU_RESULT;
                        select1<=1;//mux1选择rs1_val
                        select2<=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b001:begin//srli srai
                        case(funct7)
                        7'b0000000:begin//srli
                            alu_op<=`ALUOP_SRL;
                            comp_op=`COMPOP_NON;
                            mem_op<=`MEMOP_NON;
                            wb_op<=`WBOP_ALU_RESULT;
                            select1<=1;//mux1选择rs1_val
                            select2<=1;//mux2选择imm
                            imm_ext_32<={{20{ir[31]}},ir[31:20]};
                            jmp<=0;branch<=0;
                            rra[rd]<=0;
                        end
                        7'b0100000:begin//srai
                            alu_op<=`ALUOP_SRA;
                            comp_op=`COMPOP_NON;
                            mem_op<=`MEMOP_NON;
                            wb_op<=`WBOP_ALU_RESULT;
                            select1<=1;//mux1选择rs1_val
                            select2<=1;//mux2选择imm
                            imm_ext_32<={{20{ir[31]}},ir[31:20]};
                            jmp<=0;branch<=0;
                            rra[rd]<=0;
                        end
                        endcase
                    end
                    endcase
                end
                7'b0110011:begin//寄存器类型 R-type
                    case(funct3)
                    3'b000:begin//add sub
                        case(funct7)
                        7'b0000000:begin//add
                            alu_op<=`ALUOP_ADD;
                            comp_op=`COMPOP_NON;
                            mem_op<=`MEMOP_NON;
                            wb_op<=`WBOP_ALU_RESULT;
                            select1=1;//mux1选择rs1_val
                            select2=0;//mux2选择rs2_val
                            imm_ext_32<=0;//没有立即数
                            jmp<=0;branch<=0;
                            rra[rd]<=0;
                        end
                        7'b0100000:begin//sub
                            alu_op<=`ALUOP_SUB;
                            comp_op=`COMPOP_NON;
                            mem_op<=`MEMOP_NON;
                            wb_op<=`WBOP_ALU_RESULT;
                            select1=1;//mux1选择rs1_val
                            select2=0;//mux2选择rs2_val
                            imm_ext_32<=0;//没有立即数
                            jmp<=0;branch<=0;
                            rra[rd]<=0;
                        end
                        endcase
                    end
                    3'b001:begin//sll
                        alu_op<=`ALUOP_SLL;
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_ALU_RESULT;
                        select1=1;//mux1选择rs1_val
                        select2=0;//mux2选择rs2_val
                        imm_ext_32<=0;//没有立即数
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b010:begin//slt
                        alu_op<=`ALUOP_NON;
                        comp_op=`COMPOP_LT;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_COMP_RESULT;
                        select1=1;//mux1选择rs1_val
                        select2=0;//mux2选择rs2_val
                        imm_ext_32<=0;//没有立即数
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b011:begin//sltu
                        alu_op<=`ALUOP_NON;
                        comp_op=`COMPOP_LTU;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_COMP_RESULT;
                        select1=1;//mux1选择rs1_val
                        select2=0;//mux2选择rs2_val
                        imm_ext_32<=0;//没有立即数
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b100:begin//xor
                        alu_op<=`ALUOP_XOR;
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_ALU_RESULT;
                        select1=1;//mux1选择rs1_val
                        select2=0;//mux2选择rs2_val
                        imm_ext_32<=0;//没有立即数
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b101:begin//srl sra
                        case(funct7)
                        7'b0000000:begin//srl
                            alu_op<=`ALUOP_SRL;
                            comp_op=`COMPOP_NON;
                            mem_op<=`MEMOP_NON;
                            wb_op<=`WBOP_ALU_RESULT;
                            select1=1;//mux1选择rs1_val
                            select2=0;//mux2选择rs2_val
                            imm_ext_32<=0;//没有立即数
                            jmp<=0;branch<=0;
                            rra[rd]<=0;
                        end
                        7'b0100000:begin//sra
                            alu_op<=`ALUOP_SRA;
                            comp_op=`COMPOP_NON;
                            mem_op<=`MEMOP_NON;
                            wb_op<=`WBOP_ALU_RESULT;
                            select1=1;//mux1选择rs1_val
                            select2=0;//mux2选择rs2_val
                            imm_ext_32<=0;//没有立即数
                            jmp<=0;branch<=0;
                            rra[rd]<=0;
                        end
                        endcase
                    end
                    3'b110:begin//or
                        alu_op<=`ALUOP_OR;
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_ALU_RESULT;
                        select1=1;//mux1选择rs1_val
                        select2=0;//mux2选择rs2_val
                        imm_ext_32<=0;//没有立即数
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b111:begin//and
                        alu_op<=`ALUOP_AND;
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_NON;
                        wb_op<=`WBOP_ALU_RESULT;
                        select1=1;//mux1选择rs1_val
                        select2=0;//mux2选择rs2_val
                        imm_ext_32<=0;//没有立即数
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    endcase
                end
                7'b0000011:begin//load指令
                    case(funct3)
                    3'b000:begin//lb
                        alu_op=`ALUOP_ADD;//load指令都是使用add计算目标地址
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_LB;
                        wb_op<=`WBOP_MEM_DATA;
                        select1=1;//mux1选择rs1_val
                        select2=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};//立即数为相对地址
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b001:begin//lh
                        alu_op=`ALUOP_ADD;//load指令都是使用add计算目标地址
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_LH;
                        wb_op<=`WBOP_MEM_DATA;
                        select1=1;//mux1选择rs1_val
                        select2=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};//立即数为相对地址
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b010:begin//lw
                        alu_op=`ALUOP_ADD;//load指令都是使用add计算目标地址
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_LW;
                        wb_op<=`WBOP_MEM_DATA;
                        select1=1;//mux1选择rs1_val
                        select2=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};//立即数为相对地址
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b100:begin//lbu
                        alu_op=`ALUOP_ADD;//load指令都是使用add计算目标地址
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_LBU;
                        wb_op<=`WBOP_MEM_DATA;
                        select1=1;//mux1选择rs1_val
                        select2=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};//立即数为相对地址
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    3'b101:begin//lhu
                        alu_op=`ALUOP_ADD;//load指令都是使用add计算目标地址
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_LHU;
                        wb_op<=`WBOP_MEM_DATA;
                        select1=1;//mux1选择rs1_val
                        select2=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:20]};//立即数为相对地址
                        jmp<=0;branch<=0;
                        rra[rd]<=0;
                    end
                    endcase
                end
                7'b0100011:begin//store指令
                    case(funct3)
                    3'b000:begin//sb
                        alu_op=`ALUOP_ADD;//store指令都是使用add计算目标地址
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_SB;
                        wb_op<=`WBOP_NON;
                        select1=1;//mux1选择rs1_val
                        select2=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:25],ir[11:7]};//相对偏移量
                        jmp<=0;branch<=0;
                    end
                    3'b001:begin//sh
                        alu_op=`ALUOP_ADD;//store指令都是使用add计算目标地址
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_SH;
                        wb_op<=`WBOP_NON;
                        select1=1;//mux1选择rs1_val
                        select2=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:25],ir[11:7]};//相对偏移量
                        jmp<=0;branch<=0;
                    end
                    3'b010:begin//sw
                        alu_op=`ALUOP_ADD;//store指令都是使用add计算目标地址
                        comp_op=`COMPOP_NON;
                        mem_op<=`MEMOP_SW;
                        wb_op<=`WBOP_NON;
                        select1=1;//mux1选择rs1_val
                        select2=1;//mux2选择imm
                        imm_ext_32<={{20{ir[31]}},ir[31:25],ir[11:7]};//相对偏移量
                        jmp<=0;branch<=0;
                    end
                    endcase
                end
                7'b1100011:begin//branch指令
                    alu_op=`ALUOP_ADD;//alu_op统一为add，为了计算跳转地址
                    mem_op<=`MEMOP_NON;
                    wb_op<=`WBOP_NON;
                    select1=0;//mux1选择ia
                    select2=1;//mux2选择imm
                    imm_ext_32<={{20{ir[31]}},ir[7],ir[30:25],ir[11:8],1'b0};//分支偏移量
                    jmp<=0;branch<=1;
                    case(funct3)
                    3'b000:comp_op=`COMPOP_EQ;//beq
                    3'b001:comp_op=`COMPOP_NE;//bne
                    3'b100:comp_op=`COMPOP_LT;//blt
                    3'b101:comp_op=`COMPOP_GE;//bge
                    3'b110:comp_op=`COMPOP_LTU;//bltu
                    3'b111:comp_op=`COMPOP_GEU;//bgeu
                    endcase
                    stall_op_prev<=stall_op;
                    stall_op<=2;//分支指令默认直接stall流水线
                end
                7'b1101111:begin//jal指令
                    alu_op=`ALUOP_ADD;//alu_op统一为add，为了计算跳转地址
                    comp_op=`COMPOP_NON;
                    mem_op<=`MEMOP_NON;
                    wb_op<=`WBOP_IA_ADD4;
                    select1=0;//mux1选择ia
                    select2=1;//mux2选择imm
                    imm_ext_32<={{12{ir[31]}},ir[19:12],ir[20],ir[30:21],1'b0};//jmp偏移量
                    jmp<=1;branch<=0;
                    rra[rd]<=0;
                end
                7'b1100111:begin//jalr指令
                    alu_op=`ALUOP_ADD;//alu_op统一为add，为了计算跳转地址
                    comp_op=`COMPOP_NON;
                    mem_op<=`MEMOP_NON;
                    wb_op<=`WBOP_IA_ADD4;
                    select1<=1;//mux1选择rs1_val
                    select2<=1;//mux2选择imm
                    imm_ext_32<={{20{ir[31]}},ir[31:20]};//12位偏移量
                    jmp<=1;branch<=0;
                    rra[rd]<=0;
                end
                7'b0110111:begin//lui指令
                    alu_op=`ALUOP_NON;//不用计算
                    comp_op=`COMPOP_NON;
                    mem_op<=`MEMOP_NON;
                    wb_op<=`WBOP_IMM;
                    select1<=1;//mux1不需要
                    select2<=1;//mux2不需要
                    imm_ext_32<={ir[31:12],{12{1'b0}}};//20位寄存器高位
                    jmp<=0;branch<=0;
                    rra[rd]<=0;
                end
                7'b0010111:begin//auipc指令
                    alu_op=`ALUOP_ADD;
                    comp_op=`COMPOP_NON;
                    mem_op<=`MEMOP_NON;
                    wb_op<=`WBOP_ALU_RESULT;
                    select1<=0;//mux1选择ia
                    select2<=1;//mux2选择imm
                    imm_ext_32<={ir[31:12],{12{1'b0}}};//20位寄存器高位
                    jmp<=0;branch<=0;
                    rra[rd]<=0;
                end
                default:begin
                    alu_op=`ALUOP_NON;
                    comp_op=`COMPOP_NON;
                    mem_op<=`MEMOP_NON;
                    wb_op<=`WBOP_NON;
                    jmp<=0;branch<=0;
                end
                endcase
            end
        end
    end
    
endmodule

module Decoder_tb;
    reg clk,reset;
    reg[31:0] ir;
    wire[3:0] alu_op;
    wire[2:0] comp_op;
    wire[3:0] mem_op;
    wire[3:0] wb_op;
    wire select1;
    wire select2;
    wire[31:0] imm_ext_32;
    wire jmp;
    wire branch;
    Decoder decoder (
    .clk(clk),
    .reset(reset),
    .ir(ir),
    .alu_op(alu_op),
    .comp_op(comp_op),
    .mem_op(),
    .wb_op(),
    .select1(select1),
    .select2(select2),
    .imm_ext_32(imm_ext_32),
    .jmp(jmp),
    .branch(branch)
    );

    initial begin
        clk<=0;reset<=0;
        ir<=32'h00000517;
        #17 reset<=1;
        #10 ir<=32'h02050513;
        #10 ir<=32'h130005b7;
        #30 $stop;
    end

    always #5 clk=~clk;
endmodule