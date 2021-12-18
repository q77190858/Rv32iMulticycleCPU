# 基于RV32I指令集的多周期处理器

## 设计特点：

1. 使用`Verilog`硬件描述语言设计
2. 一个多周期的五级流水线CPU，从取指-译码-执行-访存-写回
3. 使单独的指令存储器`IM`和单独的数据存储器`DM`来解决**结构冲突**
4. 使用流水线停顿`stall`来解决**数据冲突** `RAW`和`WAW`
5. 使用流水线停顿`stall`来解决分支`branch`跳转`jmp`指令的**控制冲突**
6. 原本设计支持所有的RV32I指令集，后面由于时间不足，单指令译码支持37条指令，冲突控制目前只支持`addi` `branch`和`jmp`指令
7. 处理器运行于小端(`little-endian`)模式
8. 模拟`UART`映射到0x13000000内存，使用`$display()`系统调用支持串口打印输出
9. 可直接运行由`riscv32-unknown-linux-gnu-gcc`编译出的文本格式的hex文件
10. 由于时间原因，目前只实现了M态，未实现系统寄存器
11. 项目已上传到github和gitee，地址：https://github.com/q77190858/Rv32iMulticycleCPU  https://gitee.com/q77190858/Rv32iMulticycleCPU

## 处理器结构图

![](img\多周期RISCV处理器结构.png)

## 模块介绍

### 取指阶段

#### 模块名 PC

模块功能：指令计数器，保存当前取指的指令地址和上一次的指令地址。执行`addi`指令出现数据冲突会停顿PC，此时PC会回退到上一次指令地址，以期待停顿结束时原来冲突的指令可以再一次执行。若是由于`branch`和`jmp`指令造成的停顿，则PC不会回退。

内部实现：使用2个32位寄存器保存当前指令地址和上一个指令地址。

```verilog
input clk,//时钟信号
input reset,//复位信号
input[1:0] stall_op,//stall操作码
input[31:0] result,//输入地址
output reg[31:0] addr//保存并输出的地址
```

#### 模块名 PCADD4

模块功能：计算PC+4

内部实现：计算输入+4并输出，非时序

```verilog
input[31:0] pc,//输入的PC值
output reg[31:0] result//输出PC+4
```

#### 模块名 IM_1M

模块功能：1MB容量的指令存储器，依然支持32位的地址线，但是高12位会被忽略

内部实现：一个1M的字节数组存储数据，每次根据地址线的地址，依次读取4个字节按照小端字节序输出

```verilog
input reset,//复位信号
input[31:0] addr,//32位地址线
output reg[31:0] data_out//32位数据线
```

#### 模块名 MUX_PC

模块功能：select=0意味着不跳转则选择in0(pc+4)作为下一个指令地址,否则选择in1(bj_addr)作为下一个PC

内部实现：用于控制PC是否跳转的2选1多路选择器

```verilog
input select,//选择信号
input[31:0] in0,//0号输入
input[31:0] in1,//1好输入
output[31:0] out//输出
```

### 译码阶段

#### 模块名 Decoder

模块功能：译码器 兼控制器

内部实现：根据流入的指令内容，流出指令的控制信号和数据信号的值，调度各个多路选择器选择，调度各个运算单元`ALU` `COMP` 进行运算，调度数据存储器进行读写操作，调度8选1多路选择器选择写回的数据，调度`PC`和`IF/ID`段决定是否停顿和怎样停顿。

```verilog
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
```

#### 模块名 Registers

模块功能：寄存器文件，保存0-31号32位寄存器的值，其中0号寄存器读出时钟为0

内部实现：使用`reg[31:0] regs[0:31];`寄存器数组保存数据，有2个读端口，一个写端口，可同时读写

```verilog
input clk,//时钟信号
input reset,//复位信号
input[4:0] rs1,//源1寄存器ID
input[4:0] rs2,//源2寄存器ID
input[4:0] rd,//目的寄存器ID
input[2:0] wb_op,//写回操作码 0-4:可写回数据 5-7:只读
input[31:0] wb_data,//写回rd的数据
output reg[31:0] rs1_val,//源1寄存器的值
output reg[31:0] rs2_val//源2寄存器的值
```

### 执行阶段

#### 模块名 MUX1

模块功能：用于控制ALU第1个运算数的2选1多路选择器，复用了MUX模块

内部实现：select=0意味着选择当前指令地址ia_ID作为ALU第一个运算数,否则选择寄存器文件读出的第一个源操作数值rs1_val作为ALU第一个运算数

```verilog
input select,//选择信号
input[31:0] in0,//0号输入
input[31:0] in1,//1好输入
output[31:0] out//输出
```

#### 模块名 MUX2

模块功能：用于控制ALU第2个运算数的2选1多路选择器，复用了MUX模块

内部实现：select=0意味着选择寄存器文件读出的第2个源操作数值rs2_val作为ALU第2个运算数,否则选择扩展到32位的立即数作为ALU第2个运算数

```verilog
input select,//选择信号
input[31:0] in0,//0号输入
input[31:0] in1,//1好输入
output[31:0] out//输出
```

#### 模块名 MUX_COMP

模块功能：用于控制COMP比较器第2个运算数的2选1多路选择器，复用了MUX模块，由于比较操作只有branch和slt slti类型需要使用，因此比较器的第一个输入始终为rs1_val，第二个输入可能为rs2_val和立即数，因此需要选择

内部实现：select=0意味着选择扩展到32位的立即数作为COMP第2个运算数,否则选择寄存器文件读出的第2个源操作数值rs2_val作为COMP第2个运算数

```verilog
input select,//选择信号
input[31:0] in0,//0号输入
input[31:0] in1,//1好输入
output[31:0] out//输出
```

#### 模块名 ALU

模块功能：算术逻辑单元，可执行加减、位移和位运算

内部实现：根据alu_op来执行不同的计算，定义如下（见control_op_def.v定义文件）

```verilog
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
```

输入和输出信号如下

```verilog
input clk,//时钟信号
input reset,//复位信号
input[31:0] oprand1,//ALU第1个操作数
input[31:0] oprand2,//ALU第2个操作数
input[3:0] alu_op,//ALU运算操作码
output reg[31:0] result//运算结果
```

#### 模块名 Compare

模块功能：比较器，可执行有符号和无符号的比较运算，真结果为1，假结果为0，结果均为32位

内部实现：根据comp_op来执行不同的比较，定义如下（见control_op_def.v定义文件）

```verilog
//比较器操作码comp_op
`define COMPOP_NON 3'b000
`define COMPOP_LT  3'b001
`define COMPOP_LTU 3'b010
`define COMPOP_EQ  3'b011
`define COMPOP_NE  3'b100
`define COMPOP_GE  3'b101
`define COMPOP_GEU 3'b110
```

输入和输出信号如下

```verilog
input clk,
input reset,
input[31:0] rs1_val,
input[31:0] rs2_val,
input[2:0] comp_op,//比较器操作码
output reg[31:0] result//1:成立  0:不成立
```

### 访存阶段

#### 模块名 DM_1M

模块功能：1MB容量的数据存储器，依然支持32位的地址线，但是高12位会被忽略

内部实现：一个1M的字节数组`reg[7:0] mem[0:1024*1024-1]`存储数据，每次根据`mem_op`不同的操作码读取或者写入数据，读取或者写入多个字节按照小端字节序。mem操作码定义如下（见control_op_def.v定义文件）：

```verilog
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
```

输入和输出信号如下

```verilog
input clk,//时钟信号
input reset,//复位信号
input[31:0] addr,//32位地址线
input[31:0] data_in,//要写入的数据
input[3:0] mem_op,//数据存储器操作码
output reg[31:0] data_out//读出数据
```

### 写回阶段

#### 模块名 MUX8

模块功能：用于写回阶段写回数据的8选1多路选择器，实际只使用了6个端口，由于写回阶段可写回ALU COMP的计算结果、可写回IA+4（jmp指令要求）、可写回从数据存储器读取的data，因此需要多路选择

内部实现：wb_op定义如下

```verilog
//写回操作码wb_op
`define WBOP_ALU_RESULT  3'd0 //写回ALU运算结果
`define WBOP_IA_ADD4     3'd1 //写回IA+4
`define WBOP_COMP_RESULT 3'd2 //写回比较结果
`define WBOP_MEM_DATA    3'd3 //写回数据存储器数据
`define WBOP_IMM         3'd4 //写回立即数
`define WBOP_NON         3'd5 //不写回
```

使用了MUX8模块，输入和输出信号如下

```verilog
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
```

### 冲突解决和流水线停顿

该处理器主要使用流水线stall来解决冲突，在对于数据冲突RAW和WAW，在Decoder中定义一个RRA（register ready array）数组来保存当前寄存器的就绪状态

```verilog
reg rra[0:31];//寄存器就绪数组 rra[i]=0表示i寄存器未就绪,1表示就绪
```

#### 数据冲突

我们以addi为例子。若一个指令addi1要写寄存器i，则把这个寄存器状态置为0未就绪，若接下来进入译码的指令addi2需要读写i寄存器，则发生冲突，addi2指令无法发射出去，停顿PC取指和IF/ID段的流入。同时在PC停顿时，将PC的值恢复到上一个值，也就是addi2的地址。在addi1指令完成执行并且写回寄存器i以后，decoder把rra[i]置为1，寄存器1就绪可访问。decoder恢复流水线，继续开始PC取指和IF/ID段的流动，addi2指令重新进入decoder进行译码，流水线恢复执行。

#### 控制冲突

我们以分支指令beq为例子。若decoder译码一个指令发现为beq，则停顿PC取指和IF/ID段的流入，但是与addi不同的是，PC指针不需要恢复到上一个值，因为当前PC的值是beq后一个指令的地址，由于目前无法判断beq一定跳转，所以也无法判定beq后面的那个指令就一定是无效不执行的。因此仅仅停顿了流水线。beq经过执行阶段得到执行结果，这时bj_finish信号为1说明跳转指令执行完毕（并不能说明是否跳转，只是执行完了，后面的指令可以在下一拍流入了）。这时is_bj信号若为1则说明需要跳转，则在下一拍把alu的跳转地址写回PC。经过一拍后，此时PC的值为跳转的地址，流入译码器的值为beq后一个指令，这个指令在跳转成功的时候明显是不需要执行的，因此decoder丢弃这个指令。若is_bj信号为0说明不需要跳转，则下一拍继续执行beq后一条指令，流水线正常执行。

我们可以看出数据冲突和结构冲突对于流水线停顿的操作是有区别的。因此定义了停顿操作码stall_op如下

```verilog
//stall操作码stall_op
`define STALLOP_NON   2'd0 //不stall
`define STALLOP_DATA  2'd1 //因为读写寄存器stall 数据冲突
`define STALLOP_PC    2'd2 //因为PC指针stall 分支跳转指令
```

## 功能验证

使用如下代码进行功能验证，指令执行和流水线停顿正常，执行结果符合预期

```verilog
@00000000
01100011 10000110 00100000 00000000  //beq x1,x2,6
10010011 10000000 00000000 01000000 //addi x1,x1,1024
00010011 10000001 00100000 00000000 //addi x2,x1,2
10010011 10000000 00000000 01000000 //addi x1,x1,1024
00010011 10000001 00100000 00000000 //addi x2,x1,2
00010011 00000001 01000001 00000000 //addi x2,x2,4
```

## 指令支持

| **分类**       | **指令**                                                     | **数目** | 单指令执行 |  冲突控制  |
| -------------- | :----------------------------------------------------------- | -------- | :--------: | :--------: |
| 算术和逻辑运算 | LUI/AUIPC<br />ADDI/SLTI/SLTIU/ADD/SUB/SLT/SLTU<br />SLLI/SRLI/SRAI/SLL/SRL/SRA<br />ANDI/ORI/XORI/AND/OR/XOR | 21       |    实现    | 仅支持ADDI |
| 控制           | JAL/JALR<br />BEQ/BNE/BLT/BGE/BLTU/BGEU                      | 8        |    实现    |    实现    |
| 数据传输       | LB/LH/LW/LBU/LHU<br />SB/SH/SW                               | 8        |    实现    |   待实现   |
| 其他           | FENCE/ECALL/EBREAK                                           | 3        |   待实现   |   待实现   |
| 总计           |                                                              | 40       |     37     |     9      |

## 汇编文件编译成`verilog`可运行文本文件

```bash
# test.s -> test.o
riscv32-unknown-linux-gnu-gcc -nostdlib -c -o test.o test.s
# test.o -> test.elf
riscv32-unknown-linux-gnu-ld -nostdlib -o test.elf test.o
# test.elf -> test.dis
riscv32-unknown-linux-gnu-objdump -D test.elf > test.dis
# test.elf -> test_text_hex.txt 代码段
riscv32-unknown-linux-gnu-objcopy -O verilog --only-section ".text"  test.elf test_text_hex.txt
# test.elf -> test_data_hex.txt 数据段
riscv32-unknown-linux-gnu-objcopy -O verilog --only-section ".data"  test.elf test_data_hex.txt
```

## 下一步工作

1. 继续完善各个指令对于流水线停顿的支持
2. 探索使用数据旁路、Tomasolo等方法解决冲突，提高指令执行效率