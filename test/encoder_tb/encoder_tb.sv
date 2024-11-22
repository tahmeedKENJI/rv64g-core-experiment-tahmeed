/*
Description
The encoder module is designed to determine the position of the highest priority active signal among multiple input wires. 
It encodes this position into an output index. 
This type of module is commonly used in digital systems where it is necessary to identify 
  which of several input signals is active and assign a corresponding binary code to that signal. 
This functionality is crucial for applications like priority encoders and resource arbitration.

This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information

Parameters:
NUM_WIRE	int		16	Number of input wires

Ports:
wire_in	input	logic [NUM_WIRE-1:0]		Input vector of wires
index_o	output	logic [$clog2(NUM_WIRE)-1:0]		Output index of the highest priority wire

Author : S. M. Tahmeed Reza (tahmeedreza@gmail.com)
*/

module encoder_tb;

  `define ENABLE_DUMPFILE 

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // parameter for number of input wires to encoder module
  parameter int NUM_WIRE = 16;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // apply typedef to repetitive code for readability
  typedef logic [NUM_WIRE-1:0] n_input;
  typedef logic [$clog2(NUM_WIRE)-1:0] n_output;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  n_input wire_in;  // encoder input bus
  n_output index_o;  // encoder output bus
  int tx_total = 0;  // records total number of executions
  int ms_time_var = 1;  // records time elapsed

  bit in_out_ok;
  int tx_success = 0; 

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-INTERFACES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-CLASSES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // assign buses to the correct encoder ports
  encoder #(
      .NUM_WIRE(NUM_WIRE)
  ) u_en1 (
      .wire_in(wire_in),
      .index_o(index_o)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // monitor the changes in input and output
  task automatic start_in_out_mon();
  in_out_ok = 1;
    fork
      forever begin
        @(posedge clk_i);
        #1ns $display("input = %b, output = %d", wire_in, index_o);
        if (one_hot_decode(wire_in) === index_o) tx_success++;
        else in_out_ok = 0;
      end
    join_none
  endtask

  // drive the rtl module with random input values
  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        wire_in <= (1 << $urandom_range(0, NUM_WIRE - 1));
        tx_total++;
      end
    join_none
  endtask

  // a redundant one_hot_decoder
  function automatic int one_hot_decode(n_input value);
    foreach (value[i]) begin
      if (value[i] === 1) return i;
    end
  endfunction

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    forever begin
      @(posedge clk_i);
      if (tx_total == 4 * NUM_WIRE) begin
        $display("END OF SIMULATION B8TCH");
        $display("Number of total runs: %d", tx_total);
        result_print(in_out_ok, "Data Encoding");

        $display("Number of valid runs: %d", tx_success);
        $finish;
      end
    end
  end

  initial begin
    #1ms;
    result_print(0, "SOMETHING WENT WRONG");
    $fatal(1, "FATAL TIMEOUT B8TCH");
  end

  initial begin  // main initial
    start_clk_i();
    start_random_drive();
    start_in_out_mon();
  end

  // initial begin
  //   fork
  //     begin
  //       forever begin
  //         #10ns $display("[%0d ms has elapsed]", ms_time_var);
  //         ms_time_var++;
  //       end
  //     end
  //     begin
  //       forever begin
  //         @(posedge clk_i);
  //         $display("TICK TOCK");
  //       end
  //     end
  //   join
  // end

endmodule
