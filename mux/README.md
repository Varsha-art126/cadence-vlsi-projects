# Multiplexer (MUX)

Full-custom **multiplexer** designed in Cadence Virtuoso. The design implements 2:1 and/or 4:1 MUX functionality using transmission gates and/or NAND/NOR logic, with a compact custom layout.

## Design Overview

| Item | Detail |
|------|--------|
| **Function** | 2:1 / 4:1 Multiplexer |
| **Technology** | Standard CMOS (Cadence Virtuoso) |
| **Inputs** | Data inputs (D0, D1, ...), Select line(s) |
| **Outputs** | Y (selected output) |
| **Verification** | Layout DRC/LVS, GDSII extraction |

## Files

| File | Description |
|------|-------------|
| `mux.png` | Top-level design / block diagram |
| `layout.png` | Full-custom layout view |
| `layout_3d.png` | 3-D layout visualization |
| `gds file.png` | GDSII extraction view |
| `terminal.png` | Simulation terminal output / log |

## How to Verify

1. Review the design diagram (`mux.png`) to verify the MUX architecture.
2. Open the layout (`layout.png`) and run **DRC** to check design rules.
3. Run **LVS** to compare the layout against the schematic.
4. Extract to GDSII (`gds file.png`) and verify the final netlist.
