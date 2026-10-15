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

  // ---------------- Registers ----------------
  reg [127:0] vector_cache [0:MAX_D-1];         // current input vector
  reg [31:0]  dim, matrices, matrix_idx, row_idx, col_idx;
  reg [31:0]  load_issued, load_received, gate_cursor;
  reg [127:0] prefetched_gate, gate_hold;
  reg         prefetch_valid, use_prefetched, last_real;
  reg [63:0]  acc_r, acc_i, tmp_r, tmp_i;

  // ---------------- FMA: result = a*b + c ----------------
  reg  [63:0] a, b, c;
  wire [63:0] result;
  wire invalid, overflow, underflow, inexact;
  fp64_fma U1 (.a(a), .b(b), .c(c), .rnd(3'b000), .result(result),
               .invalid(invalid), .overflow(overflow),
               .underflow(underflow), .inexact(inexact));

  // ---------------- Datapath wires ----------------
  wire [127:0] current_gate = use_prefetched ? prefetched_gate : gates_sram_read_data;
  wire [63:0]  gr = current_gate[127:64], gi = current_gate[63:0];
  wire [63:0]  vr = vector_cache[col_idx][127:64], vi = vector_cache[col_idx][63:0];
  wire real_only  = (gi[62:0] == 63'd0) && (vi[62:0] == 63'd0);  // fast path: 1 FMA

  // ---------------- States ----------------
  localparam [4:0] IDLE=0, HEADER_WAIT=1, HEADER_GET=2, LOAD_START=3, LOAD_PRIME=4,
                   LOAD_STREAM=5, ROW_START=6, GATE_WAIT1=7, GATE_WAIT2=8, MAC_R0=9,
                   MAC_R1=10, MAC_I0=11, MAC_I1=12, ROW_WRITE=13, ROW_NEXT=14,
                   MATRIX_NEXT=15, IDENTITY=16, FINISH=17, ERROR_STATE=18;
  reg [4:0] state;

  // ---------------- FMA operand select ----------------
  // real: acc_r += gr*vr - gi*vi    imag: acc_i += gr*vi + gi*vr
  always @(*) begin
    a = 64'd0; b = 64'd0; c = 64'd0;
    case (state)
      MAC_R0: begin a = gr;                                 b = vr; c = acc_r; end
      MAC_R1: begin a = {~gate_hold[63], gate_hold[62:0]};  b = vi; c = tmp_r; end
      MAC_I0: begin a = gate_hold[127:64];                  b = vi; c = acc_i; end
      MAC_I1: begin a = gate_hold[63:0];                    b = vr; c = tmp_i; end
      default: ;
    endcase
  end

  // ---------------- Main FSM ----------------
  always @(posedge clk) begin
    if (!reset_n) begin
      state <= IDLE;  dut_ready <= 1'b1;
      input_sram_read_address <= 0;  gates_sram_read_address <= 0;
      scratchpad_sram_read_address <= 32'hFFFFFFFF;
      output_sram_write_enable <= 0;  output_sram_write_address <= 0;  output_sram_write_data <= 0;
      scratchpad_sram_write_enable <= 0;  scratchpad_sram_write_address <= 0;  scratchpad_sram_write_data <= 0;
      dim <= 0;  matrices <= 0;  matrix_idx <= 0;  row_idx <= 0;  col_idx <= 0;
      load_issued <= 0;  load_received <= 0;  gate_cursor <= 0;
      gate_hold <= 0;  prefetched_gate <= 0;  prefetch_valid <= 0;  use_prefetched <= 0;  last_real <= 0;
      acc_r <= 0;  acc_i <= 0;  tmp_r <= 0;  tmp_i <= 0;
    end else begin
      output_sram_write_enable     <= 0;   // default: no writes
      scratchpad_sram_write_enable <= 0;
      if (state != LOAD_START && state != LOAD_PRIME && state != LOAD_STREAM)
        scratchpad_sram_read_address <= 32'hFFFFFFFF;   // park away from writes

      case (state)
        // ---- Handshake + header (Q, M) ----
        IDLE: if (dut_valid) begin
          dut_ready <= 0;  input_sram_read_address <= 0;  matrix_idx <= 0;
          gate_cursor <= 0;  prefetch_valid <= 0;  use_prefetched <= 0;
          state <= HEADER_WAIT;
        end
        HEADER_WAIT: state <= HEADER_GET;
        HEADER_GET: begin
          matrices <= input_sram_read_data[63:0];
          if (input_sram_read_data[127:64] > MAX_Q || input_sram_read_data[63:32] != 0)
            state <= ERROR_STATE;
          else begin
            dim <= 32'd1 << input_sram_read_data[69:64];
            load_issued <= 0;  load_received <= 0;  state <= LOAD_START;
          end
        end

        // ---- Load vector: input SRAM (gate 0) or scratchpad, 1 per clock ----
        LOAD_START: begin
          if (matrix_idx == 0) input_sram_read_address <= load_issued + 1;
          else                 scratchpad_sram_read_address <= load_issued;
          load_issued <= load_issued + 1;  state <= LOAD_PRIME;
        end
        LOAD_PRIME: begin
          if (load_issued < dim) begin
            if (matrix_idx == 0) input_sram_read_address <= load_issued + 1;
            else                 scratchpad_sram_read_address <= load_issued;
            load_issued <= load_issued + 1;
          end
          state <= LOAD_STREAM;
        end
        LOAD_STREAM: begin
          vector_cache[load_received] <= (matrix_idx == 0) ? input_sram_read_data
                                                           : scratchpad_sram_read_data;
          load_received <= load_received + 1;
          if (load_issued < dim) begin
            if (matrix_idx == 0) input_sram_read_address <= load_issued + 1;
            else                 scratchpad_sram_read_address <= load_issued;
            load_issued <= load_issued + 1;
          end
          if (load_received + 1 == dim) begin
            row_idx <= 0;
            state   <= (matrices == 0) ? IDENTITY : ROW_START;
          end
        end

        // ---- M = 0: output = input ----
        IDENTITY: begin
          output_sram_write_enable  <= 1;
          output_sram_write_address <= row_idx;
          output_sram_write_data    <= vector_cache[row_idx];
          if (row_idx + 1 == dim) state <= FINISH;
          else                    row_idx <= row_idx + 1;
        end

        // ---- Row setup: use prefetched gate or start a new read ----
        ROW_START: begin
          col_idx <= 0;  acc_r <= 0;  acc_i <= 0;
          if (prefetch_valid) begin
            use_prefetched <= 1;  prefetch_valid <= 0;  state <= MAC_R0;
          end else begin
            use_prefetched <= 0;  gates_sram_read_address <= gate_cursor;  state <= GATE_WAIT1;
          end
        end
        GATE_WAIT1: state <= GATE_WAIT2;
        GATE_WAIT2: begin
          gates_sram_read_address <= gate_cursor + 1;   // look ahead one gate
          state <= MAC_R0;
        end

        // ---- MAC: real fast path streams 1 gate per clock ----
        MAC_R0: begin
          gate_hold <= current_gate;  use_prefetched <= 0;
          if (real_only) begin
            acc_r <= result;  last_real <= 1;
            gates_sram_read_address <= gate_cursor + 2;  // gate n+1 already in flight
            gate_cursor <= gate_cursor + 1;
            if (col_idx + 1 == dim) state <= ROW_WRITE;
            else                    col_idx <= col_idx + 1;
          end else begin
            last_real <= 0;  tmp_r <= result;  state <= MAC_R1;
          end
        end
        MAC_R1: begin acc_r <= result;  state <= MAC_I0; end   // - gi*vi
        MAC_I0: begin tmp_i <= result;  state <= MAC_I1; end   // + gr*vi
        MAC_I1: begin                                          // + gi*vr
          acc_i <= result;  gate_cursor <= gate_cursor + 1;
          if (col_idx + 1 == dim) state <= ROW_WRITE;
          else begin
            col_idx <= col_idx + 1;
            gates_sram_read_address <= gate_cursor + 1;        // restart read pipeline
            state <= GATE_WAIT1;
          end
        end

        // ---- Write row: last gate -> output, else -> scratchpad ----
        ROW_WRITE: begin
          if (matrix_idx + 1 == matrices) begin
            output_sram_write_enable <= 1;  output_sram_write_address <= row_idx;
            output_sram_write_data   <= {acc_r, acc_i};
          end else begin
            scratchpad_sram_write_enable <= 1;  scratchpad_sram_write_address <= row_idx;
            scratchpad_sram_write_data   <= {acc_r, acc_i};
          end
          if (row_idx + 1 < dim && last_real) begin             // next row's first gate is here
            prefetched_gate <= gates_sram_read_data;  prefetch_valid <= 1;
          end else
            prefetch_valid <= 0;
          state <= ROW_NEXT;
        end
        ROW_NEXT: begin
          if (row_idx + 1 == dim)
            state <= (matrix_idx + 1 == matrices) ? FINISH : MATRIX_NEXT;
          else begin
            row_idx <= row_idx + 1;  state <= ROW_START;
          end
        end
        MATRIX_NEXT: begin
          matrix_idx <= matrix_idx + 1;  load_issued <= 0;  load_received <= 0;
          prefetch_valid <= 0;  state <= LOAD_START;
        end

        // ---- Done ----
        ERROR_STATE: state <= FINISH;                          // Q > MAX_Q: no output
        FINISH: begin dut_ready <= 1;  state <= IDLE; end
        default: state <= IDLE;
      endcase
    end
  end

endmodule