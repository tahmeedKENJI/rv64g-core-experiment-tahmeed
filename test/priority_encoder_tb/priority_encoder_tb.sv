/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module priority_encoder_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  parameter int NUM_WIRE = 16;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [NUM_WIRE-1:0] n_wire;
  typedef logic [$clog2(NUM_WIRE)-1:0] n_encode;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  n_wire wire_in;
  n_encode index_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  integer pen_counter = 0;
  integer total_pencoded;
  logic priority_violation_flag = 0;
  event fail_trigger;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  priority_encoder #(
      .NUM_WIRE(NUM_WIRE)
  ) u_pen1 (
      .wire_in,
      .index_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic start_random_driver();
    fork
      forever begin
        @(posedge clk_i);
        wire_in <= $urandom;
        pen_counter++;
      end
    join_none
  endtask

  task automatic start_in_out_monitor();
    priority_violation_flag = 0;
    fork
      forever begin
        @(posedge clk_i);
        #1ns;
        // $display("wire_in = %b, input_idx = %0d, pen = %0d", wire_in, priority_idx(wire_in),
                //  index_o);

        if (priority_idx(wire_in) === index_o) begin
          // $display("No violation of Priority");

        end else begin
          priority_violation_flag <= 1;
          // $display("Violation of Priority");
        end
      end
    join_none
  endtask

  function automatic integer priority_idx(n_wire wire_in);
    for (integer i = 0; i < NUM_WIRE; i++) begin
      if (wire_in[i] === '1) return i;
    end
  endfunction
  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial
    start_clk_i();
    start_random_driver();
    start_in_out_monitor();
  end

  initial begin
    total_pencoded = 1000;
    fork
      begin
        forever begin
          @(posedge clk_i);
          #2ns;
          if (pen_counter === total_pencoded) begin
            $display("[%.1f] all out of %0d priority encodings completed", $time, total_pencoded);
            result_print(!priority_violation_flag, "Priority Preservation Check");
            $finish;
          end
        end
      end
      begin
        forever begin
          @(posedge clk_i);
          #2ns;
          if (priority_violation_flag) begin
            $display("[%.1f] %0d out of %0d priority encodings completed", $time, pen_counter,
                     total_pencoded);
            result_print(!priority_violation_flag, "Priority Preservation Check");
            $finish;
          end
        end
      end
    join_none
  end

endmodule
