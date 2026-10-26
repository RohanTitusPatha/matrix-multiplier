module MyDesign(
  input  wire reset_n, clk, dut_valid,
  output reg  dut_ready,
  output wire input_sram_write_enable,
  output wire [31:0]  input_sram_write_address,
  output wire [127:0] input_sram_write_data,
  output reg [31:0]  input_sram_read_address,
  input  wire [127:0] input_sram_read_data,
  output reg output_sram_write_enable,
  output reg [31:0]  output_sram_write_address,
  output reg [127:0] output_sram_write_data,
  output wire [31:0]  output_sram_read_address,
  input  wire [127:0] output_sram_read_data,
  output reg scratchpad_sram_write_enable,
  output reg [31:0]  scratchpad_sram_write_address,
  output reg [127:0] scratchpad_sram_write_data,
  output reg [31:0]  scratchpad_sram_read_address,
  input  wire [127:0] scratchpad_sram_read_data,
  output wire gates_sram_write_enable,
  output wire [31:0]  gates_sram_write_address,
  output wire [127:0] gates_sram_write_data,
  output reg [31:0]  gates_sram_read_address,
  input  wire [127:0] gates_sram_read_data);

  assign {input_sram_write_enable, input_sram_write_address, input_sram_write_data, gates_sram_write_enable, gates_sram_write_address, gates_sram_write_data, output_sram_read_address }= 0;
  
