module dut_reference #(
    parameter ADDR_W = 32,
    parameter DATA_W = 128,
    parameter MAX_D  = 1024
)(
    input                       clk,
    input                       rst_n,
    input                       start,
    output reg [ADDR_W-1:0]     input_addr,
    input      [DATA_W-1:0]     input_data,
    output reg [ADDR_W-1:0]     gate_addr,
    input      [DATA_W-1:0]     gate_data,
    output reg [ADDR_W-1:0]     output_addr,
    output reg [DATA_W-1:0]     output_data,
    output reg                  output_we,
    output reg                  done
);

    localparam IDLE=4'd0, READ_INFO=4'd1, GET_INFO=4'd2,
               LOAD_INPUT=4'd3, SAVE_INPUT=4'd4, START_ROW=4'd5,
               READ_GATE=4'd6, GET_GATE=4'd7, ACCUMULATE=4'd8,
               WRITE_OUT=4'd9, NEXT_ROW=4'd10, FINISH=4'd11;
    reg [3:0] state;

    reg [3:0]  Q, M;
    reg [10:0] dimension;
    reg [3:0]  matrix_idx;
    reg [9:0]  row_idx;
    reg [9:0]  col_idx;
    reg [9:0]  load_idx;

    reg [63:0] input_cache [0:MAX_D-1];

    reg  [63:0] accumulator;
    reg  [63:0] gate_value;
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

endmodule
