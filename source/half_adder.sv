/*
Write a markdown documentation for this systemverilog module:
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module half_adder #(
) (
    input logic op1,
    input logic op2,
    output logic sum,
    output logic c_out
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign sum = op1 ^ op2;
  assign c_out = op1 & op2;

endmodule
