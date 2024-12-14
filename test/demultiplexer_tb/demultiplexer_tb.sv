/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module demultiplexer_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  `include "vip/tb_ess.sv"
  `include "rv64g_pkg.sv"
  import rv64g_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  parameter int OUT_LEN = 128;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  `CREATE_CLK(clk_i, 4ns, 6ns)
  logic data_i;
  logic [$clog2(OUT_LEN)-1:0] select_i;
  logic [OUT_LEN-1:0] wire_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  int total_runs;
  int dmx_success;
  int dmx_failed;
  logic dmx_fail_n;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  demultiplexer #(
      .OUT_LEN(OUT_LEN)
  ) u_dut (
      .data_i  (data_i),
      .select_i(select_i),
      .wire_o  (wire_o)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic start_random_drive();
    fork
      begin
        forever begin
          @(posedge clk_i);
          data_i   <= $urandom;
          select_i <= $urandom;
        end
      end
    join_none
  endtask

  task automatic start_in_out_monitor();
    total_runs  = 0;
    dmx_success = 0;
    dmx_failed  = 0;
    dmx_fail_n  = '1;

    fork
      begin
        forever begin
          @(posedge clk_i);
          // $write("data_i: 0b%b\t", data_i);
          // $write("select_i: %04d\n", select_i);
          // $write("wire_o:    0b%b\n", wire_o);
          // $write("exp_dmx_o: 0b%b\n\n", select_idx_d_i(data_i, select_i));
          if (data_i !== 'x && select_i !== 'x) begin
            total_runs++;
            if (select_idx_d_i(data_i, select_i) === wire_o) dmx_success++;
            else begin
              dmx_failed++;
              dmx_fail_n = '0;
            end
          end
        end
      end
    join_none
  endtask

  function automatic logic [OUT_LEN-1:0] select_idx_d_i(logic data,
                                                        logic [$clog2(OUT_LEN)-1:0] select);
    logic [OUT_LEN-1:0] exp_dmx_o;
    exp_dmx_o = data << select;
    return exp_dmx_o;

  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial

    start_clk_i();
    start_random_drive();
    start_in_out_monitor();

  end

  initial begin

    repeat (20000) @(posedge clk_i);
    $write("\n/* SIMULATION REPORT */\n");
    $write("total runs:    %03d\n", total_runs);
    $write("demux success: %03d\n", dmx_success);
    $write("demux failed:  %03d\n\n", dmx_failed);
    result_print(dmx_fail_n, "RTL INTEGRITY CHECK: DEMULTIPLEXER");
    $finish;

  end

endmodule
