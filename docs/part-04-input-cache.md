# Part 4 — Input Vector Cache

input_cache stores the input vector locally. Each element is 64 bits because the matrix values are FP64. Caching allows the same input-vector elements to be reused across gate-matrix rows without repeatedly reading them from SRAM.
