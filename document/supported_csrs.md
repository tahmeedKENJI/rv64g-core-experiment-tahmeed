# Supprted CSRs
| Number | Privilege | Name       | Description
|--------|-----------|------------|------------
| 0x001  | URW       | fflags     | Floating-Point Accrued Exceptions.
| 0x002  | URW       | frm        | Floating-Point Dynamic Rounding Mode.
| 0x003  | URW       | fcsr       | Floating-Point Control and Status Register (frm +fflags).
|--------|-----------|------------|------------
| 0xC00  | URO       | cycle      | Cycle counter for RDCYCLE instruction.
| 0xC02  | URO       | instret    | Instructions-retired counter for RDINSTRET instruction.
| 0xC01  | URO       | time       | Timer for RDTIME instruction.
|--------|-----------|------------|------------
| 0x300  | MRW       | mstatus    | Machine status register.
| 0x301  | MRW       | misa       | ISA and extensions (0x10001129)
| 0x304  | MRW       | mie        | Machine interrupt-enable register.
| 0x305  | MRW       | mtvec      | Machine trap-handler base address.
|--------|-----------|------------|------------
| 0x340  | MRW       | mscratch   | Scratch register for machine trap handlers.
| 0x341  | MRW       | mepc       | Machine exception program counter.
| 0x342  | MRW       | mcause     | Machine trap cause.
| 0x343  | MRW       | mtval      | Machine bad address or instruction.
| 0x344  | MRW       | mip        | Machine interrupt pending.
| 0x34A  | MRW       | mtinst     | Machine trap instruction (transformed).
| 0x34B  | MRW       | mtval2     | Machine bad guest physical address.
