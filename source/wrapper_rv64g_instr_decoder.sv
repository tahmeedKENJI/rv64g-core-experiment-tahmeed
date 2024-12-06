`include "rv64g_pkg.sv"

module wrapper_rv64g_instr_decoder #(
    localparam int  XLEN            = rv64g_pkg::XLEN,
    localparam type decoded_instr_t = rv64g_pkg::decoded_instr_t
) (
    input  logic                      clk_i,
    input  logic                      arst_ni,
    input  logic           [XLEN-1:0] pc_i,
    input  logic           [    31:0] code_i,
    output decoded_instr_t            cmd_o
);

  logic [XLEN-1:0] pc;
  logic [31:0] code;
  decoded_instr_t cmd;

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      pc <= '0;
      code <= '0;
      cmd_o <= '0;
    end else begin
      pc <= pc_i;
      code <= code_i;
      cmd_o <= cmd;
    end
  end

  rv64g_instr_decoder #() u_rv64g_instr_decoder (
      .pc_i  (pc),
      .code_i(code),
      .cmd_o (cmd)
  );

endmodule
