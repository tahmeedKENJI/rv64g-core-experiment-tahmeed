/*
The rv64g_regfile module is designed to implement a register file with 64 registers, each 64 bits
wide, for the RISC-V 64-bit architecture. This module supports locking and unlocking specific
registers, making it suitable for operations that require controlled access to the registers.
Author : Foez Ahmed (foez.official@gmail.com)
*/

module rv64g_regfile #(
    localparam int NR = 64,  // Number of registers
    localparam int DW = 64,  // Data/Register Width
    localparam int AW = $clog2(NR)  // Address Width (log base 2 of the number of registers)
) (
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i,    // Clock input

    input logic [AW-1:0] wr_unlock_addr_i,  // Address for writing data to unlock a register
    input logic [DW-1:0] wr_unlock_data_i,  // Data to write to the register
    input logic          wr_unlock_en_i,    // Enable signal for writing unlock data

    input logic          wr_lock_en_i,   // Enable signal for locking a register
    input logic [AW-1:0] wr_lock_addr_i, // Address of the register to lock

    input logic [AW-1:0] rs1_addr_i,  // Address of the first source register
    input logic [AW-1:0] rs2_addr_i,  // Address of the second source register
    input logic [AW-1:0] rs3_addr_i,  // Address of the third source register

    output logic [NR-1:0] locks_o,  // Output vector indicating the lock status of each register

    output logic [DW-1:0] rs1_data_o,  // Data output from the first source register
    output logic [DW-1:0] rs2_data_o,  // Data output from the second source register
    output logic [DW-1:0] rs3_data_o   // Data output from the third source register
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [DW-1:0] regfile[NR];  // Array representing the register file
  logic wr_unlock_addr_not_zero;  // Flag indicating if the unlock address is non-zero

  logic [NR-1:0] lock;  // Array representing the lock status for registers
  logic [NR-1:0] unlock;  // Array representing the unlock status for registers
  logic [NR-1:0] locks_o_next;  // Next state of the lock status array

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Read data from the specified source registers
  always_comb rs1_data_o = regfile[rs1_addr_i];
  always_comb rs2_data_o = regfile[rs2_addr_i];
  always_comb rs3_data_o = regfile[rs3_addr_i];

  // Check if the unlock address is non-zero
  always_comb wr_unlock_addr_not_zero = |wr_unlock_addr_i;

  // Determine which register to lock
  always_comb begin
    lock                 = '0;
    lock[wr_lock_addr_i] = wr_lock_en_i;
    lock[0]              = '0;  // Register 0 is always unlocked
  end

  // Determine which register to unlock
  always_comb begin
    unlock                   = '1;
    unlock[wr_unlock_addr_i] = ~wr_unlock_en_i;
    unlock[0]                = '0;  // Register 0 is always unlocked
  end

  // Calculate the next state of the locks
  always_comb locks_o_next = (locks_o & unlock) | lock;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Update the register file on the rising edge of the clock or the falling edge of the reset
  // signal
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      foreach (regfile[i]) begin
        regfile[i] <= '0;  // Reset all registers to zero
      end
    end else if (wr_unlock_en_i & wr_unlock_addr_not_zero) begin
      regfile[wr_unlock_addr_i] <= wr_unlock_data_i;  // Write data to the specified register
    end
  end

  // Update the lock status on the rising edge of the clock or the falling edge of the reset signal
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      locks_o <= '0;  // Reset all lock statuses to zero
    end else begin
      locks_o <= locks_o_next;  // Update the lock statuses
    end
  end

endmodule
