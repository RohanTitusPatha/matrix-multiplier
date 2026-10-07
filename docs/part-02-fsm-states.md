# Part 2 — FSM State Definitions

Planned flow:

IDLE → READ_INFO → GET_INFO → LOAD_INPUT → SAVE_INPUT → START_ROW → READ_GATE → GET_GATE → ACCUMULATE → WRITE_OUT → NEXT_ROW → FINISH

START_ROW prepares a new output row; it does not calculate the row yet.
