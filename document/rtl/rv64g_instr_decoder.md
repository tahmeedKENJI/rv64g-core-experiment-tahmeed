# rv64g_instr_decoder (module)

### Author : Foez Ahmed (https://github.com/foez-ahmed)

## TOP IO
<img src="./rv64g_instr_decoder_top.svg">

## Description

Write a markdown documentation for this systemverilog module:
<br>**This file is part of DSInnovators:rv64g-core**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|decoded_instr_t|type||rv64g_pkg::decoded_instr_t| type definition of decoded instruction|

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|code_i|input|logic [31:0]|| 32-bit input instruction code|
|cmd_o|output|decoded_instr_t|| Output decoded instruction|
