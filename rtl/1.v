module dut_reference #(
    parameter ADDR_W = 32,
    parameter DATA_W = 128,
    parameter Q = 2,
    parameter M = 2,
    parameter D = 2**q 
)(
    input clk,
    input rst_n,
    input start,

    output reg [ADDR_W-1:0] input_addr,
    input [DATA_W-1:0] input_data,

    output reg [ADDR_W-1:0] gate_addr,
    input [DATA_W-1:0] gate_data,

    output reg [ADDR_W-1:0] output_addr,
    output reg [DATA_W-1:0] output_data,
    output reg output_we,

    output reg done
);
