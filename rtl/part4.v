// REFERENCE FRAGMENT 4/5: NOT A STANDALONE COMPILABLE MODULE.
// Compile rtl/dut.v instead. This file is a consecutive source section.

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

