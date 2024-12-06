/*
Write a markdown documentation for this systemverilog module:
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module constant_compare #(
    parameter int                IP_WIDTH    = 10,
    parameter bit [IP_WIDTH-1:0] CMP_ENABLES = 'h0C3,
    parameter bit [IP_WIDTH-1:0] EXP_RESULT  = 'h082,
    parameter int                OP_WIDTH    = 2,
    parameter bit [OP_WIDTH-1:0] MATCH_TRUE  = 1,
    parameter bit [OP_WIDTH-1:0] MATCH_FALSE = 2
) (
    input  logic [IP_WIDTH-1:0] in_i,
    output logic [OP_WIDTH-1:0] out_o
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef bit [31:0] int_t;

  function automatic int_t count_ones();
    int_t count = 0;
    foreach (CMP_ENABLES[i]) if (CMP_ENABLES[i]) count++;
    return count;
  endfunction

  localparam int_t NumCompares = count_ones();

  typedef int_t [NumCompares-1:0] index_t;

  function automatic index_t gen_index();
    index_t idx;
    int j = 0;
    for (int i = 0; i < IP_WIDTH; i++) begin
      if (CMP_ENABLES[i]) begin
        idx[j] = i;
        j++;
      end
    end
    return idx;
  endfunction

  localparam index_t AndIndex = gen_index();

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [NumCompares-1:0] and_array;
  logic                   is_match;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb begin
    foreach (and_array[i]) and_array[i] = in_i[AndIndex[i]];
  end

  always_comb is_match = |and_array;

  always_comb out_o = is_match ? MATCH_TRUE : MATCH_FALSE;

endmodule
