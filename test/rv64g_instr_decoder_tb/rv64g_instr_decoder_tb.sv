/*
Description
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
Co-Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module rv64g_instr_decoder_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"
  `include "rv64g_pkg.sv"

  import rv64g_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int Clen = 32;
  localparam int NumInstr = 158;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 2ns, 2ns)

  logic [Clen-1:0] code_i;
  decoded_instr_t cmd_o;
  logic [XLEN-1:0] pc_i;
  decoded_instr_t exp_cmd_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  bit pc_ok;
  bit func_ok;
  bit rd_ok;
  bit rs1_ok;
  bit rs2_ok;
  bit rs3_ok;
  bit jump_ok;
  bit imm_ok;
  bit reg_req_ok;
  int tx_pc;
  int tx_func;
  int tx_rd;
  int tx_rs1;
  int tx_rs2;
  int tx_rs3;
  int tx_jump;
  int tx_imm;
  int tx_reg_req;
  int tx_all;

  logic [256-1:0] instr_check;
  int count = 0;

  logic [11:0] reg_state;
  imm_src_t imm_src_infer;
  logic [XLEN-1:0] stand_imm;  // stand-in immediate

  event e_all_instr_checked;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // update the program counter
  always_comb begin : pc
    exp_cmd_o.pc = pc_i;
  end

  // determine the instruction
  always_comb begin : func
    exp_cmd_o.func = INVALID;
    casez (code_i)
      32'bzzzzzzzzzzzzzzzzzzzzzzzzz0010111: exp_cmd_o.func = AUIPC;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzz1101111: exp_cmd_o.func = JAL;
      32'bzzzzzzzzzzzzzzzzz000zzzzz1100111: exp_cmd_o.func = JALR;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzz0110111: exp_cmd_o.func = LUI;
      32'bzzzzzzzzzzzzzzzzz000zzzzz1100011: exp_cmd_o.func = BEQ;
      32'bzzzzzzzzzzzzzzzzz001zzzzz1100011: exp_cmd_o.func = BNE;
      32'bzzzzzzzzzzzzzzzzz100zzzzz1100011: exp_cmd_o.func = BLT;
      32'bzzzzzzzzzzzzzzzzz101zzzzz1100011: exp_cmd_o.func = BGE;
      32'bzzzzzzzzzzzzzzzzz110zzzzz1100011: exp_cmd_o.func = BLTU;
      32'bzzzzzzzzzzzzzzzzz111zzzzz1100011: exp_cmd_o.func = BGEU;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0000011: exp_cmd_o.func = LB;
      32'bzzzzzzzzzzzzzzzzz001zzzzz0000011: exp_cmd_o.func = LH;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0000011: exp_cmd_o.func = LW;
      32'bzzzzzzzzzzzzzzzzz100zzzzz0000011: exp_cmd_o.func = LBU;
      32'bzzzzzzzzzzzzzzzzz101zzzzz0000011: exp_cmd_o.func = LHU;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0100011: exp_cmd_o.func = SB;
      32'bzzzzzzzzzzzzzzzzz001zzzzz0100011: exp_cmd_o.func = SH;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0100011: exp_cmd_o.func = SW;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0010011: exp_cmd_o.func = ADDI;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0010011: exp_cmd_o.func = SLTI;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0010011: exp_cmd_o.func = SLTIU;
      32'bzzzzzzzzzzzzzzzzz100zzzzz0010011: exp_cmd_o.func = XORI;
      32'bzzzzzzzzzzzzzzzzz110zzzzz0010011: exp_cmd_o.func = ORI;
      32'bzzzzzzzzzzzzzzzzz111zzzzz0010011: exp_cmd_o.func = ANDI;
      32'b0000000zzzzzzzzzz000zzzzz0110011: exp_cmd_o.func = ADD;
      32'b0100000zzzzzzzzzz000zzzzz0110011: exp_cmd_o.func = SUB;
      32'b0000000zzzzzzzzzz001zzzzz0110011: exp_cmd_o.func = SLL;
      32'b0000000zzzzzzzzzz010zzzzz0110011: exp_cmd_o.func = SLT;
      32'b0000000zzzzzzzzzz011zzzzz0110011: exp_cmd_o.func = SLTU;
      32'b0000000zzzzzzzzzz100zzzzz0110011: exp_cmd_o.func = XOR;
      32'b0000000zzzzzzzzzz101zzzzz0110011: exp_cmd_o.func = SRL;
      32'b0100000zzzzzzzzzz101zzzzz0110011: exp_cmd_o.func = SRA;
      32'b0000000zzzzzzzzzz110zzzzz0110011: exp_cmd_o.func = OR;
      32'b0000000zzzzzzzzzz111zzzzz0110011: exp_cmd_o.func = AND;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0001111: exp_cmd_o.func = FENCE;
      32'b10000011001100000000000000001111: exp_cmd_o.func = FENCE_TSO;
      32'b00000001000000000000000000001111: exp_cmd_o.func = PAUSE;
      32'b00000000000000000000000001110011: exp_cmd_o.func = ECALL;
      32'b00000000000100000000000001110011: exp_cmd_o.func = EBREAK;
      32'bzzzzzzzzzzzzzzzzz110zzzzz0000011: exp_cmd_o.func = LWU;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0000011: exp_cmd_o.func = LD;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0100011: exp_cmd_o.func = SD;
      32'b000000zzzzzzzzzzz001zzzzz0010011: exp_cmd_o.func = SLLI;
      32'b000000zzzzzzzzzzz101zzzzz0010011: exp_cmd_o.func = SRLI;
      32'b010000zzzzzzzzzzz101zzzzz0010011: exp_cmd_o.func = SRAI;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0011011: exp_cmd_o.func = ADDIW;
      32'b0000000zzzzzzzzzz001zzzzz0011011: exp_cmd_o.func = SLLIW;
      32'b0000000zzzzzzzzzz101zzzzz0011011: exp_cmd_o.func = SRLIW;
      32'b0100000zzzzzzzzzz101zzzzz0011011: exp_cmd_o.func = SRAIW;
      32'b0000000zzzzzzzzzz000zzzzz0111011: exp_cmd_o.func = ADDW;
      32'b0100000zzzzzzzzzz000zzzzz0111011: exp_cmd_o.func = SUBW;
      32'b0000000zzzzzzzzzz001zzzzz0111011: exp_cmd_o.func = SLLW;
      32'b0000000zzzzzzzzzz101zzzzz0111011: exp_cmd_o.func = SRLW;
      32'b0100000zzzzzzzzzz101zzzzz0111011: exp_cmd_o.func = SRAW;
      32'bzzzzzzzzzzzzzzzzz001zzzzz1110011: exp_cmd_o.func = CSRRW;
      32'bzzzzzzzzzzzzzzzzz010zzzzz1110011: exp_cmd_o.func = CSRRS;
      32'bzzzzzzzzzzzzzzzzz011zzzzz1110011: exp_cmd_o.func = CSRRC;
      32'bzzzzzzzzzzzzzzzzz101zzzzz1110011: exp_cmd_o.func = CSRRWI;
      32'bzzzzzzzzzzzzzzzzz110zzzzz1110011: exp_cmd_o.func = CSRRSI;
      32'bzzzzzzzzzzzzzzzzz111zzzzz1110011: exp_cmd_o.func = CSRRCI;
      32'b0000001zzzzzzzzzz000zzzzz0110011: exp_cmd_o.func = MUL;
      32'b0000001zzzzzzzzzz001zzzzz0110011: exp_cmd_o.func = MULH;
      32'b0000001zzzzzzzzzz010zzzzz0110011: exp_cmd_o.func = MULHSU;
      32'b0000001zzzzzzzzzz011zzzzz0110011: exp_cmd_o.func = MULHU;
      32'b0000001zzzzzzzzzz100zzzzz0110011: exp_cmd_o.func = DIV;
      32'b0000001zzzzzzzzzz101zzzzz0110011: exp_cmd_o.func = DIVU;
      32'b0000001zzzzzzzzzz110zzzzz0110011: exp_cmd_o.func = REM;
      32'b0000001zzzzzzzzzz111zzzzz0110011: exp_cmd_o.func = REMU;
      32'b0000001zzzzzzzzzz000zzzzz0111011: exp_cmd_o.func = MULW;
      32'b0000001zzzzzzzzzz100zzzzz0111011: exp_cmd_o.func = DIVW;
      32'b0000001zzzzzzzzzz101zzzzz0111011: exp_cmd_o.func = DIVUW;
      32'b0000001zzzzzzzzzz110zzzzz0111011: exp_cmd_o.func = REMW;
      32'b0000001zzzzzzzzzz111zzzzz0111011: exp_cmd_o.func = REMUW;
      32'b00010zz00000zzzzz010zzzzz0101111: exp_cmd_o.func = LR_W;
      32'b00011zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = SC_W;
      32'b00001zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOSWAP_W;
      32'b00000zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOADD_W;
      32'b00100zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOXOR_W;
      32'b01100zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOAND_W;
      32'b01000zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOOR_W;
      32'b10000zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOMIN_W;
      32'b10100zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOMAX_W;
      32'b11000zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOMINU_W;
      32'b11100zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func = AMOMAXU_W;
      32'b00010zz00000zzzzz011zzzzz0101111: exp_cmd_o.func = LR_D;
      32'b00011zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = SC_D;
      32'b00001zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOSWAP_D;
      32'b00000zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOADD_D;
      32'b00100zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOXOR_D;
      32'b01100zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOAND_D;
      32'b01000zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOOR_D;
      32'b10000zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOMIN_D;
      32'b10100zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOMAX_D;
      32'b11000zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOMINU_D;
      32'b11100zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func = AMOMAXU_D;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0000111: exp_cmd_o.func = FLW;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0100111: exp_cmd_o.func = FSW;
      32'bzzzzz00zzzzzzzzzzzzzzzzzz1000011: exp_cmd_o.func = FMADD_S;
      32'bzzzzz00zzzzzzzzzzzzzzzzzz1000111: exp_cmd_o.func = FMSUB_S;
      32'bzzzzz00zzzzzzzzzzzzzzzzzz1001011: exp_cmd_o.func = FNMSUB_S;
      32'bzzzzz00zzzzzzzzzzzzzzzzzz1001111: exp_cmd_o.func = FNMADD_S;
      32'b0000000zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func = FADD_S;
      32'b0000100zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func = FSUB_S;
      32'b0001000zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func = FMUL_S;
      32'b0001100zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func = FDIV_S;
      32'b010110000000zzzzzzzzzzzzz1010011: exp_cmd_o.func = FSQRT_S;
      32'b0010000zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func = FSGNJ_S;
      32'b0010000zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func = FSGNJN_S;
      32'b0010000zzzzzzzzzz010zzzzz1010011: exp_cmd_o.func = FSGNJX_S;
      32'b0010100zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func = FMIN_S;
      32'b0010100zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func = FMAX_S;
      32'b110000000000zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_W_S;
      32'b110000000001zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_WU_S;
      32'b111000000000zzzzz000zzzzz1010011: exp_cmd_o.func = FMV_X_W;
      32'b1010000zzzzzzzzzz010zzzzz1010011: exp_cmd_o.func = FEQ_S;
      32'b1010000zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func = FLT_S;
      32'b1010000zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func = FLE_S;
      32'b111000000000zzzzz001zzzzz1010011: exp_cmd_o.func = FCLASS_S;
      32'b110100000000zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_S_W;
      32'b110100000001zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_S_WU;
      32'b111100000000zzzzz000zzzzz1010011: exp_cmd_o.func = FMV_W_X;
      32'b110000000010zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_L_S;
      32'b110000000011zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_LU_S;
      32'b110100000010zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_S_L;
      32'b110100000011zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_S_LU;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0000111: exp_cmd_o.func = FLD;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0100111: exp_cmd_o.func = FSD;
      32'bzzzzz01zzzzzzzzzzzzzzzzzz1000011: exp_cmd_o.func = FMADD_D;
      32'bzzzzz01zzzzzzzzzzzzzzzzzz1000111: exp_cmd_o.func = FMSUB_D;
      32'bzzzzz01zzzzzzzzzzzzzzzzzz1001011: exp_cmd_o.func = FNMSUB_D;
      32'bzzzzz01zzzzzzzzzzzzzzzzzz1001111: exp_cmd_o.func = FNMADD_D;
      32'b0000001zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func = FADD_D;
      32'b0000101zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func = FSUB_D;
      32'b0001001zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func = FMUL_D;
      32'b0001101zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func = FDIV_D;
      32'b010110100000zzzzzzzzzzzzz1010011: exp_cmd_o.func = FSQRT_D;
      32'b0010001zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func = FSGNJ_D;
      32'b0010001zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func = FSGNJN_D;
      32'b0010001zzzzzzzzzz010zzzzz1010011: exp_cmd_o.func = FSGNJX_D;
      32'b0010101zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func = FMIN_D;
      32'b0010101zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func = FMAX_D;
      32'b010000000001zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_S_D;
      32'b010000100000zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_D_S;
      32'b1010001zzzzzzzzzz010zzzzz1010011: exp_cmd_o.func = FEQ_D;
      32'b1010001zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func = FLT_D;
      32'b1010001zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func = FLE_D;
      32'b111000100000zzzzz001zzzzz1010011: exp_cmd_o.func = FCLASS_D;
      32'b110000100000zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_W_D;
      32'b110000100001zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_WU_D;
      32'b110100100000zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_D_W;
      32'b110100100001zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_D_WU;
      32'b110000100010zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_L_D;
      32'b110000100011zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_LU_D;
      32'b111000100000zzzzz000zzzzz1010011: exp_cmd_o.func = FMV_X_D;
      32'b110100100010zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_D_L;
      32'b110100100011zzzzzzzzzzzzz1010011: exp_cmd_o.func = FCVT_D_LU;
      32'b111100100000zzzzz000zzzzz1010011: exp_cmd_o.func = FMV_D_X;
      32'h30200073:                         exp_cmd_o.func = MRET;
      32'h10500073:                         exp_cmd_o.func = WFI;
      default:                              exp_cmd_o.func = INVALID;
    endcase
  end

  // check for jump condition
  always_comb begin : jump
    string func_name = exp_cmd_o.func.name();
    exp_cmd_o.jump =
     (func_name == "JAL")
    |(func_name == "JALR")
    |(func_name == "BEQ")
    |(func_name == "BNE")
    |(func_name == "BLT")
    |(func_name == "BGE")
    |(func_name == "BLTU")
    |(func_name == "BGEU")
    |(func_name == "MRET")
    |(func_name == "WFI");
  end

  // determine register state for each instruction
  always_comb begin : register_state
    unique case (exp_cmd_o.func)
      LUI:       reg_state = 12'o1000;
      AUIPC:     reg_state = 12'o1000;
      JAL:       reg_state = 12'o1000;
      JALR:      reg_state = 12'o1100;
      BEQ:       reg_state = 12'o0110;
      BNE:       reg_state = 12'o0110;
      BLT:       reg_state = 12'o0110;
      BGE:       reg_state = 12'o0110;
      BLTU:      reg_state = 12'o0110;
      BGEU:      reg_state = 12'o0110;  // checked
      LB:        reg_state = 12'o1100;
      LH:        reg_state = 12'o1100;
      LW:        reg_state = 12'o1100;
      LBU:       reg_state = 12'o1100;
      LHU:       reg_state = 12'o1100;  // checked
      SB:        reg_state = 12'o0110;
      SH:        reg_state = 12'o0110;
      SW:        reg_state = 12'o0110;  // checked
      ADDI:      reg_state = 12'o1100;
      SLTI:      reg_state = 12'o1100;
      SLTIU:     reg_state = 12'o1100;
      XORI:      reg_state = 12'o1100;
      ORI:       reg_state = 12'o1100;
      ANDI:      reg_state = 12'o1100;
      SLLI:      reg_state = 12'o1100;
      SRLI:      reg_state = 12'o1100;
      SRAI:      reg_state = 12'o1100;  // checked
      ADD:       reg_state = 12'o1110;
      SUB:       reg_state = 12'o1110;
      SLL:       reg_state = 12'o1110;
      SLT:       reg_state = 12'o1110;
      SLTU:      reg_state = 12'o1110;
      XOR:       reg_state = 12'o1110;
      SRL:       reg_state = 12'o1110;
      SRA:       reg_state = 12'o1110;
      OR:        reg_state = 12'o1110;
      AND:       reg_state = 12'o1110;
      FENCE:     reg_state = 12'o1100;
      FENCE_TSO: reg_state = 12'o0000;
      PAUSE:     reg_state = 12'o0000;
      ECALL:     reg_state = 12'o0000;
      EBREAK:    reg_state = 12'o0000;
      LWU:       reg_state = 12'o1100;
      LD:        reg_state = 12'o1100;
      SD:        reg_state = 12'o0110;
      ADDIW:     reg_state = 12'o1100;
      SLLIW:     reg_state = 12'o1100;
      SRLIW:     reg_state = 12'o1100;
      SRAIW:     reg_state = 12'o1100;
      ADDW:      reg_state = 12'o1110;
      SUBW:      reg_state = 12'o1110;
      SLLW:      reg_state = 12'o1110;
      SRLW:      reg_state = 12'o1110;
      SRAW:      reg_state = 12'o1110;
      CSRRW:     reg_state = 12'o1100;
      CSRRS:     reg_state = 12'o1100;
      CSRRC:     reg_state = 12'o1100;
      CSRRWI:    reg_state = 12'o1000;
      CSRRSI:    reg_state = 12'o1000;
      CSRRCI:    reg_state = 12'o1000;
      MUL:       reg_state = 12'o1110;
      MULH:      reg_state = 12'o1110;
      MULHSU:    reg_state = 12'o1110;
      MULHU:     reg_state = 12'o1110;
      DIV:       reg_state = 12'o1110;
      DIVU:      reg_state = 12'o1110;
      REM:       reg_state = 12'o1110;
      REMU:      reg_state = 12'o1110;
      MULW:      reg_state = 12'o1110;
      DIVW:      reg_state = 12'o1110;
      DIVUW:     reg_state = 12'o1110;
      REMW:      reg_state = 12'o1110;
      REMUW:     reg_state = 12'o1110;
      LR_W:      reg_state = 12'o1100;
      SC_W:      reg_state = 12'o1110;
      AMOSWAP_W: reg_state = 12'o1110;
      AMOADD_W:  reg_state = 12'o1110;
      AMOXOR_W:  reg_state = 12'o1110;
      AMOAND_W:  reg_state = 12'o1110;
      AMOOR_W:   reg_state = 12'o1110;
      AMOMIN_W:  reg_state = 12'o1110;
      AMOMAX_W:  reg_state = 12'o1110;
      AMOMINU_W: reg_state = 12'o1110;
      AMOMAXU_W: reg_state = 12'o1110;
      LR_D:      reg_state = 12'o1100;
      SC_D:      reg_state = 12'o1110;
      AMOSWAP_D: reg_state = 12'o1110;
      AMOADD_D:  reg_state = 12'o1110;
      AMOXOR_D:  reg_state = 12'o1110;
      AMOAND_D:  reg_state = 12'o1110;
      AMOOR_D:   reg_state = 12'o1110;
      AMOMIN_D:  reg_state = 12'o1110;
      AMOMAX_D:  reg_state = 12'o1110;
      AMOMINU_D: reg_state = 12'o1110;
      AMOMAXU_D: reg_state = 12'o1110;
      FLW:       reg_state = 12'o2100;
      FSW:       reg_state = 12'o0120;
      FADD_S:    reg_state = 12'o2220;
      FSUB_S:    reg_state = 12'o2220;
      FMUL_S:    reg_state = 12'o2220;
      FDIV_S:    reg_state = 12'o2220;
      FSQRT_S:   reg_state = 12'o2200;
      FMIN_S:    reg_state = 12'o2220;
      FMAX_S:    reg_state = 12'o2220;
      FMADD_S:   reg_state = 12'o2222;
      FMSUB_S:   reg_state = 12'o2222;
      FNMADD_S:  reg_state = 12'o2222;
      FNMSUB_S:  reg_state = 12'o2222;
      FCVT_W_S:  reg_state = 12'o1200;
      FCVT_WU_S: reg_state = 12'o1200;
      FCVT_L_S:  reg_state = 12'o1200;
      FCVT_LU_S: reg_state = 12'o1200;
      FCVT_S_W:  reg_state = 12'o2100;
      FCVT_S_WU: reg_state = 12'o2100;
      FCVT_S_L:  reg_state = 12'o2100;
      FCVT_S_LU: reg_state = 12'o2100;
      FSGNJ_S:   reg_state = 12'o2220;
      FSGNJN_S:  reg_state = 12'o2220;
      FSGNJX_S:  reg_state = 12'o2220;
      FMV_X_W:   reg_state = 12'o1200;
      FMV_W_X:   reg_state = 12'o2100;
      FEQ_S:     reg_state = 12'o1220;
      FLT_S:     reg_state = 12'o1220;
      FLE_S:     reg_state = 12'o1220;
      FCLASS_S:  reg_state = 12'o1200;
      FLD:       reg_state = 12'o2100;
      FSD:       reg_state = 12'o0120;
      FADD_D:    reg_state = 12'o2220;
      FSUB_D:    reg_state = 12'o2220;
      FMUL_D:    reg_state = 12'o2220;
      FDIV_D:    reg_state = 12'o2220;
      FSQRT_D:   reg_state = 12'o2200;
      FMIN_D:    reg_state = 12'o2220;
      FMAX_D:    reg_state = 12'o2220;
      FMADD_D:   reg_state = 12'o2222;
      FMSUB_D:   reg_state = 12'o2222;
      FNMADD_D:  reg_state = 12'o2222;
      FNMSUB_D:  reg_state = 12'o2222;
      FCVT_W_D:  reg_state = 12'o1200;
      FCVT_WU_D: reg_state = 12'o1200;
      FCVT_L_D:  reg_state = 12'o1200;
      FCVT_LU_D: reg_state = 12'o1200;
      FCVT_D_W:  reg_state = 12'o2100;
      FCVT_D_WU: reg_state = 12'o2100;
      FCVT_D_L:  reg_state = 12'o2100;
      FCVT_D_LU: reg_state = 12'o2100;
      FCVT_S_D:  reg_state = 12'o2210;
      FCVT_D_S:  reg_state = 12'o2210;
      FSGNJ_D:   reg_state = 12'o2220;
      FSGNJN_D:  reg_state = 12'o2220;
      FSGNJX_D:  reg_state = 12'o2220;
      FMV_X_D:   reg_state = 12'o1200;
      FMV_D_X:   reg_state = 12'o2100;
      FEQ_D:     reg_state = 12'o1220;
      FLT_D:     reg_state = 12'o1220;
      FLE_D:     reg_state = 12'o1220;
      FCLASS_D:  reg_state = 12'o1200;
      MRET:      reg_state = 12'o0000;
      WFI:       reg_state = 12'o0000;
      INVALID:   reg_state = 12'o0000;
    endcase
  end

  // determine type of immediate per instruction
  always_comb begin : immediate_mapping
    case (exp_cmd_o.func)
      LUI:       imm_src_infer = UIMM;
      AUIPC:     imm_src_infer = UIMM;
      JAL:       imm_src_infer = JIMM;
      JALR:      imm_src_infer = IIMM;
      BEQ:       imm_src_infer = BIMM;
      BNE:       imm_src_infer = BIMM;
      BLT:       imm_src_infer = BIMM;
      BGE:       imm_src_infer = BIMM;
      BLTU:      imm_src_infer = BIMM;
      BGEU:      imm_src_infer = BIMM;
      LB:        imm_src_infer = IIMM;
      LH:        imm_src_infer = IIMM;
      LW:        imm_src_infer = IIMM;
      LBU:       imm_src_infer = IIMM;
      LHU:       imm_src_infer = IIMM;
      SB:        imm_src_infer = SIMM;
      SH:        imm_src_infer = SIMM;
      SW:        imm_src_infer = SIMM;
      ADDI:      imm_src_infer = IIMM;
      SLTI:      imm_src_infer = IIMM;
      SLTIU:     imm_src_infer = IIMM;
      XORI:      imm_src_infer = IIMM;
      ORI:       imm_src_infer = IIMM;
      ANDI:      imm_src_infer = IIMM;
      SLLI:      imm_src_infer = AIMM;
      SRLI:      imm_src_infer = AIMM;
      SRAI:      imm_src_infer = AIMM;
      ADD:       imm_src_infer = NONE;
      SUB:       imm_src_infer = NONE;
      SLL:       imm_src_infer = NONE;
      SLT:       imm_src_infer = NONE;
      SLTU:      imm_src_infer = NONE;
      XOR:       imm_src_infer = NONE;
      SRL:       imm_src_infer = NONE;
      SRA:       imm_src_infer = NONE;
      OR:        imm_src_infer = NONE;
      AND:       imm_src_infer = NONE;
      FENCE:     imm_src_infer = IIMM;
      FENCE_TSO: imm_src_infer = IIMM;
      PAUSE:     imm_src_infer = IIMM;
      ECALL:     imm_src_infer = IIMM;
      EBREAK:    imm_src_infer = IIMM;
      LWU:       imm_src_infer = IIMM;
      LD:        imm_src_infer = IIMM;
      SD:        imm_src_infer = SIMM;
      ADDIW:     imm_src_infer = IIMM;
      SLLIW:     imm_src_infer = AIMM;
      SRLIW:     imm_src_infer = AIMM;
      SRAIW:     imm_src_infer = AIMM;
      ADDW:      imm_src_infer = NONE;
      SUBW:      imm_src_infer = NONE;
      SLLW:      imm_src_infer = NONE;
      SRLW:      imm_src_infer = NONE;
      SRAW:      imm_src_infer = NONE;
      CSRRW:     imm_src_infer = IIMM;
      CSRRS:     imm_src_infer = IIMM;
      CSRRC:     imm_src_infer = IIMM;
      CSRRWI:    imm_src_infer = CIMM;
      CSRRSI:    imm_src_infer = CIMM;
      CSRRCI:    imm_src_infer = CIMM;
      MUL:       imm_src_infer = NONE;
      MULH:      imm_src_infer = NONE;
      MULHSU:    imm_src_infer = NONE;
      MULHU:     imm_src_infer = NONE;
      DIV:       imm_src_infer = NONE;
      DIVU:      imm_src_infer = NONE;
      REM:       imm_src_infer = NONE;
      REMU:      imm_src_infer = NONE;
      MULW:      imm_src_infer = NONE;
      DIVW:      imm_src_infer = NONE;
      DIVUW:     imm_src_infer = NONE;
      REMW:      imm_src_infer = NONE;
      REMUW:     imm_src_infer = NONE;
      LR_W:      imm_src_infer = TIMM;
      SC_W:      imm_src_infer = TIMM;
      AMOSWAP_W: imm_src_infer = TIMM;
      AMOADD_W:  imm_src_infer = TIMM;
      AMOXOR_W:  imm_src_infer = TIMM;
      AMOAND_W:  imm_src_infer = TIMM;
      AMOOR_W:   imm_src_infer = TIMM;
      AMOMIN_W:  imm_src_infer = TIMM;
      AMOMAX_W:  imm_src_infer = TIMM;
      AMOMINU_W: imm_src_infer = TIMM;
      AMOMAXU_W: imm_src_infer = TIMM;
      LR_D:      imm_src_infer = TIMM;
      SC_D:      imm_src_infer = TIMM;
      AMOSWAP_D: imm_src_infer = TIMM;
      AMOADD_D:  imm_src_infer = TIMM;
      AMOXOR_D:  imm_src_infer = TIMM;
      AMOAND_D:  imm_src_infer = TIMM;
      AMOOR_D:   imm_src_infer = TIMM;
      AMOMIN_D:  imm_src_infer = TIMM;
      AMOMAX_D:  imm_src_infer = TIMM;
      AMOMINU_D: imm_src_infer = TIMM;
      AMOMAXU_D: imm_src_infer = TIMM;
      FLW:       imm_src_infer = IIMM;
      FSW:       imm_src_infer = SIMM;
      FMADD_S:   imm_src_infer = RIMM;
      FMSUB_S:   imm_src_infer = RIMM;
      FNMADD_S:  imm_src_infer = RIMM;
      FNMSUB_S:  imm_src_infer = RIMM;
      FADD_S:    imm_src_infer = RIMM;
      FSUB_S:    imm_src_infer = RIMM;
      FMUL_S:    imm_src_infer = RIMM;
      FDIV_S:    imm_src_infer = RIMM;
      FSQRT_S:   imm_src_infer = RIMM;
      FSGNJ_S:   imm_src_infer = NONE;
      FSGNJN_S:  imm_src_infer = NONE;
      FSGNJX_S:  imm_src_infer = NONE;
      FMIN_S:    imm_src_infer = NONE;
      FMAX_S:    imm_src_infer = NONE;
      FCVT_W_S:  imm_src_infer = RIMM;
      FCVT_WU_S: imm_src_infer = RIMM;
      FMV_X_W:   imm_src_infer = NONE;
      FEQ_S:     imm_src_infer = NONE;
      FLT_S:     imm_src_infer = NONE;
      FLE_S:     imm_src_infer = NONE;
      FCLASS_S:  imm_src_infer = NONE;
      FCVT_S_W:  imm_src_infer = RIMM;
      FCVT_S_WU: imm_src_infer = RIMM;
      FMV_W_X:   imm_src_infer = NONE;
      FCVT_L_S:  imm_src_infer = RIMM;
      FCVT_LU_S: imm_src_infer = RIMM;
      FCVT_S_L:  imm_src_infer = RIMM;
      FCVT_S_LU: imm_src_infer = RIMM;
      FLD:       imm_src_infer = IIMM;
      FSD:       imm_src_infer = SIMM;
      FMADD_D:   imm_src_infer = RIMM;
      FMSUB_D:   imm_src_infer = RIMM;
      FNMADD_D:  imm_src_infer = RIMM;
      FNMSUB_D:  imm_src_infer = RIMM;
      FADD_D:    imm_src_infer = RIMM;
      FSUB_D:    imm_src_infer = RIMM;
      FMUL_D:    imm_src_infer = RIMM;
      FDIV_D:    imm_src_infer = RIMM;
      FSQRT_D:   imm_src_infer = RIMM;
      FSGNJ_D:   imm_src_infer = NONE;
      FSGNJN_D:  imm_src_infer = NONE;
      FSGNJX_D:  imm_src_infer = NONE;
      FMIN_D:    imm_src_infer = NONE;
      FMAX_D:    imm_src_infer = NONE;
      FCVT_S_D:  imm_src_infer = RIMM;
      FCVT_D_S:  imm_src_infer = RIMM;
      FEQ_D:     imm_src_infer = NONE;
      FLT_D:     imm_src_infer = NONE;
      FLE_D:     imm_src_infer = NONE;
      FCLASS_D:  imm_src_infer = NONE;
      FCVT_W_D:  imm_src_infer = RIMM;
      FCVT_WU_D: imm_src_infer = RIMM;
      FCVT_D_W:  imm_src_infer = RIMM;
      FCVT_D_WU: imm_src_infer = RIMM;
      FCVT_L_D:  imm_src_infer = RIMM;
      FCVT_LU_D: imm_src_infer = RIMM;
      FMV_X_D:   imm_src_infer = NONE;
      FCVT_D_L:  imm_src_infer = RIMM;
      FCVT_D_LU: imm_src_infer = RIMM;
      FMV_D_X:   imm_src_infer = NONE;
      MRET:      imm_src_infer = NONE;
      WFI:       imm_src_infer = NONE;
      INVALID:   imm_src_infer = NONE;
      default:   imm_src_infer = NONE;
    endcase
  end

  // set source register 3 state and location
  always_comb begin : rs3
    unique case (reg_state[2:0])
      0: exp_cmd_o.rs3 = '0;
      1: exp_cmd_o.rs3 = {1'b0, code_i[31:27]};
      2: exp_cmd_o.rs3 = {1'b1, code_i[31:27]};
    endcase
  end

  // set source register 2 state and location
  always_comb begin : rs2
    unique case (reg_state[5:3])
      0: exp_cmd_o.rs2 = '0;
      1: exp_cmd_o.rs2 = {1'b0, code_i[24:20]};
      2: exp_cmd_o.rs2 = {1'b1, code_i[24:20]};
    endcase
  end

  // set source register 1 state and location
  always_comb begin : rs1
    unique case (reg_state[8:6])
      0: exp_cmd_o.rs1 = '0;
      1: exp_cmd_o.rs1 = {1'b0, code_i[19:15]};
      2: exp_cmd_o.rs1 = {1'b1, code_i[19:15]};
    endcase
  end

  // set destination register state and location
  always_comb begin : rd
    unique case (reg_state[11:9])
      0: exp_cmd_o.rd = '0;
      1: exp_cmd_o.rd = {1'b0, code_i[11:7]};
      2: exp_cmd_o.rd = {1'b1, code_i[11:7]};
    endcase
  end

  // set register requirement
  always_comb begin : reg_req
    if (exp_cmd_o.jump) exp_cmd_o.reg_req = '1;
    else begin
      exp_cmd_o.reg_req = '0;
      exp_cmd_o.reg_req[exp_cmd_o.rd] = 1'b1;
      exp_cmd_o.reg_req[exp_cmd_o.rs1] = 1'b1;
      exp_cmd_o.reg_req[exp_cmd_o.rs2] = 1'b1;
      exp_cmd_o.reg_req[exp_cmd_o.rs3] = 1'b1;
    end
  end

  // set immediate based on instruction type
  always_comb begin : imm
    stand_imm = '0;
    case (imm_src_infer)
      AIMM: begin  // sign extended shift amount
        foreach (stand_imm[i]) stand_imm[i] = (code_i[25]);
        stand_imm[5:0] = code_i[25:20];
        exp_cmd_o.imm  = stand_imm;
      end
      BIMM: begin  // B-TYPE instructions
        foreach (stand_imm[i]) stand_imm[i] = (code_i[31]);
        stand_imm[12:0] = {code_i[31], code_i[7], code_i[30:25], code_i[11:8], 1'b0};
        exp_cmd_o.imm   = stand_imm;
      end
      CIMM: begin  // csr instructions
        stand_imm[11:0] = code_i[31:20];
        stand_imm[16:12] = code_i[19:15];
        exp_cmd_o.imm = stand_imm;
      end
      IIMM: begin  // I-TYPE instructions
        foreach (stand_imm[i]) stand_imm[i] = (code_i[31]);
        stand_imm[11:0] = code_i[31:20];
        exp_cmd_o.imm   = stand_imm;
      end
      JIMM: begin  // J-TYPE instructions
        foreach (stand_imm[i]) stand_imm[i] = (code_i[31]);
        stand_imm[20:0] = {code_i[31], code_i[19:12], code_i[20], code_i[30:21], 1'b0};
        exp_cmd_o.imm   = stand_imm;
      end
      RIMM: begin  // R-TYPE instructions
        stand_imm[2:0] = code_i[14:12];
        exp_cmd_o.imm  = stand_imm;
      end
      SIMM: begin  // S-TYPE instructions
        foreach (stand_imm[i]) stand_imm[i] = (code_i[31]);
        stand_imm[11:0] = {code_i[31:25], code_i[11:7]};
        exp_cmd_o.imm   = stand_imm;
      end
      TIMM: begin
        stand_imm[1:0] = {code_i[26:25]};
        exp_cmd_o.imm  = stand_imm;
      end
      UIMM: begin  // U-TYPE instructions
        stand_imm[31:12] = {code_i[31:12]};
        exp_cmd_o.imm = stand_imm;
      end
      default: exp_cmd_o.imm = stand_imm;
    endcase
  end
  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  rv64g_instr_decoder u_dut (
      .pc_i,
      .code_i,
      .cmd_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Task to start input-output monitoring
  task automatic start_in_out_mon();
    pc_ok       = 1;
    func_ok     = 1;
    rd_ok       = 1;
    rs1_ok      = 1;
    rs2_ok      = 1;
    rs3_ok      = 1;
    jump_ok     = 1;
    imm_ok      = 1;
    reg_req_ok  = 1;

    tx_pc       = 0;
    tx_func     = 0;
    tx_rd       = 0;
    tx_rs1      = 0;
    tx_rs2      = 0;
    tx_rs3      = 0;
    tx_jump     = 0;
    tx_imm      = 0;
    tx_reg_req  = 0;

    instr_check = '0;
    tx_all      = 0;
    fork
      forever begin
        @(posedge clk_i);
        tx_all++;
        if (exp_cmd_o !== cmd_o) begin
          if (exp_cmd_o.pc !== cmd_o.pc && cmd_o.func !== INVALID) pc_ok = 0;
          else tx_pc++;
          if (exp_cmd_o.func !== cmd_o.func && cmd_o.func !== INVALID) func_ok = 0;
          else tx_func++;
          if (exp_cmd_o.rd !== cmd_o.rd && cmd_o.func !== INVALID) rd_ok = 0;
          else tx_rd++;
          if (exp_cmd_o.rs1 !== cmd_o.rs1 && cmd_o.func !== INVALID) begin
            $write("[%.3t] cmd_o.rs1:     0b%b\n", $realtime, cmd_o.rs1);
            $write("[%.3t] exp_cmd_o.rs1: 0b%b\n", $realtime, exp_cmd_o.rs1);
            $write("cmd_o.func: %p\texp_cmd_o.func: %p\n\n", cmd_o.func, exp_cmd_o.func);
            rs1_ok = 0;
          end else tx_rs1++;
          if (exp_cmd_o.rs2 !== cmd_o.rs2 && cmd_o.func !== INVALID) begin
            $write("[%.3t] cmd_o.rs2:     0b%b\n", $realtime, cmd_o.rs2);
            $write("[%.3t] exp_cmd_o.rs2: 0b%b\n", $realtime, exp_cmd_o.rs2);
            $write("cmd_o.func: %p\texp_cmd_o.func: %p\n\n", cmd_o.func, exp_cmd_o.func);
            rs2_ok = 0;
          end else tx_rs2++;
          if (exp_cmd_o.rs3 !== cmd_o.rs3 && cmd_o.func !== INVALID) rs3_ok = 0;
          else tx_rs3++;
          if (exp_cmd_o.jump !== cmd_o.jump && cmd_o.func !== INVALID) jump_ok = 0;
          else tx_jump++;
          if (exp_cmd_o.imm !== cmd_o.imm && cmd_o.func !== INVALID) imm_ok = 0;
          else tx_imm++;
          if (exp_cmd_o.reg_req !== cmd_o.reg_req && cmd_o.func !== INVALID) reg_req_ok = 0;
          else tx_reg_req++;
        end else begin
          tx_pc++;
          tx_func++;
          tx_rd++;
          tx_rs1++;
          tx_rs2++;
          tx_rs3++;
          tx_jump++;
          tx_imm++;
          tx_reg_req++;
          instr_check[cmd_o.func] = 1'b1;
          count = sum_of_packed_array(instr_check);
          if (count == NumInstr)->e_all_instr_checked;
        end
      end
    join_none
  endtask

  // Task to start random drive on inputs
  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        pc_i   <= $urandom;
        code_i <= $urandom;
      end
    join_none
  endtask

  function automatic int sum_of_packed_array(logic [255:0] packed_array);
    int sum = 0;
    foreach (packed_array[i]) begin
      if (packed_array[i]) sum++;
    end
    return sum;
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Initial block to handle fatal timeout
  initial begin
    repeat (1000001) @(posedge clk_i);
    $display("Success_pc             %d", tx_pc);
    $display("Success_func           %d", tx_func);
    $display("Success_rd             %d", tx_rd);
    $display("Success_rs1            %d", tx_rs1);
    $display("Success_rs2            %d", tx_rs2);
    $display("Success_rs3            %d", tx_rs3);
    $display("Success_jump           %d", tx_jump);
    $display("Success_imm            %d", tx_imm);
    $display("Success_reg_req        %d", tx_reg_req);
    $display("Instructions Verified: %d", count);
    $display("Total runs:            %d", tx_all);

    if (count != NumInstr) result_print(0, "FATAL TIMEOUT");
    result_print(pc_ok, "PC read check");
    result_print(func_ok, "FUNC read check");
    result_print(rd_ok, "RD read check");
    result_print(rs1_ok, "RS1 read check");
    result_print(rs2_ok, "RS2 read check");
    result_print(rs3_ok, "RS3 read check");
    result_print(jump_ok, "JUMP read check");
    result_print(imm_ok, "IMM read check");
    result_print(reg_req_ok, "REG_REQ read check");
    $finish;
  end

  // Initial block to start clock, monitor & drive
  initial begin
    pc_i   = '0;
    code_i = '0;
    start_clk_i();
    start_in_out_mon();
    start_random_drive();
  end

endmodule
