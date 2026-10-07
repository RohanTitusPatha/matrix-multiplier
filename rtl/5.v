reg [63:0] accumulator;
reg [63:0] gate_value;

wire [63:0] fma_result;

fp64_fma fma_unit (
    .a(gate_value),
    .b(input_cache[col_idx]),
    .c(accumulator),
    .rnd(3'b000),
    .result(fma_result),
    .invalid(),
    .overflow(),
    .underflow(),
    .inexact()
);
