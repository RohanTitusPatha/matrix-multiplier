# Part 2 — Registers and FP64 datapath

Source: `rtl/part2.v`.

## Vector cache
`vector_cache[0:MAX_D-1]` holds the current vector. At default `MAX_Q=6`, it contains 64 × 128 = 8,192 bits, rather than two full-sized vector arrays. The code does not guarantee that synthesis maps it to SRAM; storage inference depends on the synthesis tool.

## Counters
- `matrix_idx`: matrix currently being applied.
- `row_idx`: output row.
- `col_idx`: dot-product column.
- `load_issued` / `load_received`: vector SRAM read requests and captured values.
- `gate_cursor`: sequential gate address.

## Gate buffering
`current_gate` selects either `prefetched_gate` or direct `gates_sram_read_data`. `gate_hold` preserves a gate during the multi-cycle complex path. `prefetch_valid` and `use_prefetched` select the first gate of a new row.

## FP64 arithmetic
A single combinational `fp64_fma` calculates `a*b+c`. Complex multiplication accumulates real and imaginary parts separately. `real_only` detects zero imaginary operands and selects the one-FMA fast path; it must not be assumed that all test data is real.
