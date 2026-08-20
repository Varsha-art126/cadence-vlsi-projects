# VLSI Design Projects

A collection of VLSI/EDA design projects implemented using **Cadence Virtuoso** for custom IC layout, schematic capture, and simulation. These projects cover fundamental digital building blocks from gate-level adders to a complete ALU, along with a MATLAB-based research reproduction of a JPEG 2000 EBCOT optimization paper.

---

## Projects

| Folder | Project | Description |
|--------|---------|-------------|
| [`aader_sub/`](aader_sub/) | **Adder / Subtractor** | 1-bit full adder-subtractor with full-custom layout, schematic, DRC-clean GDSII, and waveform verification |
| [`alu_8/`](alu_8/) | **8-bit ALU** | 8-bit Arithmetic Logic Unit supporting ADD, SUB, AND, OR, XOR — full layout, schematic, and testbench |
| [`boatpaper.v/`](boatpaper.v/) | **JPEG 2000 EBCOT Tier-2** | MATLAB reproduction of an optimized EBCOT codestream truncation paper (CDF 9/7 DWT, RD slope LUT) |
| [`cla/`](cla/) | **Carry Look-Ahead Adder** | 4-bit CLA with fast carry propagation — layout, schematic, netlist, and simulation |
| [`mux/`](mux/) | **Multiplexer** | 2:1 / 4:1 MUX with custom layout and GDSII extraction |
| [`rca/`](rca/) | **Ripple Carry Adder** | Multi-bit ripple carry adder with full layout, testbench, and waveform results |

## Tools Used

- **Cadence Virtuoso** — Schematic editor, layout editor (Layout XL)
- **Cadence Spectre** — SPICE-level simulation
- **Cadence Encounter** — P&R and GDSII generation
- **MATLAB R2020b+** — Algorithm-level research reproduction (boatpaper.v)

## Repository Structure

```
cadence-vlsi-projects/
├── aader_sub/        # Adder/Subtractor — design, layout, waveform
├── alu_8/            # 8-bit ALU — design, layout, GDSII
├── boatpaper.v/      # J2K EBCOT research — MATLAB code, figures, results
├── cla/              # Carry Look-Ahead Adder — layout, netlist, wave
├── mux/              # Multiplexer — layout, GDSII, terminal
└── rca/              # Ripple Carry Adder — layout, waveforms, netlist
```

## Author

**Varsha-art126** — [GitHub](https://github.com/Varsha-art126)
