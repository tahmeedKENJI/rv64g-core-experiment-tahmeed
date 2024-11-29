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
    input logic [XLEN:0] pc_i,

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

  wand [19:0] intr_func;  // intermediate function

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // INSTRUCTION REGISTER INDEX
  assign rd          = code_i[11:7];
  assign rs1         = code_i[19:15];
  assign rs2         = code_i[24:20];
  assign rs3         = code_i[31:27];

  // SHIFT AMOUNT
  assign aimm[5:0]   = code_i[25:20];
  assign aimm[63:6]  = '0;

  // BTYPE INSTRUCTION IMMEDIATE
  assign bimm[0]     = '0;
  assign bimm[4:1]   = code_i[11:8];
  assign bimm[10:5]  = code_i[30:25];
  assign bimm[11]    = code_i[7];
  assign bimm[12]    = code_i[31];
  assign bimm[63:13] = {51{code_i[31]}};

  // CSR INSTRUCTION IMMEDIATE
  assign cimm[11:0]  = code_i[31:20];
  assign cimm[16:12] = code_i[19:15];
  assign cimm[63:17] = '0;

  // ITYPE INSTRUCTION IMMEDIATE
  assign iimm[11:0]  = code_i[31:20];
  assign iimm[63:12] = {52{code_i[31]}};

  // JTYPE INSTRUCTION IMMEDIATE
  assign jimm[0]     = '0;
  assign jimm[10:1]  = code_i[30:21];
  assign jimm[19:12] = code_i[19:12];
  assign jimm[11]    = code_i[20];
  assign jimm[20]    = code_i[31];
  assign jimm[63:21] = {43{code_i[31]}};

  // FLOATING ROUND MODE IMMEDIATE
  assign rimm[2:0]   = code_i[14:12];
  assign rimm[63:3]  = '0;

  // RTYPE INSTRUCTION IMMEDIATE
  assign simm[4:0]   = code_i[11:7];
  assign simm[11:5]  = code_i[31:25];
  assign simm[63:12] = {52{code_i[31]}};

  // ATOMICS IMMEDIATE
  assign timm[0]     = code_i[25:25];
  assign timm[1]     = code_i[26:26];
  assign timm[63:2]  = '0;

  // UTYPE INSTRUCTION IMMEDIATE
  assign uimm[11:0]  = code_i[31:12];
  assign uimm[63:12] = '0;

  // Decode the instruction and set the intermediate function
  assign intr_func   = ((code_i & 32'h0000007F) == 32'h00000037) ? i_LUI : '1;
  assign intr_func   = ((code_i & 32'h0000007F) == 32'h00000017) ? i_AUIPC : '1;
  assign intr_func   = ((code_i & 32'h0000007F) == 32'h0000006F) ? i_JAL : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00000067) ? i_JALR : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00000063) ? i_BEQ : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00001063) ? i_BNE : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00004063) ? i_BLT : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00005063) ? i_BGE : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00006063) ? i_BLTU : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00007063) ? i_BGEU : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00000003) ? i_LB : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00001003) ? i_LH : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00002003) ? i_LW : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00004003) ? i_LBU : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00005003) ? i_LHU : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00000023) ? i_SB : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00001023) ? i_SH : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00002023) ? i_SW : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00000013) ? i_ADDI : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00002013) ? i_SLTI : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00003013) ? i_SLTIU : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00004013) ? i_XORI : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00006013) ? i_ORI : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00007013) ? i_ANDI : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00001013) ? i_SLLI : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00005013) ? i_SRLI : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h40005013) ? i_SRAI : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00000033) ? i_ADD : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h40000033) ? i_SUB : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00001033) ? i_SLL : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00002033) ? i_SLT : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00003033) ? i_SLTU : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00004033) ? i_XOR : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00005033) ? i_SRL : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h40005033) ? i_SRA : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00006033) ? i_OR : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h00007033) ? i_AND : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h0000000F) ? i_FENCE : '1;
  assign intr_func   = ((code_i & 32'hFFFFFFFF) == 32'h8330000F) ? i_FENCE_TSO : '1;
  assign intr_func   = ((code_i & 32'hFFFFFFFF) == 32'h0100000F) ? i_PAUSE : '1;
  assign intr_func   = ((code_i & 32'hFFFFFFFF) == 32'h00000073) ? i_ECALL : '1;
  assign intr_func   = ((code_i & 32'hFFFFFFFF) == 32'h00100073) ? i_EBREAK : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00006003) ? i_LWU : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00003003) ? i_LD : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00003023) ? i_SD : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h0000001B) ? i_ADDIW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0000101B) ? i_SLLIW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0000501B) ? i_SRLIW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h4000501B) ? i_SRAIW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0000003B) ? i_ADDW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h4000003B) ? i_SUBW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0000103B) ? i_SLLW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0000503B) ? i_SRLW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h4000503B) ? i_SRAW : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00001073) ? i_CSRRW : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00002073) ? i_CSRRS : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00003073) ? i_CSRRC : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00005073) ? i_CSRRWI : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00006073) ? i_CSRRSI : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00007073) ? i_CSRRCI : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h02000033) ? i_MUL : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h02001033) ? i_MULH : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h02002033) ? i_MULHSU : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h02003033) ? i_MULHU : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h02004033) ? i_DIV : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h02005033) ? i_DIVU : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h02006033) ? i_REM : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h02007033) ? i_REMU : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0200003B) ? i_MULW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0200403B) ? i_DIVW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0200503B) ? i_DIVUW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0200603B) ? i_REMW : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h0200703B) ? i_REMUW : '1;
  assign intr_func   = ((code_i & 32'hF9F0707F) == 32'h1000202F) ? i_LR_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h1800202F) ? i_SC_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h0800202F) ? i_AMOSWAP_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h0000202F) ? i_AMOADD_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h2000202F) ? i_AMOXOR_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h6000202F) ? i_AMOAND_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h4000202F) ? i_AMOOR_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h8000202F) ? i_AMOMIN_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'hA000202F) ? i_AMOMAX_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'hC000202F) ? i_AMOMINU_W : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'hE000202F) ? i_AMOMAXU_W : '1;
  assign intr_func   = ((code_i & 32'hF9F0707F) == 32'h1000302F) ? i_LR_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h1800302F) ? i_SC_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h0800302F) ? i_AMOSWAP_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h0000302F) ? i_AMOADD_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h2000302F) ? i_AMOXOR_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h6000302F) ? i_AMOAND_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h4000302F) ? i_AMOOR_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'h8000302F) ? i_AMOMIN_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'hA000302F) ? i_AMOMAX_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'hC000302F) ? i_AMOMINU_D : '1;
  assign intr_func   = ((code_i & 32'hF800707F) == 32'hE000302F) ? i_AMOMAXU_D : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00002007) ? i_FLW : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00002027) ? i_FSW : '1;
  assign intr_func   = ((code_i & 32'h0600007F) == 32'h00000043) ? i_FMADD_S : '1;
  assign intr_func   = ((code_i & 32'h0600007F) == 32'h00000047) ? i_FMSUB_S : '1;
  assign intr_func   = ((code_i & 32'h0600007F) == 32'h0000004B) ? i_FNMSUB_S : '1;
  assign intr_func   = ((code_i & 32'h0600007F) == 32'h0000004F) ? i_FNMADD_S : '1;
  assign intr_func   = ((code_i & 32'hFE00007F) == 32'h00000053) ? i_FADD_S : '1;
  assign intr_func   = ((code_i & 32'hFE00007F) == 32'h08000053) ? i_FSUB_S : '1;
  assign intr_func   = ((code_i & 32'hFE00007F) == 32'h10000053) ? i_FMUL_S : '1;
  assign intr_func   = ((code_i & 32'hFE00007F) == 32'h18000053) ? i_FDIV_S : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'h58000053) ? i_FSQRT_S : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h20000053) ? i_FSGNJ_S : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h20001053) ? i_FSGNJN_S : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h20002053) ? i_FSGNJX_S : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h28000053) ? i_FMIN_S : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h28001053) ? i_FMAX_S : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hC0000053) ? i_FCVT_W_S : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hC0100053) ? i_FCVT_WU_S : '1;
  assign intr_func   = ((code_i & 32'hFFF0707F) == 32'hE0000053) ? i_FMV_X_W : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'hA0002053) ? i_FEQ_S : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'hA0001053) ? i_FLT_S : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'hA0000053) ? i_FLE_S : '1;
  assign intr_func   = ((code_i & 32'hFFF0707F) == 32'hE0001053) ? i_FCLASS_S : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hD0000053) ? i_FCVT_S_W : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hD0100053) ? i_FCVT_S_WU : '1;
  assign intr_func   = ((code_i & 32'hFFF0707F) == 32'hF0000053) ? i_FMV_W_X : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hC0200053) ? i_FCVT_L_S : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hC0300053) ? i_FCVT_LU_S : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hD0200053) ? i_FCVT_S_L : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hD0300053) ? i_FCVT_S_LU : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00003007) ? i_FLD : '1;
  assign intr_func   = ((code_i & 32'h0000707F) == 32'h00003027) ? i_FSD : '1;
  assign intr_func   = ((code_i & 32'h0600007F) == 32'h02000043) ? i_FMADD_D : '1;
  assign intr_func   = ((code_i & 32'h0600007F) == 32'h02000047) ? i_FMSUB_D : '1;
  assign intr_func   = ((code_i & 32'h0600007F) == 32'h0200004B) ? i_FNMSUB_D : '1;
  assign intr_func   = ((code_i & 32'h0600007F) == 32'h0200004F) ? i_FNMADD_D : '1;
  assign intr_func   = ((code_i & 32'hFE00007F) == 32'h02000053) ? i_FADD_D : '1;
  assign intr_func   = ((code_i & 32'hFE00007F) == 32'h0A000053) ? i_FSUB_D : '1;
  assign intr_func   = ((code_i & 32'hFE00007F) == 32'h12000053) ? i_FMUL_D : '1;
  assign intr_func   = ((code_i & 32'hFE00007F) == 32'h1A000053) ? i_FDIV_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'h5A000053) ? i_FSQRT_D : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h22000053) ? i_FSGNJ_D : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h22001053) ? i_FSGNJN_D : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h22002053) ? i_FSGNJX_D : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h2A000053) ? i_FMIN_D : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'h2A001053) ? i_FMAX_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'h40100053) ? i_FCVT_S_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'h42000053) ? i_FCVT_D_S : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'hA2002053) ? i_FEQ_D : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'hA2001053) ? i_FLT_D : '1;
  assign intr_func   = ((code_i & 32'hFE00707F) == 32'hA2000053) ? i_FLE_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0707F) == 32'hE2001053) ? i_FCLASS_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hC2000053) ? i_FCVT_W_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hC2100053) ? i_FCVT_WU_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hD2000053) ? i_FCVT_D_W : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hD2100053) ? i_FCVT_D_WU : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hC2200053) ? i_FCVT_L_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hC2300053) ? i_FCVT_LU_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0707F) == 32'hE2000053) ? i_FMV_X_D : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hD2200053) ? i_FCVT_D_L : '1;
  assign intr_func   = ((code_i & 32'hFFF0007F) == 32'hD2300053) ? i_FCVT_D_LU : '1;
  assign intr_func   = ((code_i & 32'hFFF0707F) == 32'hF2000053) ? i_FMV_D_X : '1;

  // extract function
  assign cmd_o.func  = func_t'(intr_func[7:0]);

  // select rd int/float
  always_comb begin
    case ({
      intr_func[11], intr_func[8]
    })
      default cmd_o.rd = '0;
      'b01: cmd_o.rd = {1'b0, rd};
      'b10: cmd_o.rd = {1'b1, rd};
    endcase
  end

  // select rs1 int/float
  always_comb begin
    case ({
      intr_func[12], intr_func[9]
    })
      default cmd_o.rs1 = '0;
      'b01: cmd_o.rs1 = {1'b0, rs1};
      'b10: cmd_o.rs1 = {1'b1, rs1};
    endcase
  end

  // select rs2 int/float
  always_comb begin
    case ({
      intr_func[13], intr_func[10]
    })
      default cmd_o.rs2 = '0;
      'b01: cmd_o.rs2 = {1'b0, rs2};
      'b10: cmd_o.rs2 = {1'b1, rs2};
    endcase
  end

  // select rs3 int/float
  always_comb begin
    case (intr_func[14])
      default cmd_o.rs3 = '0;
      'b1: cmd_o.rs3 = {1'b1, rs3};
    endcase
  end

  // choose immediate source
  always_comb begin
    case (intr_func[19:16])
      default cmd_o.imm = '0;
      AIMM: cmd_o.imm = cimm;
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
    cmd_o.jump = intr_func[15];
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
