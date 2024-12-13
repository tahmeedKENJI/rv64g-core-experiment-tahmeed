/*
Write a markdown documentation for this systemverilog module:
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module n_bit_ripple_carry_adder #(
    parameter int BIT_NUM = 4
) (
    input  logic [BIT_NUM-1:0] op1,
    input  logic [BIT_NUM-1:0] op2,
    input  logic               sgn_op2,
    output logic [BIT_NUM-1:0] sum,
    output logic               carry_o
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [BIT_NUM-1:0] n_bit_c;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  n_bit_c c_intermediate;
  n_bit_c s_op2;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  generate
    for (genvar i = 0; i < BIT_NUM; i++) begin : sgn_op
      assign s_op2[i] = op2[i] ^ sgn_op2;
    end
  endgenerate

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  generate
    for (genvar i = 0; i < BIT_NUM; i++) begin : dut_service
      if (i == 0) begin
        full_adder #() u_dut (
            .op1  (op1[i]),
            .op2  (s_op2[i]),
            .c_in (sgn_op2),
            .sum  (sum[i]),
            .c_out(c_intermediate[i])
        );
      end else if (i < BIT_NUM - 1) begin
        full_adder #() u_dut (
            .op1  (op1[i]),
            .op2  (s_op2[i]),
            .c_in (c_intermediate[i-1]),
            .sum  (sum[i]),
            .c_out(c_intermediate[i])
        );
      end else begin
        full_adder #() u_dut (
            .op1  (op1[i]),
            .op2  (s_op2[i]),
            .c_in (c_intermediate[i-1]),
            .sum  (sum[i]),
            .c_out(carry_o)
        );
      end
    end
  endgenerate

endmodule
