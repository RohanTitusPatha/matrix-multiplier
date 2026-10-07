# Matrix Multiplier

An ongoing RTL project focused on developing a complete matrix multiplication accelerator using Verilog and FP64 arithmetic.

The project is being built incrementally, beginning with the core architecture and datapath and progressing toward a fully integrated matrix multiplier capable of handling runtime matrix dimensions, multiple gate matrices, SRAM-based data movement, intermediate results, and final output generation.

## Current Progress

The implementation currently includes:

1. Module declaration, parameters and SRAM-facing ports
2. FSM state definitions
3. Runtime parameters and control counters
4. Input-vector caching
5. FP64 fused multiply-add datapath

## Architecture

The design is centered around:

- SRAM interfaces for input, gate and output data
- Runtime-controlled matrix dimensions
- Counters for matrix, row and column traversal
- Local input-vector caching for data reuse
- IEEE-754 FP64 arithmetic
- Fused multiply-add operations for matrix dot products
- FSM-based control for sequencing memory and computation

## Development Roadmap

The next stages will integrate the control flow with SRAM timing, input loading, matrix traversal, accumulation, output writes, multi-matrix chaining and verification.

The end product will be a full-fledged matrix multiplier with a complete RTL datapath and control architecture, designed to process matrix operations efficiently while correctly managing memory access and FP64 computation.

## Status

**Ongoing development**
