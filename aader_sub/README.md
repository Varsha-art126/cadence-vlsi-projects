# Adder / Subtractor

Full-custom **1-bit adder-subtractor** designed in Cadence Virtuoso. The circuit performs both addition and subtraction based on a control select signal, using XOR gates for conditional inversion and a full adder core.

## Design Overview

| Item | Detail |
|------|--------|
| **Function** | A + B (select=0) or A − B (select=1) |
| **Technology** | Standard CMOS (Cadence Virtuoso) |
| **Inputs** | A, B, Sel (1 bit each) |
| **Outputs** | Sum/Difference, Cout/Borrow |
| **Verification** | Schematic simulation, layout DRC/LVS clean |

## Files

| File | Description |
|------|-------------|
| `design.png` | Top-level design / block diagram |
| `schematic.png` | Cadence Virtuoso transistor-level schematic |
| `LAYOUT.png` | Full-custom layout view |
| `3d.png` | 3-D layout visualization |
| `tb.png` | Testbench schematic |
| `waveform.png` | Spectre transient simulation waveform |

## How to Verify

1. Open the schematic in Virtuoso and verify the transistor connections.
2. Run the testbench (`tb.png`) through Spectre transient analysis.
3. Check the output waveform (`waveform.png`) — Sum toggles on every input change, Carry propagates correctly.
4. Open the layout (`LAYOUT.png`) and run **DRC** and **LVS** to confirm no design-rule or schematic-vs-layout errors.
