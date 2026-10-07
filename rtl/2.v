localparam IDLE = 4'd0,
           READ_INFO = 4'd1,
           GET_INFO = 4'd2,
           LOAD_INPUT = 4'd3,
           SAVE_INPUT = 4'd4,
           START_ROW = 4'd5,
           READ_GATE = 4'd6,
           GET_GATE = 4'd7,
           ACCUMULATE = 4'd8,
           WRITE_OUT = 4'd9,
           NEXT_ROW = 4'd10,
           FINISH = 4'd11;

reg [3:0] state;

always @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
    end
    else begin
        case (state)

            IDLE: begin
                if (start)
                    state <= READ_INFO;
            end

            READ_INFO:
                state <= GET_INFO;

            GET_INFO:
                state <= LOAD_INPUT;

            LOAD_INPUT:
                state <= SAVE_INPUT;

            SAVE_INPUT: begin
                if (load_idx == D-1)
                    state <= START_ROW;
                else
                    state <= LOAD_INPUT;
            end

            START_ROW:
                state <= READ_GATE;

            READ_GATE:
                state <= GET_GATE;

            GET_GATE:
                state <= ACCUMULATE;

            ACCUMULATE: begin
                if (col_idx == D-1)
                    state <= WRITE_OUT;
                else
                    state <= READ_GATE;
            end

            WRITE_OUT:
                state <= NEXT_ROW;

            NEXT_ROW: begin
                if (row_idx == D-1)
                    state <= FINISH;
                else
                    state <= START_ROW;
            end

            FINISH:
                state <= IDLE;

            default:
                state <= IDLE;

        endcase
    end
end
