/*
The encoder module is designed to determine the position of the highest priority active signal among
multiple input wires. It encodes this position into an output index. This type of module is commonly
used in digital systems where it is necessary to identify which of several input signals is active
and assign a corresponding binary code to that signal. This functionality is crucial for
applications like priority encoders and resource arbitration.
Author : Foez Ahmed (foez.official@gmail.com)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module encoder #(
    parameter int NUM_WIRE = 16  // Number of input wires
) (
    input logic [NUM_WIRE-1:0] wire_in,  // Input vector of wires

    output logic [$clog2(NUM_WIRE)-1:0] index_o  // Output index of the highest priority wire
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Array to hold intermediate reduction results for each level
  logic [NUM_WIRE/2-1:0] index_or_red[$clog2(NUM_WIRE)];

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Generate block to calculate reduction for each level
  for (genvar j = 0; j < $clog2(NUM_WIRE); j++) begin : g_addr_or_red
    always_comb begin
      int k;
      index_or_red[j] = '0;  // Initialize reduction array to 0
      k = 0;
      for (int i = 0; i < NUM_WIRE; i++) begin
        // Condition to include the wire in the current reduction level
        if (!((i % (2 ** (j + 1))) < ((2 ** (j + 1)) / 2))) begin
          index_or_red[j][k] = wire_in[i];  // Assign wire to reduction array
          k++;
        end
      end
    end
  end

  // Generate block to assign output index based on the reduction results
  for (genvar i = 0; i < $clog2(NUM_WIRE); i++) begin : g_addr_o
    always_comb index_o[i] = |index_or_red[i];  // OR reduction results to form the output index
  end

endmodule