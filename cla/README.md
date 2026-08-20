# Carry Look-Ahead Adder (CLA)

Full-custom **4-bit Carry Look-Ahead Adder** designed in Cadence Virtuoso. The CLA computes all carry bits in parallel using generate (G) and propagate (P) logic, significantly reducing the carry chain delay compared to a ripple carry adder.

## Design Overview

| Item | Detail |
|------|--------|
| **Bit-width** | 4-bit |
| **Technique** | Carry Look-Ahead (parallel carry computation) |
| **Technology** | Standard CMOS (Cadence Virtuoso) |
| **Inputs** | A[3:0], B[3:0], Cin |
| **Outputs** | Sum[3:0], Cout |
| **Verification** | Schematic simulation, layout DRC/LVS, netlist extraction |

## CLA Equations

```
G_i = A_i · B_i          (Generate)
P_i = A_i ⊕ B_i          (Propagate)

C1 = G0 + P0·C0
C2 = G1 + P1·G0 + P1·P0·C0
C3 = G2 + P2·G1 + P2·P1·G0 + P2·P1·P0·C0
C4 = G3 + P3·G2 + P3·P2·G1 + P3·P2·P1·G0 + P3·P2·P1·P0·C0
```

## Files

| File | Description |
|------|-------------|
| `design_cla.png` | Top-level block diagram / architecture |
| `schematic_cla.png` | Transistor-level schematic in Virtuoso |
| `LAYOUT_CLA.png` | Full-custom layout view |
| `gdsii.png` | GDSII extraction view |
| `netlist_cla.png` | Extracted netlist |
| `cla_tb.png` | Testbench schematic |
| `cla_wave.png` | Spectre transient simulation waveform |

## How to Verify

1. Review the CLA schematic (`schematic_cla.png`) — verify G and P generate blocks and the carry-lookahead chain.
2. Run the testbench (`cla_tb.png`) through Spectre.
3. Check the waveform (`cla_wave.png`) — all sum and carry outputs should stabilize in one propagation delay (no rippling).
4. Run **DRC** and **LVS** on the layout (`LAYOUT_CLA.png`), then extract the netlist (`netlist_cla.png`).
