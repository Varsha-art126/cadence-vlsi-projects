# 8-bit ALU

Full-custom **8-bit Arithmetic Logic Unit** designed in Cadence Virtuoso. The ALU supports both arithmetic operations (ADD, SUB) and logical operations (AND, OR, XOR) selected via a 3-bit opcode, producing an 8-bit result and carry/borrow flag.

## Design Overview

| Item | Detail |
|------|--------|
| **Bit-width** | 8-bit |
| **Operations** | ADD, SUB, AND, OR, XOR (selectable via opcode) |
| **Technology** | Standard CMOS (Cadence Virtuoso) |
| **Inputs** | A[7:0], B[7:0], Opcode[2:0] |
| **Outputs** | Result[7:0], Cout |
| **Verification** | Schematic simulation, layout DRC/LVS, GDSII extraction |

## Files

| File | Description |
|------|-------------|
| `alu_design.png` | Top-level ALU architecture / block diagram |
| `schematic_alu.png` | Transistor-level schematic in Virtuoso |
| `LAYOUT.png` | Full-custom layout view |
| `3_d layout.png` | 3-D layout visualization |
| `gdsii.png` | GDSII file extraction view |
| `alu_tb.png` | Testbench schematic |
| `alu_waveform.png` | Spectre transient simulation waveform |

## Opcode Map

| Opcode | Operation |
|--------|-----------|
| 000 | ADD |
| 001 | SUB |
| 010 | AND |
| 011 | OR |
| 100 | XOR |

## How to Verify

1. Open the schematic (`schematic_alu.png`) and inspect the datapath and control logic.
2. Run the testbench (`alu_tb.png`) through Spectre transient analysis.
3. Verify the waveform (`alu_waveform.png`) — check each opcode produces the correct result.
4. Open the layout, run **DRC** and **LVS**, then extract to GDSII (`gdsii.png`).
