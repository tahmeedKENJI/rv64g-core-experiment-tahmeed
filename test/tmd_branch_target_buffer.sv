/*
Write a markdown documentation for this systemverilog module:
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/
`include "rv64g_pkg.sv"

module tmd_branch_target_buffer #(
    localparam int XLEN = rv64g_pkg::XLEN
) (
    input  logic            arst_ni,                     // asynchronous reset
    input  logic            clk_i,                       // clock signal: 100MHz
    input  logic [XLEN-1:0] pc_i,                        // current program counter
    input  logic [XLEN-1:0] curr_addr_i,                 // current execution program address
    input  logic [XLEN-1:0] next_addr_i,                 // next execution program address
    input  logic            is_jump_i,                   // is jump instruction or not
    input  logic            direct_next_address_load_i,  // load next address flag
    output logic            pipeline_clear_o,            // pipeline clear signal
    output logic [XLEN-1:0] next_pc_o                    // next program counter
);

  import rv64g_pkg::*;
  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [          127:0][XLEN-1:2] c_addr_buffer;
  logic [          127:0][XLEN-1:2] n_addr_buffer;
  logic [          127:0]           valid;

  logic [          127:0]           wr_en;  // write enable
  logic [$clog2(128)-1:0]           wr_select_1;  // write demux 1 selector
  logic [$clog2(128)-1:0]           wr_select_2;  // write demux 2 selector
  logic                             buffer_full_n;  // check if buffer full
  logic                             need_write_new;  // check incoming overwrite
  logic                             need_write_old;  // check incoming overwrite
  logic [          127:0]           now_write_new;  // send overwrite to desired buffer
  logic [          127:0]           now_write_old;  // send overwrite to desired buffer
  logic                             cmp_eq_next_curr_4;
  logic [          127:0]           curr_addr_found;
  logic [          127:0]           next_addr_found;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb begin : b_are_they_equal
    if ((curr_addr_i + 4) === next_addr_i) begin
      cmp_eq_next_curr_4 = '1;
    end else begin
      cmp_eq_next_curr_4 = '0;
    end
  end

  always_comb begin : g_wr_en
    wr_en = now_write & buffer_full_n;
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  priority_encoder #(
      .NUM_WIRE(128)
  ) u_pe_1 (
      .wire_in(~valid),
      .index_o(wr_select_1),
      .index_valid_o(buffer_full_n)
  );

  encoder #(
      .NUM_WIRE(128)
  ) u_en_1 (
      .wire_in(curr_addr_found),
      .index_o(wr_select),
      .index_valid_o(buffer_full_n)
  );

  demultiplexer #(
      .OUT_LEN(128)
  ) u_dmx_1 (
      .data_i  (need_write),
      .select_i(wr_select_1),
      .wire_o  (now_write)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i or negedge arst_ni) begin : b_next_pc
    if (~arst_ni) begin
      c_addr_buffer <= '0;
      n_addr_buffer <= '0;
      valid         <= '0;
    end else begin
      for (int i = 0; i < 128; i++) begin
        if (wr_en[i]) valid[i] <= cmp_res[i];
      end
    end
  end

endmodule
