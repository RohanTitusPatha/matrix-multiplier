// REFERENCE FRAGMENT 5/5: NOT A STANDALONE COMPILABLE MODULE.
// Compile rtl/dut.v instead. This file is a consecutive source section.

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