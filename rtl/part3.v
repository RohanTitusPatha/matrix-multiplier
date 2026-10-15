// REFERENCE FRAGMENT 3/5: NOT A STANDALONE COMPILABLE MODULE.
// Compile rtl/dut.v instead. This file is a consecutive source section.

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

