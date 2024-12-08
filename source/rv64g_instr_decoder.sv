/*
This module is mean to decode instruction into the decoded_instr_t as mentioned in the
[rv64g_pkg](../../include/rv64g_pkg.sv).
- The `func` field enumerates the function that the current instruction.
- The `rd` is the destination register ant the `rs1`, `rs2` & `rs3` are the source registers. An
  offset of 32 is added for the floating point registers' address.
- The `imm` has multi-purpose such signed/unsigned immediate, shift, csr_addr, etc. based on the
  `func`.
- The `pc` hold's the physical address of the current instruction.
- The `jump` field is set high when the current instruction can cause branch/jump.
- The `reg_req` field is a flag that indicates the registers that are required for the current
  instruction

[Click here to see the supported instruction](../supported_instructions.md)

See the [ISA Manual](https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf)'s Chapter
24 (RV32/64G Instruction Set Listings) for the encoding.

Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "rv64g_pkg.sv"

module rv64g_instr_decoder #(
    // interger register width
    localparam int  XLEN            = rv64g_pkg::XLEN,
    // type definition of decoded instruction
    localparam type decoded_instr_t = rv64g_pkg::decoded_instr_t
) (
    // 32-bit input instruction code
    input logic [XLEN-1:0] pc_i,

    // 32-bit input instruction code
    input logic [31:0] code_i,

    // Output decoded instruction
    output decoded_instr_t cmd_o
);

  import rv64g_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [4:0] rd;  // Destination register
  logic [4:0] rs1;  // Source register 1
  logic [4:0] rs2;  // Source register 2
  logic [4:0] rs3;  // Source register 3

  logic [XLEN-1:0] aimm;  // SHIFT AMOUNT
  logic [XLEN-1:0] bimm;  // BTYPE INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] cimm;  // CSR INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] iimm;  // ITYPE INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] jimm;  // JTYPE INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] rimm;  // FLOATING ROUND MODE IMMEDIATE
  logic [XLEN-1:0] simm;  // RTYPE INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] timm;  // ATOMICS IMMEDIATE
  logic [XLEN-1:0] uimm;  // UTYPE INSTRUCTION IMMEDIATE

  logic [19:0] i_func[159];  // internal function AND array
  logic [19:0] i_func_final;  // internal function final

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // INSTRUCTION REGISTER INDEX
  always_comb rd = code_i[11:7];
  always_comb rs1 = code_i[19:15];
  always_comb rs2 = code_i[24:20];
  always_comb rs3 = code_i[31:27];

  // SHIFT AMOUNT
  always_comb begin
    aimm = '0;
    aimm[5:0] = code_i[25:20];
  end

  // BTYPE INSTRUCTION IMMEDIATE
  always_comb begin
    bimm = '0;
    bimm[4:1] = code_i[11:8];
    bimm[10:5] = code_i[30:25];
    bimm[11] = code_i[7];
    bimm[12] = code_i[31];
    bimm[63:13] = {51{code_i[31]}};
  end

  // CSR INSTRUCTION IMMEDIATE
  always_comb begin
    cimm = '0;
    cimm[11:0] = code_i[31:20];
    cimm[16:12] = code_i[19:15];
  end

  // ITYPE INSTRUCTION IMMEDIATE
  always_comb begin
    iimm[11:0]  = code_i[31:20];
    iimm[63:12] = {52{code_i[31]}};
  end

  // JTYPE INSTRUCTION IMMEDIATE
  always_comb begin
    jimm = '0;
    jimm[10:1] = code_i[30:21];
    jimm[19:12] = code_i[19:12];
    jimm[11] = code_i[20];
    jimm[20] = code_i[31];
    jimm[63:21] = {43{code_i[31]}};
  end

  // FLOATING ROUND MODE IMMEDIATE
  always_comb begin
    rimm = '0;
    rimm[2:0] = code_i[14:12];
  end

  // RTYPE INSTRUCTION IMMEDIATE
  always_comb begin
    simm[4:0]   = code_i[11:7];
    simm[11:5]  = code_i[31:25];
    simm[63:12] = {52{code_i[31]}};
  end

  // ATOMICS IMMEDIATE
  always_comb begin
    timm = '0;
    timm[0] = code_i[25:25];
    timm[1] = code_i[26:26];
  end

  // UTYPE INSTRUCTION IMMEDIATE
  always_comb begin
    uimm = '0;
    uimm[11:0] = code_i[31:12];
  end

  `define RV64G_INSTR_DECODER_CMP(__IDX__, __CMP__, __EXP__, __OUT__)                             \
    constant_compare #(                                                                           \
        .IP_WIDTH(32),                                                                            \
        .CMP_ENABLES(``__CMP__``),                                                                \
        .EXP_RESULT(``__EXP__``),                                                                 \
        .OP_WIDTH(20),                                                                            \
        .MATCH_TRUE(``__OUT__``),                                                                 \
        .MATCH_FALSE('1)                                                                          \
    ) u_constant_compare_``__IDX__``_``__OUT__`` (                                                \
        .in_i (code_i),                                                                           \
        .out_o(i_func[``__IDX__``])                                                               \
    );                                                                                            \

  // Decode the instruction and set the intermediate function
  `RV64G_INSTR_DECODER_CMP(0, 32'h0000007F, 32'h00000037, i_LUI)
  `RV64G_INSTR_DECODER_CMP(1, 32'h0000007F, 32'h00000017, i_AUIPC)
  `RV64G_INSTR_DECODER_CMP(2, 32'h0000007F, 32'h0000006F, i_JAL)
  `RV64G_INSTR_DECODER_CMP(3, 32'h0000707F, 32'h00000067, i_JALR)
  `RV64G_INSTR_DECODER_CMP(4, 32'h0000707F, 32'h00000063, i_BEQ)
  `RV64G_INSTR_DECODER_CMP(5, 32'h0000707F, 32'h00001063, i_BNE)
  `RV64G_INSTR_DECODER_CMP(6, 32'h0000707F, 32'h00004063, i_BLT)
  `RV64G_INSTR_DECODER_CMP(7, 32'h0000707F, 32'h00005063, i_BGE)
  `RV64G_INSTR_DECODER_CMP(8, 32'h0000707F, 32'h00006063, i_BLTU)
  `RV64G_INSTR_DECODER_CMP(9, 32'h0000707F, 32'h00007063, i_BGEU)
  `RV64G_INSTR_DECODER_CMP(10, 32'h0000707F, 32'h00000003, i_LB)
  `RV64G_INSTR_DECODER_CMP(11, 32'h0000707F, 32'h00001003, i_LH)
  `RV64G_INSTR_DECODER_CMP(12, 32'h0000707F, 32'h00002003, i_LW)
  `RV64G_INSTR_DECODER_CMP(13, 32'h0000707F, 32'h00004003, i_LBU)
  `RV64G_INSTR_DECODER_CMP(14, 32'h0000707F, 32'h00005003, i_LHU)
  `RV64G_INSTR_DECODER_CMP(15, 32'h0000707F, 32'h00000023, i_SB)
  `RV64G_INSTR_DECODER_CMP(16, 32'h0000707F, 32'h00001023, i_SH)
  `RV64G_INSTR_DECODER_CMP(17, 32'h0000707F, 32'h00002023, i_SW)
  `RV64G_INSTR_DECODER_CMP(18, 32'h0000707F, 32'h00000013, i_ADDI)
  `RV64G_INSTR_DECODER_CMP(19, 32'h0000707F, 32'h00002013, i_SLTI)
  `RV64G_INSTR_DECODER_CMP(20, 32'h0000707F, 32'h00003013, i_SLTIU)
  `RV64G_INSTR_DECODER_CMP(21, 32'h0000707F, 32'h00004013, i_XORI)
  `RV64G_INSTR_DECODER_CMP(22, 32'h0000707F, 32'h00006013, i_ORI)
  `RV64G_INSTR_DECODER_CMP(23, 32'h0000707F, 32'h00007013, i_ANDI)
  `RV64G_INSTR_DECODER_CMP(24, 32'hFE00707F, 32'h00001013, i_SLLI)
  `RV64G_INSTR_DECODER_CMP(25, 32'hFE00707F, 32'h00005013, i_SRLI)
  `RV64G_INSTR_DECODER_CMP(26, 32'hFE00707F, 32'h40005013, i_SRAI)
  `RV64G_INSTR_DECODER_CMP(27, 32'hFE00707F, 32'h00000033, i_ADD)
  `RV64G_INSTR_DECODER_CMP(28, 32'hFE00707F, 32'h40000033, i_SUB)
  `RV64G_INSTR_DECODER_CMP(29, 32'hFE00707F, 32'h00001033, i_SLL)
  `RV64G_INSTR_DECODER_CMP(30, 32'hFE00707F, 32'h00002033, i_SLT)
  `RV64G_INSTR_DECODER_CMP(31, 32'hFE00707F, 32'h00003033, i_SLTU)
  `RV64G_INSTR_DECODER_CMP(32, 32'hFE00707F, 32'h00004033, i_XOR)
  `RV64G_INSTR_DECODER_CMP(33, 32'hFE00707F, 32'h00005033, i_SRL)
  `RV64G_INSTR_DECODER_CMP(34, 32'hFE00707F, 32'h40005033, i_SRA)
  `RV64G_INSTR_DECODER_CMP(35, 32'hFE00707F, 32'h00006033, i_OR)
  `RV64G_INSTR_DECODER_CMP(36, 32'hFE00707F, 32'h00007033, i_AND)
  `RV64G_INSTR_DECODER_CMP(37, 32'h0000707F, 32'h0000000F, i_FENCE)
  `RV64G_INSTR_DECODER_CMP(38, 32'hFFFFFFFF, 32'h8330000F, i_FENCE_TSO)
  `RV64G_INSTR_DECODER_CMP(39, 32'hFFFFFFFF, 32'h0100000F, i_PAUSE)
  `RV64G_INSTR_DECODER_CMP(40, 32'hFFFFFFFF, 32'h00000073, i_ECALL)
  `RV64G_INSTR_DECODER_CMP(41, 32'hFFFFFFFF, 32'h00100073, i_EBREAK)
  `RV64G_INSTR_DECODER_CMP(42, 32'h0000707F, 32'h00006003, i_LWU)
  `RV64G_INSTR_DECODER_CMP(43, 32'h0000707F, 32'h00003003, i_LD)
  `RV64G_INSTR_DECODER_CMP(44, 32'h0000707F, 32'h00003023, i_SD)
  `RV64G_INSTR_DECODER_CMP(45, 32'h0000707F, 32'h0000001B, i_ADDIW)
  `RV64G_INSTR_DECODER_CMP(46, 32'hFE00707F, 32'h0000101B, i_SLLIW)
  `RV64G_INSTR_DECODER_CMP(47, 32'hFE00707F, 32'h0000501B, i_SRLIW)
  `RV64G_INSTR_DECODER_CMP(48, 32'hFE00707F, 32'h4000501B, i_SRAIW)
  `RV64G_INSTR_DECODER_CMP(49, 32'hFE00707F, 32'h0000003B, i_ADDW)
  `RV64G_INSTR_DECODER_CMP(50, 32'hFE00707F, 32'h4000003B, i_SUBW)
  `RV64G_INSTR_DECODER_CMP(51, 32'hFE00707F, 32'h0000103B, i_SLLW)
  `RV64G_INSTR_DECODER_CMP(52, 32'hFE00707F, 32'h0000503B, i_SRLW)
  `RV64G_INSTR_DECODER_CMP(53, 32'hFE00707F, 32'h4000503B, i_SRAW)
  `RV64G_INSTR_DECODER_CMP(54, 32'h0000707F, 32'h00001073, i_CSRRW)
  `RV64G_INSTR_DECODER_CMP(55, 32'h0000707F, 32'h00002073, i_CSRRS)
  `RV64G_INSTR_DECODER_CMP(56, 32'h0000707F, 32'h00003073, i_CSRRC)
  `RV64G_INSTR_DECODER_CMP(57, 32'h0000707F, 32'h00005073, i_CSRRWI)
  `RV64G_INSTR_DECODER_CMP(58, 32'h0000707F, 32'h00006073, i_CSRRSI)
  `RV64G_INSTR_DECODER_CMP(59, 32'h0000707F, 32'h00007073, i_CSRRCI)
  `RV64G_INSTR_DECODER_CMP(60, 32'hFE00707F, 32'h02000033, i_MUL)
  `RV64G_INSTR_DECODER_CMP(61, 32'hFE00707F, 32'h02001033, i_MULH)
  `RV64G_INSTR_DECODER_CMP(62, 32'hFE00707F, 32'h02002033, i_MULHSU)
  `RV64G_INSTR_DECODER_CMP(63, 32'hFE00707F, 32'h02003033, i_MULHU)
  `RV64G_INSTR_DECODER_CMP(64, 32'hFE00707F, 32'h02004033, i_DIV)
  `RV64G_INSTR_DECODER_CMP(65, 32'hFE00707F, 32'h02005033, i_DIVU)
  `RV64G_INSTR_DECODER_CMP(66, 32'hFE00707F, 32'h02006033, i_REM)
  `RV64G_INSTR_DECODER_CMP(67, 32'hFE00707F, 32'h02007033, i_REMU)
  `RV64G_INSTR_DECODER_CMP(68, 32'hFE00707F, 32'h0200003B, i_MULW)
  `RV64G_INSTR_DECODER_CMP(69, 32'hFE00707F, 32'h0200403B, i_DIVW)
  `RV64G_INSTR_DECODER_CMP(70, 32'hFE00707F, 32'h0200503B, i_DIVUW)
  `RV64G_INSTR_DECODER_CMP(71, 32'hFE00707F, 32'h0200603B, i_REMW)
  `RV64G_INSTR_DECODER_CMP(72, 32'hFE00707F, 32'h0200703B, i_REMUW)
  `RV64G_INSTR_DECODER_CMP(73, 32'hF9F0707F, 32'h1000202F, i_LR_W)
  `RV64G_INSTR_DECODER_CMP(74, 32'hF800707F, 32'h1800202F, i_SC_W)
  `RV64G_INSTR_DECODER_CMP(75, 32'hF800707F, 32'h0800202F, i_AMOSWAP_W)
  `RV64G_INSTR_DECODER_CMP(76, 32'hF800707F, 32'h0000202F, i_AMOADD_W)
  `RV64G_INSTR_DECODER_CMP(77, 32'hF800707F, 32'h2000202F, i_AMOXOR_W)
  `RV64G_INSTR_DECODER_CMP(78, 32'hF800707F, 32'h6000202F, i_AMOAND_W)
  `RV64G_INSTR_DECODER_CMP(79, 32'hF800707F, 32'h4000202F, i_AMOOR_W)
  `RV64G_INSTR_DECODER_CMP(80, 32'hF800707F, 32'h8000202F, i_AMOMIN_W)
  `RV64G_INSTR_DECODER_CMP(81, 32'hF800707F, 32'hA000202F, i_AMOMAX_W)
  `RV64G_INSTR_DECODER_CMP(82, 32'hF800707F, 32'hC000202F, i_AMOMINU_W)
  `RV64G_INSTR_DECODER_CMP(83, 32'hF800707F, 32'hE000202F, i_AMOMAXU_W)
  `RV64G_INSTR_DECODER_CMP(84, 32'hF9F0707F, 32'h1000302F, i_LR_D)
  `RV64G_INSTR_DECODER_CMP(85, 32'hF800707F, 32'h1800302F, i_SC_D)
  `RV64G_INSTR_DECODER_CMP(86, 32'hF800707F, 32'h0800302F, i_AMOSWAP_D)
  `RV64G_INSTR_DECODER_CMP(87, 32'hF800707F, 32'h0000302F, i_AMOADD_D)
  `RV64G_INSTR_DECODER_CMP(88, 32'hF800707F, 32'h2000302F, i_AMOXOR_D)
  `RV64G_INSTR_DECODER_CMP(89, 32'hF800707F, 32'h6000302F, i_AMOAND_D)
  `RV64G_INSTR_DECODER_CMP(90, 32'hF800707F, 32'h4000302F, i_AMOOR_D)
  `RV64G_INSTR_DECODER_CMP(91, 32'hF800707F, 32'h8000302F, i_AMOMIN_D)
  `RV64G_INSTR_DECODER_CMP(92, 32'hF800707F, 32'hA000302F, i_AMOMAX_D)
  `RV64G_INSTR_DECODER_CMP(93, 32'hF800707F, 32'hC000302F, i_AMOMINU_D)
  `RV64G_INSTR_DECODER_CMP(94, 32'hF800707F, 32'hE000302F, i_AMOMAXU_D)
  `RV64G_INSTR_DECODER_CMP(95, 32'h0000707F, 32'h00002007, i_FLW)
  `RV64G_INSTR_DECODER_CMP(96, 32'h0000707F, 32'h00002027, i_FSW)
  `RV64G_INSTR_DECODER_CMP(97, 32'h0600007F, 32'h00000043, i_FMADD_S)
  `RV64G_INSTR_DECODER_CMP(98, 32'h0600007F, 32'h00000047, i_FMSUB_S)
  `RV64G_INSTR_DECODER_CMP(99, 32'h0600007F, 32'h0000004B, i_FNMSUB_S)
  `RV64G_INSTR_DECODER_CMP(100, 32'h0600007F, 32'h0000004F, i_FNMADD_S)
  `RV64G_INSTR_DECODER_CMP(101, 32'hFE00007F, 32'h00000053, i_FADD_S)
  `RV64G_INSTR_DECODER_CMP(102, 32'hFE00007F, 32'h08000053, i_FSUB_S)
  `RV64G_INSTR_DECODER_CMP(103, 32'hFE00007F, 32'h10000053, i_FMUL_S)
  `RV64G_INSTR_DECODER_CMP(104, 32'hFE00007F, 32'h18000053, i_FDIV_S)
  `RV64G_INSTR_DECODER_CMP(105, 32'hFFF0007F, 32'h58000053, i_FSQRT_S)
  `RV64G_INSTR_DECODER_CMP(106, 32'hFE00707F, 32'h20000053, i_FSGNJ_S)
  `RV64G_INSTR_DECODER_CMP(107, 32'hFE00707F, 32'h20001053, i_FSGNJN_S)
  `RV64G_INSTR_DECODER_CMP(108, 32'hFE00707F, 32'h20002053, i_FSGNJX_S)
  `RV64G_INSTR_DECODER_CMP(109, 32'hFE00707F, 32'h28000053, i_FMIN_S)
  `RV64G_INSTR_DECODER_CMP(110, 32'hFE00707F, 32'h28001053, i_FMAX_S)
  `RV64G_INSTR_DECODER_CMP(111, 32'hFFF0007F, 32'hC0000053, i_FCVT_W_S)
  `RV64G_INSTR_DECODER_CMP(112, 32'hFFF0007F, 32'hC0100053, i_FCVT_WU_S)
  `RV64G_INSTR_DECODER_CMP(113, 32'hFFF0707F, 32'hE0000053, i_FMV_X_W)
  `RV64G_INSTR_DECODER_CMP(114, 32'hFE00707F, 32'hA0002053, i_FEQ_S)
  `RV64G_INSTR_DECODER_CMP(115, 32'hFE00707F, 32'hA0001053, i_FLT_S)
  `RV64G_INSTR_DECODER_CMP(116, 32'hFE00707F, 32'hA0000053, i_FLE_S)
  `RV64G_INSTR_DECODER_CMP(117, 32'hFFF0707F, 32'hE0001053, i_FCLASS_S)
  `RV64G_INSTR_DECODER_CMP(118, 32'hFFF0007F, 32'hD0000053, i_FCVT_S_W)
  `RV64G_INSTR_DECODER_CMP(119, 32'hFFF0007F, 32'hD0100053, i_FCVT_S_WU)
  `RV64G_INSTR_DECODER_CMP(120, 32'hFFF0707F, 32'hF0000053, i_FMV_W_X)
  `RV64G_INSTR_DECODER_CMP(121, 32'hFFF0007F, 32'hC0200053, i_FCVT_L_S)
  `RV64G_INSTR_DECODER_CMP(122, 32'hFFF0007F, 32'hC0300053, i_FCVT_LU_S)
  `RV64G_INSTR_DECODER_CMP(123, 32'hFFF0007F, 32'hD0200053, i_FCVT_S_L)
  `RV64G_INSTR_DECODER_CMP(124, 32'hFFF0007F, 32'hD0300053, i_FCVT_S_LU)
  `RV64G_INSTR_DECODER_CMP(125, 32'h0000707F, 32'h00003007, i_FLD)
  `RV64G_INSTR_DECODER_CMP(126, 32'h0000707F, 32'h00003027, i_FSD)
  `RV64G_INSTR_DECODER_CMP(127, 32'h0600007F, 32'h02000043, i_FMADD_D)
  `RV64G_INSTR_DECODER_CMP(128, 32'h0600007F, 32'h02000047, i_FMSUB_D)
  `RV64G_INSTR_DECODER_CMP(129, 32'h0600007F, 32'h0200004B, i_FNMSUB_D)
  `RV64G_INSTR_DECODER_CMP(130, 32'h0600007F, 32'h0200004F, i_FNMADD_D)
  `RV64G_INSTR_DECODER_CMP(131, 32'hFE00007F, 32'h02000053, i_FADD_D)
  `RV64G_INSTR_DECODER_CMP(132, 32'hFE00007F, 32'h0A000053, i_FSUB_D)
  `RV64G_INSTR_DECODER_CMP(133, 32'hFE00007F, 32'h12000053, i_FMUL_D)
  `RV64G_INSTR_DECODER_CMP(134, 32'hFE00007F, 32'h1A000053, i_FDIV_D)
  `RV64G_INSTR_DECODER_CMP(135, 32'hFFF0007F, 32'h5A000053, i_FSQRT_D)
  `RV64G_INSTR_DECODER_CMP(136, 32'hFE00707F, 32'h22000053, i_FSGNJ_D)
  `RV64G_INSTR_DECODER_CMP(137, 32'hFE00707F, 32'h22001053, i_FSGNJN_D)
  `RV64G_INSTR_DECODER_CMP(138, 32'hFE00707F, 32'h22002053, i_FSGNJX_D)
  `RV64G_INSTR_DECODER_CMP(139, 32'hFE00707F, 32'h2A000053, i_FMIN_D)
  `RV64G_INSTR_DECODER_CMP(140, 32'hFE00707F, 32'h2A001053, i_FMAX_D)
  `RV64G_INSTR_DECODER_CMP(141, 32'hFFF0007F, 32'h40100053, i_FCVT_S_D)
  `RV64G_INSTR_DECODER_CMP(142, 32'hFFF0007F, 32'h42000053, i_FCVT_D_S)
  `RV64G_INSTR_DECODER_CMP(143, 32'hFE00707F, 32'hA2002053, i_FEQ_D)
  `RV64G_INSTR_DECODER_CMP(144, 32'hFE00707F, 32'hA2001053, i_FLT_D)
  `RV64G_INSTR_DECODER_CMP(145, 32'hFE00707F, 32'hA2000053, i_FLE_D)
  `RV64G_INSTR_DECODER_CMP(146, 32'hFFF0707F, 32'hE2001053, i_FCLASS_D)
  `RV64G_INSTR_DECODER_CMP(147, 32'hFFF0007F, 32'hC2000053, i_FCVT_W_D)
  `RV64G_INSTR_DECODER_CMP(148, 32'hFFF0007F, 32'hC2100053, i_FCVT_WU_D)
  `RV64G_INSTR_DECODER_CMP(149, 32'hFFF0007F, 32'hD2000053, i_FCVT_D_W)
  `RV64G_INSTR_DECODER_CMP(150, 32'hFFF0007F, 32'hD2100053, i_FCVT_D_WU)
  `RV64G_INSTR_DECODER_CMP(151, 32'hFFF0007F, 32'hC2200053, i_FCVT_L_D)
  `RV64G_INSTR_DECODER_CMP(152, 32'hFFF0007F, 32'hC2300053, i_FCVT_LU_D)
  `RV64G_INSTR_DECODER_CMP(153, 32'hFFF0707F, 32'hE2000053, i_FMV_X_D)
  `RV64G_INSTR_DECODER_CMP(154, 32'hFFF0007F, 32'hD2200053, i_FCVT_D_L)
  `RV64G_INSTR_DECODER_CMP(155, 32'hFFF0007F, 32'hD2300053, i_FCVT_D_LU)
  `RV64G_INSTR_DECODER_CMP(156, 32'hFFF0707F, 32'hF2000053, i_FMV_D_X)
  `RV64G_INSTR_DECODER_CMP(157, 32'hFFFFFFFF, 32'h30200073, i_MRET)
  `RV64G_INSTR_DECODER_CMP(158, 32'hFFFFFFFF, 32'h10500073, i_WFI)

  // final AND reduction
  and_reduction #(
      .NUM_ELEM  (157),
      .ELEM_WIDTH(20)
  ) u_and_reduction (
      .ins_i(i_func),
      .out_o(i_func_final)
  );

  // extract function
  assign cmd_o.func = func_t'(i_func_final[7:0]);

  // select rd int/float
  always_comb begin
    case ({
      i_func_final[11], i_func_final[8]
    })
      default cmd_o.rd = '0;
      'b01: cmd_o.rd = {1'b0, rd};
      'b10: cmd_o.rd = {1'b1, rd};
    endcase
  end

  // select rs1 int/float
  always_comb begin
    case ({
      i_func_final[12], i_func_final[9]
    })
      default cmd_o.rs1 = '0;
      'b01: cmd_o.rs1 = {1'b0, rs1};
      'b10: cmd_o.rs1 = {1'b1, rs1};
    endcase
  end

  // select rs2 int/float
  always_comb begin
    case ({
      i_func_final[13], i_func_final[10]
    })
      default cmd_o.rs2 = '0;
      'b01: cmd_o.rs2 = {1'b0, rs2};
      'b10: cmd_o.rs2 = {1'b1, rs2};
    endcase
  end

  // select rs3 int/float
  always_comb begin
    case (i_func_final[14])
      default cmd_o.rs3 = '0;
      'b1: cmd_o.rs3 = {1'b1, rs3};
    endcase
  end

  // choose immediate source
  always_comb begin
    case (i_func_final[19:16])
      default cmd_o.imm = '0;
      AIMM: cmd_o.imm = aimm;
      BIMM: cmd_o.imm = bimm;
      CIMM: cmd_o.imm = cimm;
      IIMM: cmd_o.imm = iimm;
      JIMM: cmd_o.imm = jimm;
      RIMM: cmd_o.imm = rimm;
      SIMM: cmd_o.imm = simm;
      TIMM: cmd_o.imm = timm;
      UIMM: cmd_o.imm = uimm;
    endcase
  end

  always_comb begin
    cmd_o.pc = pc_i;
  end

  // can jump
  always_comb begin
    cmd_o.jump = i_func_final[15];
  end

  // required register vector generation
  always_comb begin
    cmd_o.reg_req            = {64{cmd_o.jump}};
    cmd_o.reg_req[cmd_o.rd]  = '1;
    cmd_o.reg_req[cmd_o.rs1] = '1;
    cmd_o.reg_req[cmd_o.rs2] = '1;
    cmd_o.reg_req[cmd_o.rs3] = '1;
  end

endmodule
