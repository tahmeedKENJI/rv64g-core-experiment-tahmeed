/*
AND reduction module
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module and_reduction #(
    parameter int NUM_ELEM   = 4,  // Number of elements in the input array
    parameter int ELEM_WIDTH = 8   // Width of each element in the input array
) (
    input  logic [ELEM_WIDTH-1:0] ins_i[NUM_ELEM],  // 2D array input signal
    output logic [ELEM_WIDTH-1:0] out_o             // Output signal after AND reduction
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [NUM_ELEM-1:0] re_arranged[ELEM_WIDTH];  // Temporary 2D array to hold rearranged inputs

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Rearrange the input array to prepare for AND reduction
  always_comb begin
    foreach (ins_i[i, j]) re_arranged[j][i] = ins_i[i][j];  // Transpose the input array
  end

  // Perform AND reduction on each bit position
  for (genvar i = 0; i < ELEM_WIDTH; i++) begin : g_and_reduction
    always_comb out_o[i] = &re_arranged[i];  // AND reduce the bits for each element in the row
  end

endmodule
