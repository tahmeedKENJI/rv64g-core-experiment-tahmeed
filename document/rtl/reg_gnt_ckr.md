# reg_gnt_ckr (module)

### Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)

## TOP IO
<img src="./reg_gnt_ckr_top.svg">

## Description

Register grant circuit.
<br>**pl_valid_i** - 1 for valid instruction from pipeline.
<br>**jump_i** - For jump instructions. If 1, lock all registers.
<br>**rd_i** - Index of destination register.
<br>**reg_req_i** - Has 1s at the bits indicating required source registers by the current instruction.
<br>**locks_i** - Input of locked registers.
<br>**locks_o** - Output of locked registers. Note that when jump_i = 0, rd_i = 0 register can never be locked (only exception) - otherwise lock register indicated by rd_i.
<br>**arb_req_o** - 0/1 to arbiter based on locks_i and source registers required (all required source registers must be un-locked to "pass").
<br>**This file is part of DSInnovators:rv64g-core**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|NR|int||rv64g_pkg::NUM_REGS||

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|pl_valid_i|input|logic|||
|jump_i|input|logic|||
|rd_i|input|logic [$clog2(NR)-1:0]|||
|reg_req_i|input|logic [NR-1:0]|||
|locks_i|input|logic [NR-1:0]|||
|locks_o|output|logic [NR-1:0]|||
|arb_req_o|output|logic|||
