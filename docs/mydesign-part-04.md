# Part 4 — Reset, header, and vector loading

Source: `rtl/part4.v`.

## Reset and handshake
Active-low `reset_n` resets the FSM, counters, SRAM addresses, write enables, and accumulators. A `dut_valid` pulse in `IDLE` lowers `dut_ready` and initiates the header read.

## Header
The upper 64 bits specify Q and the lower 64 bits specify M. The code rejects `Q>MAX_Q` and a nonzero upper half of M. A valid Q gives `dim=2^Q`; Q=0 gives a one-element vector.

## Streaming vector load
The first matrix reads the input SRAM from address 1 onward (address 0 is the header). Subsequent matrices read the prior intermediate vector from scratchpad SRAM starting at address 0. Issued/read counters are used to overlap consecutive SRAM reads.

## M=0
The `IDENTITY` state writes the input vector directly to output SRAM.

## Verification caution
Correctness of `LOAD_PRIME` / `LOAD_STREAM` depends on the testbench SRAM's clocked-read semantics. Verify address-to-data alignment, especially the first two and last two words.
