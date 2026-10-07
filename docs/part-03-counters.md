# Part 3 — Q, M, Dimension and Counters

Current learning assumption: Q <= 10 and M <= 10.

- Q, M: 4 bits
- dimension: 11 bits, enough to hold D = 2^10 = 1024
- matrix_idx: 4 bits
- row_idx, col_idx, load_idx: 10 bits for 0..1023

matrix_idx selects the gate matrix; row_idx the output row; col_idx the dot-product element; load_idx the input element being cached.
