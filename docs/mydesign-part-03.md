# Part 3 — FSM and FMA operand selection

Source: `rtl/part3.v`.

## State sequence
`IDLE` waits for `dut_valid`. Header states obtain Q and M. `LOAD_START`, `LOAD_PRIME`, and `LOAD_STREAM` populate the current vector. `ROW_START` sets up an output row; gate wait states prime SRAM reads. `MAC_R0` performs the first real multiply-add; `MAC_R1`, `MAC_I0`, and `MAC_I1` finish complex multiplication. `ROW_WRITE` stores the row, `ROW_NEXT` advances, and `MATRIX_NEXT` reloads the scratchpad vector.

## FMA equations
For gate `gr+j*gi` and vector `vr+j*vi`:
- real accumulation: `acc_r + gr*vr - gi*vi`
- imaginary accumulation: `acc_i + gr*vi + gi*vr`

The combinational operand mux chooses the correct operands for each MAC state.

## Important
The FMA itself is **not internally pipelined**. A one-real-MAC-per-clock throughput is an intended datapath optimization, not a measured or verified performance result.
