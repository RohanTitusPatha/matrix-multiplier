# Part 5 — Matrix MAC, prefetch, and output

Source: `rtl/part5.v`.

## Matrix traversal
For each output row, the controller traverses its columns. `gate_cursor` is incremented instead of recomputing `matrix_idx*dim*dim + row_idx*dim + col_idx`. This assumes matrices are stored contiguously in row-major order.

## Fast and complex paths
In `MAC_R0`, `real_only` allows the real accumulator to update with one FMA. Otherwise, the current gate is held and the controller performs three additional FMA steps to account for both complex components.

## Next-row prefetch
The code attempts to capture the next row's first gate during `ROW_WRITE`, then consume it in `ROW_START`. Because the gate SRAM is clocked, **prefetch alignment must be validated in simulation**. It is not safe to claim a measured one-MAC-per-cycle throughput until the waveforms confirm it.

## Intermediate and final storage
If more matrices remain, completed rows go to scratchpad SRAM. After the last matrix, they go to output SRAM. `MATRIX_NEXT` reloads the scratchpad vector before applying the next matrix.

## Known limitations
- `ERROR_STATE` silently returns to ready with no output and no error-status port.
- Default `MAX_Q=6` supports Q from 0 through 6, not larger inputs.
- SRAM data timing and prefetch behavior have **not been simulated or verified**.
- Real-only fast path still needs bit-level verification of FP64 signed-zero behavior and testbench tolerances.
- The five part files are reading aids; use the combined `rtl/dut.v` for compilation.
