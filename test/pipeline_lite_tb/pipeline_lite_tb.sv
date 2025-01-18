/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module pipeline_lite_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int DATAWIDTH = 32;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic arst_ni = 1;
  logic clear_i;

  logic [DATAWIDTH-1:0] data_in_i;
  logic data_in_valid_i;
  logic data_in_ready_o;

  logic [DATAWIDTH-1:0] data_out_o;
  logic data_out_valid_o;
  logic data_out_ready_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [DATAWIDTH-1:0] data_buffer;
  logic [DATAWIDTH-1:0] ex_data_out;
  logic buffer_clear_flag;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // pipeline #(
  pipeline_lite #(
      .DATAWIDTH(DATAWIDTH)
      // .DW(DATAWIDTH)
  ) u_dut (
      .arst_ni(arst_ni),
      .clk_i(clk_i),
      .clear_i(clear_i),
      .data_in_i(data_in_i),
      .data_in_valid_i(data_in_valid_i),
      .data_in_ready_o(data_in_ready_o),
      .data_out_o(data_out_o),
      .data_out_valid_o(data_out_valid_o),
      .data_out_ready_i(data_out_ready_i)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task static apply_reset();
    #100ns;
    $write("data_in_ready_o: 0b%b\n", data_in_ready_o);
    $write("data_out_valid_o: 0b%b\n", data_out_valid_o);
    arst_ni <= 0;
    #100ns;
    buffer_clear_flag <= '1;
    $write("data_in_ready_o: 0b%b\n", data_in_ready_o);
    $write("data_out_valid_o: 0b%b\n", data_out_valid_o);
    arst_ni <= 1;
    #100ns;
    $write("data_in_ready_o: 0b%b\n", data_in_ready_o);
    $write("data_out_valid_o: 0b%b\n", data_out_valid_o);
  endtask

  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        clear_i <= $urandom_range(0, 99) < 5;
        data_in_i <= 1 << $urandom_range(0, DATAWIDTH-1);
        data_in_valid_i <= $urandom_range(0, 99) < 50;
        data_out_ready_i <= $urandom_range(0, 99) < 50;
      end
    join_none
  endtask

  task automatic start_monitor();
    fork
      forever begin
        @(posedge clk_i);
        // $write("[%.3t]\n", $realtime);
        // // $write("\n");
        // // $write("clear_i:          0b%b\n", clear_i);
        // $write("data_in_i:          %03d\n", data_in_i);
        // $write("data_in_valid_i:  0b%b\n", data_in_valid_i);
        // $write("data_in_ready_o:  0b%b\n", data_in_ready_o);
        // $write("data_out_valid_o: 0b%b\n", data_out_valid_o);
        // $write("data_out_ready_i: 0b%b\n", data_out_ready_i);
        // $write("\n");

        if (arst_ni & ~clear_i) begin
          if (data_out_valid_o & data_out_ready_i) begin
            ex_data_out <= data_buffer;
            buffer_clear_flag <= '1;
          end
          if (data_in_ready_o & data_in_valid_i) begin
            data_buffer <= data_in_i;
            buffer_clear_flag <= '0;
          end
        end
        // $write("data_buffer:        %03d\n", data_buffer);
        // $write("ex_data_out:        %03d\n", ex_data_out);
        // $write("data_out_o:         %03d\n", data_out_o);
        // $write("buffer_clear_flag: 0b%b\n", buffer_clear_flag);
        // $write("\n");
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial
    apply_reset();
    start_clk_i();
    start_random_drive();
    start_monitor();
  end

  initial begin
    repeat (100) @(posedge clk_i);
    $finish;
  end

endmodule
