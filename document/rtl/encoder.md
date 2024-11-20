# encoder (module)

### Author : Foez Ahmed (foez.official@gmail.com)

## TOP IO
<img src="./encoder_top.svg">

## Description

The encoder module is designed to determine the position of the highest priority active signal among
multiple input wires. It encodes this position into an output index. This type of module is commonly
used in digital systems where it is necessary to identify which of several input signals is active
and assign a corresponding binary code to that signal. This functionality is crucial for
applications like priority encoders and resource arbitration.
<br>**This file is part of DSInnovators:rv64g-core**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|NUM_WIRE|int||16|Number of input wires|

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|wire_in|input|logic [NUM_WIRE-1:0]||Input vector of wires|
|index_o|output|logic [$clog2(NUM_WIRE)-1:0]||Output index of the highest priority wire|
