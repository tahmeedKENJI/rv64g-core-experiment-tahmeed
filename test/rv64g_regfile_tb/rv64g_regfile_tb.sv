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

  num_reg_t ref_mem [XLEN];
  data_t tmp_rs1;
  data_t tmp_rs2;
  data_t tmp_rs3;
  data_t __rs1_ref_o__;
  data_t __rs2_ref_o__;
  data_t __rs3_ref_o__;
  num_reg_t lock_profile;
  logic read_wait;
  logic lock_at_reset;
  logic lock_violation;
  int read_error;

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
    lock_at_reset = 1;
    #100ns;
    arst_ni <= 0;
    #100ns;
    // $write("locks_o at reset: 0b%b\n", locks_o);
    // $write("reset: 0b%b\n", arst_ni);
    if (~(&(locks_o))) result_print(~lock_at_reset, "Locks Handling At Reset");
    else result_print(lock_at_reset, "Locks Handling At Reset");
    arst_ni <= 1;
    #100ns;
  endtask

  task automatic start_random_drive();
    fork
      begin
        forever begin
          wr_lock_en_i <= $urandom_range(0, 99) < 50;
          wr_lock_addr_i <= $urandom;

          wr_unlock_en_i <= $urandom_range(0, 99) < 50;
          wr_unlock_addr_i <= $urandom;
          wr_unlock_data_i <= $urandom;

          rs1_addr_i <= $urandom;
          rs2_addr_i <= $urandom;
          rs3_addr_i <= $urandom;
          @(posedge clk_i);
        end
      end
    join_none
  endtask // random drive task

  task automatic start_ref_mem_update();
  foreach(lock_profile[i]) lock_profile[i] <= 'b0;
  fork
    begin
      forever begin
        @(posedge clk_i);
        if (arst_ni) begin
          if (wr_lock_en_i && wr_unlock_en_i && (wr_lock_addr_i === wr_unlock_addr_i)) begin
            if (wr_lock_addr_i !== 0) lock_profile[wr_lock_addr_i] <= '1;
          end else if (wr_lock_en_i || wr_unlock_en_i) begin
            if (wr_lock_en_i && (wr_lock_addr_i !== 0)) lock_profile[wr_lock_addr_i] <= 'b1;
            if (wr_unlock_en_i) begin
              ref_mem[wr_unlock_addr_i]  <= wr_unlock_data_i;
              lock_profile[wr_unlock_addr_i] <= 'b0;
            end
          end
          tmp_rs1 <= ref_mem[rs1_addr_i];
          tmp_rs2 <= ref_mem[rs2_addr_i];
          tmp_rs3 <= ref_mem[rs3_addr_i];
        end
      end
    end
    begin
      @(posedge clk_i);
      foreach(ref_mem[i]) ref_mem[i] <= '0;
    end
  join_none
  endtask

  task automatic start_in_out_monitor();
  mailbox #(data_t) rs1_mbx = new();
  mailbox #(data_t) rs2_mbx = new();
  mailbox #(data_t) rs3_mbx = new();
  lock_violation <= 'b1;
  read_error <= 0;
  read_wait <= 'b0;
  fork
    begin
      forever begin
        @(posedge clk_i);
        if (locks_o !== lock_profile) lock_violation <= 'b0;
        rs1_mbx.put(rs1_data_o);
        rs2_mbx.put(rs2_data_o);
        rs3_mbx.put(rs3_data_o);
        if (read_wait) begin
          rs1_mbx.get(__rs1_ref_o__);
          rs2_mbx.get(__rs2_ref_o__);
          rs3_mbx.get(__rs3_ref_o__);
          if (tmp_rs1 !== __rs1_ref_o__) read_error++;
          if (tmp_rs2 !== __rs2_ref_o__) read_error++;
          if (tmp_rs3 !== __rs3_ref_o__) read_error++;
        end
      end
    end
    begin
      @(posedge clk_i);
      read_wait <= 'b1;
      @(posedge clk_i);
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
    start_ref_mem_update();
    start_in_out_monitor();
  end

  initial begin
    forever begin
      @(read_error);
      $write("[%.3t]\n", $realtime);
      $write("rs1_addr_i: %03d\t", rs1_addr_i);
      $write("rs2_addr_i: %03d\t", rs2_addr_i);
      $write("rs3_addr_i: %03d\n", rs3_addr_i);
      $write("tmp_rs1: %p\n rs1_ref_o: %p\n", tmp_rs1, __rs1_ref_o__);
      $write("tmp_rs2: %p\n rs2_ref_o: %p\n", tmp_rs2, __rs2_ref_o__);
      $write("tmp_rs3: %p\n rs3_ref_o: %p\n", tmp_rs3, __rs3_ref_o__);
    end
  end

  initial begin
    repeat (201) @(posedge clk_i);
    result_print(lock_violation, "Lock Violation Check");
    result_print((read_error === 0), "Read Error Check");
    $finish;
  end

endmodule
