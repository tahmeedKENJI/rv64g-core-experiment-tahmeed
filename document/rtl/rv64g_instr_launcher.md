# rv64g_instr_launcher (module)

### Author : Foez Ahmed (https://github.com/foez-ahmed)

## TOP IO
<img src="./rv64g_instr_launcher_top.svg">

## Description

Write a markdown documentation for this systemverilog module:
<br>**This file is part of DSInnovators:rv64g-core**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|decoded_instr_t|type||rv64g_pkg::decoded_instr_t||
|NR|int||rv64g_pkg::NUM_REGS||

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|arst_ni|input|logic|||
|clk_i|input|logic|||
|clear_i|input|logic|||
|instr_in_i|input|decoded_instr_t|||
|instr_in_valid_i|input|logic|||
|instr_in_ready_o|output|logic|||
|locks_i|input|[NR-1:0]|||
|instr_out_o|output|decoded_instr_t|||
|instr_out_valid_o|output|logic|||
|instr_out_ready_i|input|logic|||
