/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:rv64g-core
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module n_bit_ripple_carry_adder_tb;

  `define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  parameter int BIT_NUM = 8;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [BIT_NUM-1:0] n_bit_op;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  `CREATE_CLK(clk_i, 4ns, 6ns)
  n_bit_op op1;
  n_bit_op op2;
  logic    sgn_op2;
  n_bit_op sum;
  logic carry_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  n_bit_op exp_sum;
  logic    exp_carry;
  logic [BIT_NUM:0] temp_sum;

  int add_success;
  int sub_success;
  int total_op;
  logic add_failed_n;
  logic sub_failed_n;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  n_bit_ripple_carry_adder #(
      .BIT_NUM(BIT_NUM)
  ) u_dut (
      .op1(op1),
      .op2(op2),
      .sgn_op2(sgn_op2),
      .sum(sum),
      .carry_o(carry_o)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic start_random_drive();
    exp_sum   = '0;
    exp_carry = '0;
    fork
      begin
        forever begin
          @(posedge clk_i);
          op1     <= $urandom;
          op2     <= $urandom;
          sgn_op2 <= $urandom;
        end
      end
    join_none
  endtask

  task automatic start_in_out_monitor();
    add_success  = '0;
    sub_success  = '0;
    total_op     = '0;
    add_failed_n = '1;
    sub_failed_n = '1;
    fork
      begin
        forever begin
          @(posedge clk_i);
          if(op1 !== 'x && op2 !== 'x) begin
            total_op++;
            if (!sgn_op2) begin
              temp_sum = op1 + op2;
              // $write("op1:  %03d\t", op1);
              // $write("op2:  %03d\t", op2);
              // $write("sign: 0b%b\n", sgn_op2);
              // $write("sum:  %03d\n", {carry_o, sum});
              // $write("temp_sum:  %03d\n\n", temp_sum);
              exp_sum = temp_sum[BIT_NUM-1:0];
              exp_carry = temp_sum[BIT_NUM];
              if ((carry_o === exp_carry) && (sum === exp_sum)) add_success++;
              else add_failed_n = 0;
            end
            else if (sgn_op2 && op1 > op2)  begin
              exp_sum = op1 - op2;
              // $write("op1:  %03d\t", op1);
              // $write("op2:  %03d\t", op2);
              // $write("sign: 0b%b\n", sgn_op2);
              // $write("sum:  %03d\n", sum);
              // $write("exp_sum:  %03d\n\n", exp_sum);
              if (sum === exp_sum) sub_success++;
              else sub_failed_n = 0;
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
    start_clk_i();
    start_random_drive();
    start_in_out_monitor();
  end

  initial begin
    repeat (100001) @(posedge clk_i);
    $write("total runs: %0d\n", total_op);
    result_print(add_failed_n, "SUCCESSFUL ADDITION");
    result_print(sub_failed_n, "SUCCESSFUL SUBTRACTION");
    $finish;
  end

endmodule
