# Supprted CSRs
| **CSR**       | **Description**                                                                            | **Address** |
|---------------|--------------------------------------------------------------------------------------------|-------------|
| cycle❗         | Cycle counter (lower 32 bits), counts the number of clock cycles.                          | 0xC00       |
| cycleh❗        | Cycle counter (upper 32 bits), extends the cycle count for 64-bit precision.               | 0xC80       |
| fcsr❗          | Floating-point Control and Status Register, manages FP operation modes.                    | 0x003       |
| instret❗       | Instructions Retired counter (lower 32 bits), counts executed instructions.                | 0xC02       |
| instreth❗      | Instructions Retired counter (upper 32 bits), extends instret for 64-bit.                  | 0xC82       |
| mcause❗        | Machine Cause Register, indicates the reason for the last exception/interrupt.             | 0x342       |
| mconfigptr❗    | Pointer to Machine Configuration.                                                          | 0xF15       |
| mcounteren❗    | Machine Counter Enable Register, controls counter access for lower levels.                 | 0x306       |
| mcountinhibit❗ | Machine Counter Inhibit Register, disables specific counters.                              | 0x320       |
| mcycle❗        | Machine Cycle Counter (lower 32 bits), counts machine cycles.                              | 0xB00       |
| mcycleh❗       | Machine Cycle Counter (upper 32 bits), extends mcycle for 64-bit precision.                | 0xB80       |
| medeleg❗       | Machine Exception Delegation Register, delegates exceptions to supervisor mode.            | 0x302       |
| mepc❗          | Machine Exception Program Counter, holds the address of the exception-causing instruction. | 0x341       |
| mhartid❗       | Machine Hardware Thread ID Register, identifies the hardware thread.                       | 0xF14       |
| mie❗           | Machine Interrupt Enable Register, enables specific machine-mode interrupts.               | 0x304       |
| mimpid❗        | Machine Implementation ID Register, identifies the processor implementation.               | 0xF13       |
| minstret❗      | Machine Instructions Retired counter (lower 32 bits), counts executed instructions.        | 0xB02       |
| minstreth❗     | Machine Instructions Retired counter (upper 32 bits), extends minstret for 64-bit.         | 0xB82       |
| mip❗           | Machine Interrupt Pending Register, indicates pending machine-mode interrupts.             | 0x344       |
| misa❗          | Machine ISA Register, specifies supported ISA extensions.                                  | 0x301       |
| mscratch❗      | Machine Scratch Register, used for temporary storage in machine mode.                      | 0x340       |
| mseccfg❗       | Machine Security Configuration Register, configures machine security settings.             | 0x747       |
| mseccfgh❗      | Machine Security Configuration Register (high part), extends mseccfg.                      | 0x757       |
| mstatus❗       | Machine Status Register, holds the processor's current status information.                 | 0x300       |
| mstatush❗      | Machine Status Register (high part), extends mstatus.                                      | 0x310       |
| mtinst❗        | Machine Trap Instruction Register, provides additional trap-related information.           | 0x34A       |
| mtval❗         | Machine Trap Value Register, holds the address or other information about the trap.        | 0x343       |
| mtval2❗        | Additional Machine Trap Value Register, extends mtval with more information.               | 0x34B       |
| mtvec❗         | Machine Trap-Vector Base Address Register, sets the base address of the trap handler.      | 0x305       |
| time❗          | Timer Register (lower 32 bits), keeps track of elapsed time.                               | 0xC01       |
| timeh❗         | Timer Register (upper 32 bits), extends the timer for 64-bit precision.                    | 0xC81       |
