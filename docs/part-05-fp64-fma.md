# Part 5 — FP64 FMA Datapath

The provided fp64_fma performs result = a*b+c.

Mapping:
- a = gate_value
- b = input_cache[col_idx]
- c = accumulator

So each dot-product step is fma_result = gate_value * input_cache[col_idx] + accumulator. gate_value, accumulator and fma_result stay 64-bit because they represent FP64 values.
