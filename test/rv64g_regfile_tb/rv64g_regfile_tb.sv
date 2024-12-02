/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module rv64g_regfile_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"
  import rv64g_pkg::NUM_REGS;
  import rv64g_pkg::XLEN;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int AW = $clog2(NUM_REGS);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [AW-1:0]       addr_t;
  typedef logic [XLEN-1:0]     data_t;
  typedef logic [NUM_REGS-1:0] num_reg_t;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic arst_ni = 1;

  // RTL inputs
  addr_t    wr_unlock_addr_i;
  data_t    wr_unlock_data_i;
  logic     wr_unlock_en_i;
  logic     wr_lock_en_i;
  addr_t    wr_lock_addr_i;

  addr_t    rs1_addr_i;
  addr_t    rs2_addr_i;
  addr_t    rs3_addr_i;

  // RTL outputs
  num_reg_t locks_o;
  data_t    rs1_data_o;
  data_t    rs2_data_o;
  data_t    rs3_data_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  addr_t temp_addr;
  num_reg_t temp_num_reg;
  logic lock_violation;
  data_t temp_rs1_prev;
  data_t temp_rs2_prev;
  data_t temp_rs3_prev;
  data_t temp_rs1_next;
  data_t temp_rs2_next;
  data_t temp_rs3_next;
  logic overwrite_violation;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  rv64g_regfile #(
  ) u_regfile (
      .arst_ni,
      .clk_i,
      .wr_unlock_addr_i,
      .wr_unlock_data_i,
      .wr_unlock_en_i,
      .wr_lock_en_i,
      .wr_lock_addr_i,
      .rs1_addr_i,
      .rs2_addr_i,
      .rs3_addr_i,
      .locks_o,
      .rs1_data_o,
      .rs2_data_o,
      .rs3_data_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task static apply_reset();
    #100ns;
    arst_ni <= 0;
    #100ns;
    arst_ni <= 1;
    #100ns;
  endtask

  task automatic start_random_drive();
    fork
      begin
        forever begin
          @(posedge clk_i);
          wr_lock_en_i <= $urandom_range(0, 99) < 50;
          wr_lock_addr_i <= $urandom;

          wr_unlock_en_i <= $urandom_range(0, 99) < 50;
          wr_unlock_addr_i <= $urandom;
          wr_unlock_data_i <= $urandom;

          rs1_addr_i <= $urandom;
          rs2_addr_i <= $urandom;
          rs3_addr_i <= $urandom;
        end
      end
    join_none
  endtask // random drive task

  task automatic start_in_out_monitor();
  mailbox #(addr_t) in_mbx = new();
  mailbox #(num_reg_t) out_mbx = new();

  mailbox #(data_t) prev1_mbx = new();
  mailbox #(data_t) next1_mbx = new();

  mailbox #(data_t) prev2_mbx = new();
  mailbox #(data_t) next2_mbx = new();

  mailbox #(data_t) prev3_mbx = new();
  mailbox #(data_t) next3_mbx = new();

  lock_violation = 1;
  overwrite_violation = 1;
    fork
      begin
        forever begin
          @(posedge clk_i);
          if (arst_ni) begin
            if (wr_lock_en_i) begin // lock violation check
              in_mbx.put(wr_lock_addr_i);
              #1ps;
              out_mbx.put(locks_o);
              in_mbx.get(temp_addr);
              out_mbx.get(temp_num_reg);
              if (temp_addr !== '0 && temp_num_reg[temp_addr] !== 1) lock_violation = 0;
            end
          end
        end
      end
      begin
        forever begin
          @(posedge clk_i);
          if (arst_ni) begin
            if (wr_lock_en_i && wr_unlock_en_i) begin
              if (wr_lock_addr_i == rs1_addr_i && wr_unlock_addr_i == rs1_addr_i) begin
                prev1_mbx.put(rs1_data_o);
                #1ps;
                next1_mbx.put(rs1_data_o);
                prev1_mbx.get(temp_rs1_prev);
                next1_mbx.get(temp_rs1_next);
                if (temp_rs1_prev !== temp_rs1_next) overwrite_violation = 0;
              end
            end
          end
        end
      end
      begin
        forever begin
          @(posedge clk_i);
          if (arst_ni) begin
            if (wr_lock_en_i && wr_unlock_en_i) begin
              if (wr_lock_addr_i == rs2_addr_i && wr_unlock_addr_i == rs2_addr_i) begin
                prev2_mbx.put(rs2_data_o);
                #1ps;
                next2_mbx.put(rs2_data_o);
                prev2_mbx.get(temp_rs2_prev);
                next2_mbx.get(temp_rs2_next);
                if (temp_rs2_prev !== temp_rs2_next) overwrite_violation = 0;
              end
            end
          end
        end
      end
      begin
        forever begin
          @(posedge clk_i);
          if (arst_ni) begin
            if (wr_lock_en_i && wr_unlock_en_i) begin
              if (wr_lock_addr_i == rs3_addr_i && wr_unlock_addr_i == rs3_addr_i) begin
                prev3_mbx.put(rs3_data_o);
                #1ps;
                next3_mbx.put(rs3_data_o);
                prev3_mbx.get(temp_rs3_prev);
                next3_mbx.get(temp_rs3_next);
                if (temp_rs3_prev !== temp_rs3_next) overwrite_violation = 0;
              end
            end
          end
        end
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial
    apply_reset();
    start_clk_i();
    start_random_drive();
    start_in_out_monitor();
  end

  initial begin
    repeat (2000001) @(posedge clk_i);
    result_print(lock_violation, "Lock Violation Check");
    result_print(overwrite_violation, "Overwrite Violation Check");
    $finish;
  end
endmodule

// redundant T-T
// initial begin
//   @(negedge lock_violation);
//   $write("[%.6t] lock violation 0b%b occured\n", $realtime, lock_violation);
//   $write("temp_addr: 0b%b\n temp_prof: 0b%b\n", temp_addr, temp_num_reg);
// end
