// REFERENCE FRAGMENT 2/5: NOT A STANDALONE COMPILABLE MODULE.
// Compile rtl/dut.v instead. This file is a consecutive source section.

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

