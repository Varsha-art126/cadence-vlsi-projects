# Ripple Carry Adder (RCA)

Full-custom **multi-bit Ripple Carry Adder** designed in Cadence Virtuoso. The RCA chains full adders in series, where each stage's carry-out feeds the next stage's carry-in. Simple and area-efficient, with verification through full layout and waveform simulation.

## Design Overview

| Item | Detail |
|------|--------|
| **Bit-width** | Multi-bit (cascaded full adders) |
| **Technique** | Ripple Carry (serial carry propagation) |
| **Technology** | Standard CMOS (Cadence Virtuoso) |
| **Inputs** | A[n:0], B[n:0], Cin |
| **Outputs** | Sum[n:0], Cout |
| **Verification** | Schematic simulation, layout DRC/LVS, netlist extraction |

## How It Works

Each full adder stage computes:
```
Sum_i  = A_i ⊕ B_i ⊕ Cin_i
Cout_i = (A_i · B_i) + (Cin_i · (A_i ⊕ B_i))
```
The carry ripples from the LSB to the MSB. Total delay scales linearly with bit-width.

## Files

| File | Description |
|------|-------------|
| `design of ripple.png` | Top-level block diagram / architecture |
| `Screenshot from 2026-06-16 02-40-00.png` | Schematic or additional design view |
| `LAYOYT OF RIPPLE CARRY ADDER.png` | Full-custom layout view |
| `gdsiii.png` | GDSII extraction view |
| `netlist of  ripple.png` | Extracted netlist |
| `tb ripple.png` | Testbench schematic |
| `waveforms of ripple.png` | Spectre transient simulation waveform |

## How to Verify

1. Review the design diagram (`design of ripple.png`) and schematic.
2. Run the testbench (`tb ripple.png`) through Spectre transient analysis.
3. Check the waveform (`waveforms of ripple.png`) — verify sum and carry propagate correctly through all stages.
4. Open the layout, run **DRC** and **LVS**, then extract to GDSII (`gdsiii.png`).
