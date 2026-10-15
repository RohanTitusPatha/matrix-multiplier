# Part 1 — Interface and memory ports

Source: `rtl/part1.v` (reference fragment); complete design: `rtl/dut.v`.

## Purpose
`MyDesign` connects to four 128-bit SRAM interfaces: input, gates, scratchpad, and output. Each 128-bit word holds two FP64 values: real in bits [127:64], imaginary in bits [63:0]. The expected mathematical operation is sequential matrix–vector multiplication, `G[M-1] ... G[0] v`.

## Parameters
- `MAX_Q=6` is the supported maximum exponent, not the runtime dimension.
- `MAX_D=(1<<MAX_Q)` reserves up to 64 complex vector entries by default.
- The input header at address zero is interpreted as `{Q[63:0], M[63:0]}`; `dim=1<<Q`.

## SRAM ports
Input and gates are read-only for this DUT; output is write-only; scratchpad is used for intermediate vectors. Unused write ports are tied low and their address/data buses tied to zero. `dut_valid` starts work; `dut_ready` is high when idle/finished.

## Caveat
The separate `part*.v` files are educational fragments, **not standalone Verilog modules**. Compile `rtl/dut.v` together with the supplied `fp64_fma.v` instead.
