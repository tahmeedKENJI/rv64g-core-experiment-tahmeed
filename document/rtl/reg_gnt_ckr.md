# reg_gnt_ckr (module)

### Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)

## TOP IO
<img src="./reg_gnt_ckr_top.svg">

## Description

Write a markdown documentation for this systemverilog module:
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
|pl_ready_o|output|logic|||
|jump_i|input|logic|||
|reg_req_i|input|logic [NR-1:0]|||
|locks_i|input|logic [NR-1:0]|||
|locks_o|output|logic [NR-1:0]|||
|arb_req_o|output|logic|||
|arb_gnt_i|input|logic|||
