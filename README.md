# FP8 3x3 Systolic Matrix Multiplier

A synthesizable Verilog implementation of a fixed-size 3x3 matrix multiplier built as a 3x3 systolic array. Each processing element forwards matrix operands through the array and accumulates one output element using a compact, custom 8-bit floating-point representation.

The design was developed for the Xilinx Artix-7 device used by the Digilent Basys 3 (`xc7a35tcpg236-1`) with Vivado 2024.2. The RTL itself is device-independent and can be synthesized for other FPGA families.

## Architecture

The top-level `systolic_mul` module contains nine `mac_fp` processing elements arranged in three rows and three columns. Inputs from matrix A move from left to right, while inputs from matrix B move from top to bottom. Staggered operand injection aligns the corresponding row and column terms at each processing element.

| Module | Purpose |
| --- | --- |
| `systolic_mul` | Controls operand scheduling, connects the 3x3 array, and generates `done`. |
| `mac_fp` | Registers forwarded operands and accumulates `a_in * b_in` each clock. |
| `fp_mult` | Combinational FP8 multiplication. |
| `fp_add` | Combinational FP8 addition and subtraction. |
| `fp_decode` | Extracts the sign, exponent, and normalized mantissa. |
| `fp_encode` | Normalizes and packs results, underflowing to zero and saturating overflow. |

### Number format

Operands and results use a project-specific FP8 E3M4 encoding:

```text
bit 7       bits 6:4       bits 3:0
sign        exponent       fraction
```

The exponent bias is 3 and normal values use an implicit leading one. `8'h00` is treated as zero. This is not a complete IEEE-754 floating-point implementation: subnormal values, infinities, NaNs, signed zero, and IEEE exception behavior are not supported.

## Interface

### Control inputs

| Signal | Width | Description |
| --- | ---: | --- |
| `clk` | 1 | Rising-edge clock. |
| `reset` | 1 | Synchronous active-high reset; clears control state, pipeline registers, and accumulators. |
| `start` | 1 | Begins an operation when the array is idle. Starts asserted while an operation is running are ignored. |

### Matrix inputs

`a00` through `a22` and `b00` through `b22` are 8-bit FP8 elements of input matrices A and B. Keep them stable while operands are injected into the array (through the first five active scheduling cycles).

### Outputs

| Signals | Matrix elements |
| --- | --- |
| `M1_out`, `M2_out`, `M3_out` | C00, C01, C02 |
| `M4_out`, `M5_out`, `M6_out` | C10, C11, C12 |
| `M7_out`, `M8_out`, `M9_out` | C20, C21, C22 |
| `done` | One-cycle pulse indicating completion. |

## Pipeline behavior and latency

Assert `reset` for a rising edge before starting an independent multiplication. When `start` is sampled high while idle, the controller begins a staggered injection schedule: row 0 and column 0 begin first, followed by later rows and columns on successive clocks. The registered processing elements propagate operands across and down the array while accumulating products.

`done` pulses seven rising edges after the edge that accepts `start`. The output accumulators are updated on that completion edge and remain available until reset or further accumulation. The implementation does not automatically clear accumulators between operations, so reset must be asserted before each independent matrix multiplication.

## Verification

Development verification used behavioral simulations for the FP8 adder, FP8 multiplier, and complete systolic array. Tests covered zero operands, positive and negative arithmetic, cancellation, exponent-range behavior, and a known 3x3 matrix multiplication case.

Testbench sources are intentionally not distributed in this public repository. Therefore, the repository does not currently include a reproducible automated regression or claim exhaustive numerical compliance.

TODO: Add newly authored, self-checking public tests with reference-model comparisons, edge-case coverage, and explicit pass/fail assertions.

## Simulation

Vivado can compile the RTL directly, but a testbench must be supplied locally:

1. Create or add a Verilog testbench that instantiates `systolic_mul`.
2. Add all files in `Lab5.srcs/sources_1/new/` listed by `scripts/create_project.tcl` as design sources.
3. Set the testbench as the simulation top.
4. Run behavioral simulation with XSim.

From the Vivado Tcl console, a project can be recreated with:

```tcl
source scripts/create_project.tcl
```

Then add your local testbench to the generated project and run **Flow > Run Simulation > Run Behavioral Simulation**.

TODO: Add a simulator-neutral command-line regression once redistributable tests are available.

## Vivado synthesis

Vivado 2024.2 or a compatible release is required for the supplied script. From the repository root:

```text
vivado -mode batch -source scripts/create_project.tcl
```

The script creates a project under `build/vivado/`, targets `xc7a35tcpg236-1`, adds only the six active RTL files, sets `systolic_mul` as the top, and applies a 100 MHz clock constraint in memory. Open the generated project or run synthesis from the Vivado Tcl console:

```tcl
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1
report_utilization
report_timing_summary
```

This top level exposes matrix elements as direct FPGA ports and does not include a board-level wrapper or pin assignments. Implementation and bitstream generation require a suitable wrapper and constraints for the target hardware.

## Timing and utilization

No verified timing or utilization results for the published `systolic_mul` top level are included. Generated reports found in the original working directory referred to a different top-level design, so their figures are deliberately not reported here.

TODO: Regenerate and record synthesis utilization and post-route timing for this exact revision and target device.

## Tradeoffs and limitations

- The fixed 3x3 array provides spatial parallelism but cannot be resized without RTL changes.
- Arithmetic is compact and combinational inside each processing element, prioritizing simplicity over high clock frequency.
- Intermediate FP8 accumulation saves resources but introduces substantial quantization error compared with a wider accumulator.
- Mantissa reduction uses truncation rather than round-to-nearest or another defined rounding mode.
- Underflow is flushed to zero and overflow saturates to the largest encoded magnitude.
- The arithmetic does not implement IEEE-754 special values or exception flags.
- Inputs are not latched as complete matrices, so the caller must keep them stable during injection.
- A reset is required between independent operations because `start` does not clear the accumulators.

Possible improvements include parameterizing matrix dimensions, adding valid/ready handshaking, latching input matrices, widening accumulators, defining rounding behavior, pipelining arithmetic paths, adding IEEE-like special-value handling, and providing a board-level streaming or memory-mapped interface.

