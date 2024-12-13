/*
Write a markdown documentation for this systemverilog module:
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module full_adder #(
) (
    input logic op1, // operand 1
    input logic op2, //operand 2
    input logic c_in, //carry in
    output logic sum, //sum
    output logic c_out //carry out
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic s_half; // intermediate signals for half adder sum
  logic c_half_1; // intermediate signals for half adder carry 1
  logic c_half_2; // intermediate signals for half adder carry 2

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign c_out = c_half_1 | c_half_2;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  half_adder #(
  ) u1 (
    .op1(op1),
    .op2(op2),
    .sum(s_half),
    .c_out(c_half_1)
  );

  half_adder #(
  ) u2 (
    .op1(s_half),
    .op2(c_in),
    .sum(sum),
    .c_out(c_half_2)
  );

endmodule
