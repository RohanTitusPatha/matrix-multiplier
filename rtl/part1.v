// REFERENCE FRAGMENT 1/5: NOT A STANDALONE COMPILABLE MODULE.
// Compile rtl/dut.v instead. This file is a consecutive source section.

// Matrix multiplication unit: output = G[M-1] x ... x G[1] x G[0] x v
// FP64 complex data: [127:64] = real, [63:0] = imaginary
module MyDesign #(
  parameter MAX_Q = 6,
  parameter MAX_D = (1 << MAX_Q)
)(
  input  wire         reset_n, clk, dut_valid,
  output reg          dut_ready,
  output wire         input_sram_write_enable,
  output wire [31:0]  input_sram_write_address,
  output wire [127:0] input_sram_write_data,
  output reg  [31:0]  input_sram_read_address,
  input  wire [127:0] input_sram_read_data,
  output reg          output_sram_write_enable,
  output reg  [31:0]  output_sram_write_address,
  output reg  [127:0] output_sram_write_data,
  output wire [31:0]  output_sram_read_address,
  input  wire [127:0] output_sram_read_data,
  output reg          scratchpad_sram_write_enable,
  output reg  [31:0]  scratchpad_sram_write_address,
  output reg  [127:0] scratchpad_sram_write_data,
  output reg  [31:0]  scratchpad_sram_read_address,
  input  wire [127:0] scratchpad_sram_read_data,
  output wire         gates_sram_write_enable,
  output wire [31:0]  gates_sram_write_address,
  output wire [127:0] gates_sram_write_data,
  output reg  [31:0]  gates_sram_read_address,
  input  wire [127:0] gates_sram_read_data
);

  // ---------------- Unused ports ----------------
  assign input_sram_write_enable  = 1'b0;
  assign input_sram_write_address = 32'd0;
  assign input_sram_write_data    = 128'd0;
  assign gates_sram_write_enable  = 1'b0;
  assign gates_sram_write_address = 32'd0;
  assign gates_sram_write_data    = 128'd0;
  assign output_sram_read_address = 32'd0;

