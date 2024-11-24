/*
Write a markdown documentation for this systemverilog module:
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "rv64g_pkg.sv"

module rv64g_instr_launcher #(
    localparam type decoded_instr_t = rv64g_pkg::decoded_instr_t,
    localparam int NR = rv64g_pkg::NUM_REGS,
    localparam type locks_t = logic [NR-1:0]
) (
    input logic arst_ni,
    input logic clk_i,
    input logic clear_i,

    input  decoded_instr_t instr_in_i,
    input  logic           instr_in_valid_i,
    output logic           instr_in_ready_o,

    input locks_t locks_i,

    output decoded_instr_t instr_out_o,
    output logic           instr_out_valid_o,
    input  logic           instr_out_ready_i
);

  import rv64g_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NOS = rv64g_pkg::NUM_OUTSTANDING;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  decoded_instr_t [NOS:0] pl_ins;
  logic           [NOS:0] pl_ins_valid;
  logic           [NOS:0] pl_ins_ready;
  decoded_instr_t [NOS:0] pl_outs;
  logic           [NOS:0] pl_outs_valid;
  logic           [NOS:0] pl_outs_ready;

  locks_t                 locks         [NOS+2];

  logic           [NOS:0] arb_req;
  logic           [NOS:0] arb_gnt;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign pl_ins[0] = instr_in_i;
  assign pl_ins_valid[0] = instr_in_valid_i;
  assign instr_in_ready_o = pl_ins_ready[0];

  assign locks[0] = locks_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  for (genvar i = 0; i < NOS; i++) begin : g_splits
    pipeline_split #(
        .DW($bits(instr_in_i))
    ) u_pipeline_split (
        .arst_ni,
        .clk_i,
        .clear_i                   (),                    // TODO
        .data_in_i                 (pl_ins[i]),
        .data_in_valid_i           (pl_ins_valid[i]),
        .data_in_ready_o           (pl_ins_ready[i]),
        .data_out_main_o           (pl_outs[NOS]),
        .data_out_main_valid_o     (pl_outs_valid[NOS]),
        .data_out_main_ready_i     (pl_outs_ready[NOS]),
        .data_out_secondary_o      (pl_ins[i+1]),
        .data_out_secondary_valid_o(pl_ins_valid[i+1]),
        .data_out_secondary_ready_i(pl_ins_ready[i+1])
    );
  end

  pipeline #(
      .DW($bits(instr_in_i))
  ) u_pipeline_split (
      .arst_ni,
      .clk_i,
      .clear_i         (),                   // TODO
      .data_in_i       (pl_ins[NOS]),
      .data_in_valid_i (pl_ins_valid[NOS]),
      .data_in_ready_o (pl_ins_ready[NOS]),
      .data_out_o      (pl_outs[0]),
      .data_out_valid_o(pl_outs_valid[0]),
      .data_out_ready_i(pl_outs_ready[0])
  );

  for (genvar i = 0; i < NOS + 1; i++) begin : g_ckeckers
    reg_gnt_ckr #() u_reg_gnt_ckr (
        .pl_valid_i(pl_outs_valid[i]),
        .pl_ready_o(pl_outs_ready[i]),
        .jump_i(pl_outs[i].jump),
        .reg_req_i(pl_outs[i].req_req),
        .locks_i(locks[i]),
        .locks_o(locks[i+1]),
        .arb_req_o(arb_req[i]),
        .arb_gnt_i(arb_gnt[i])
    );
  end

  // TODO
  // Fixed Priority Arb
  // MUX
  // ENCODER
  // CLEAR

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-INITIAL CHECKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
