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
    localparam int NR = rv64g_pkg::NUM_REGS
) (
    input logic arst_ni,
    input logic clk_i,
    input logic clear_i,

    input  decoded_instr_t instr_in_i,
    input  logic           instr_in_valid_i,
    output logic           instr_in_ready_o,

    input [NR-1:0] locks_i,

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

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign pl_ins[0] = instr_in_i;
  assign pl_ins_valid[0] = instr_in_valid_i;
  assign instr_in_ready_o = pl_ins_ready[0];

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

  // TODO
  // reg_gnt_ckr
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
