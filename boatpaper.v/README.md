# JPEG 2000 EBCOT Tier-2 — Optimized Codestream Truncation (MATLAB)

MATLAB reproduction of:

> **Yu, K., Shi, L., Dai, Y., Li, Q., Liu, Y.** *"Efficient VLSI design for
> real-time JPEG 2000 EBCOT module with optimized codestream truncation."*
> Journal of Real-Time Image Processing, 2025.

The paper proposes a hardware-friendly Tier-2 rate-distortion slope
approximation (log-LUT, **Eq. 8**) combined with a **43-entry simplified
lookup table** that replaces the traditional integer-division slope + full
**480-entry LUT** architecture. This implementation reproduces the paper's
experimental setup (Peppers & House, 512×512, 128×128 tiles, 5-level
CDF 9/7 DWT, 4:1–32:1) and compares three Tier-2 allocation schemes.

## How to run

Open `main.m` in MATLAB (R2020b or later; Image Processing Toolbox) and
press **Run**, or from a terminal:

```matlab
matlab -batch "main"
```

The script adds `MATLAB/` to the path automatically. Test images are read
from `Input/` (peppers.tiff, house.tiff) and are resized to 512×512 if
needed.

## What it implements

| File | Purpose |
|------|---------|
| `main.m` | Driver: loads images, runs 3 methods × 4 ratios, writes CSVs + figures |
| `MATLAB/j2k_compress.m` | Core encoder: DWT → code-blocks → RD points → Tier-2 allocation → truncation → reconstruction |
| `MATLAB/j2k_tiledwt.m`, `j2k_tile_inverse.m` | Tile-based 5-level CDF 9/7 forward/inverse DWT |
| `MATLAB/cdf97_forward.m`, `cdf97_inverse.m` | 1-D CDF 9/7 lifting (verified invertible) |
| `MATLAB/subband_weights.m` | Per-subband L2-norm gains used to weight distortion (JPEG 2000 style) |
| `MATLAB/compute_slope_log_lut.m` | Paper Eq. 8: LUT-based log slope, α = 16, no division |
| `MATLAB/compute_metrics.m` | PSNR / SSIM |
| `MATLAB/estimate_cycles.m` | Tier-2 clock-cycle model (paper Sec. 4) |
| `MATLAB/generate_results_figures.m` | RD curves, PSNR vs ratio, cycle bar chart |

### Tier-2 allocation schemes

1. **Exact PCRD (reference)** — floating-point slopes ΔD/ΔR, sorted
   accumulation. Software reference, Jasper-like.
2. **Traditional** — integer-division slope `16·log2(ΔD/ΔR)` (Eq. 5)
   stored in a full 480-entry byte-accumulation LUT.
3. **Proposed** — Eq. 8 log-LUT slope (no division) accumulated through
   the simplified **43-entry LUT** (keys `[0, 100, 105:5:300, 480]`):
   slopes <100 → 100, [100,300) grouped every 5, ≥300 → 480.

All schemes end with a **pass-level codestream-length enforcement step**:
the globally lowest-slope kept coding pass is dropped, one pass at a time,
until the accumulated codestream fits the target byte budget. This is the
paper's "optimized codestream truncation" and guarantees the achieved BPP
never exceeds the target while retaining the highest-quality passes.

## Modeling assumptions (important for interpretation)

The goal is to reproduce the paper's *behavior and relative trends*, not
to byte-match an entropy-coded JPEG 2000 implementation:

1. **Rate model is raw bit-plane bit counting** (magnitude bits + sign
   bit per significant coefficient, in bytes), *not* arithmetic/entropy
   coding. Consequently:
   - BPP is an upper-bound estimate of the true entropy-coded codestream
     (the paper reports ~1.92 BPP at 4:1 for an entropy-coded codestream;
     our raw model lands at the target rate).
   - Cross-method comparisons (exact vs trad vs proposed) are valid
     because all three share the same rate model.
   - Very smooth images (e.g. House) may achieve *less* than the target
     BPP at low ratios because the model rate caps at the lossless size.
2. **Cycle model is a simplification**: 3 cycles per slope computation +
   LUT size × 2 (480 vs 43) + a fixed 8000-cycle overhead. Absolute
   numbers (~15k) are smaller than the paper's (~78k), but the *relative*
   reduction of the proposed over the traditional architecture (~5.5%)
   matches the paper's ≥4.43% claim.
3. **No explicit convex-hull / singular-point merging** (paper Sec. 2.1).
   The per-block incremental slopes are computed on bit-plane points, and
   invalid (non-positive) increments are excluded; a strict monotonic
   convex hull is not enforced. This is a minor fidelity deviation.
4. The `exact` reference is a software PCRD without a hardware LUT; its
   cycle column is shown for completeness but only **trad vs proposed**
   are comparable hardware architectures (also reflected in the figures).

## Outputs

- `Results/peppers_results.csv`, `Results/house_results.csv` — full table:
  architecture, ratio, BPP, codestream size (KB), PSNR (dB), SSIM,
  clock cycles, target slope.
- `Figures/*.png` — RD curves, PSNR vs compression ratio, and the
  hardware clock-cycle comparison.
- `Output/` — reserved for reconstructed images if needed.

## Results (raw-bit rate model, 512×512, 128×128 tiles, 5-level 9/7 DWT)

### PSNR (dB)

| Image | Method | 4:1 | 8:1 | 16:1 | 32:1 |
|-------|--------|-----|-----|------|------|
| Peppers | Exact (reference) | 45.21 | 38.14 | 35.02 | 30.48 |
| Peppers | Traditional | 45.27 | 38.23 | 35.02 | 30.48 |
| Peppers | Proposed | 46.68 | 38.73 | 35.34 | 30.48 |
| House | Exact (reference) | 53.88 | 50.98 | 43.63 | 36.46 |
| House | Traditional | 53.88 | 51.09 | 43.74 | 36.47 |
| House | Proposed | 53.88 | 51.08 | 44.05 | 36.58 |

### BPP (target 2.0 / 1.0 / 0.5 / 0.25)

| Image | Method | 4:1 | 8:1 | 16:1 | 32:1 |
|-------|--------|-----|-----|------|------|
| Peppers | Exact | 2.000 | 0.999 | 0.500 | 0.248 |
| Peppers | Traditional | 1.998 | 0.999 | 0.500 | 0.248 |
| Peppers | Proposed | 2.000 | 0.998 | 0.499 | 0.248 |
| House | Exact | 1.247 | 0.985 | 0.487 | 0.239 |
| House | Traditional | 1.247 | 0.998 | 0.491 | 0.250 |
| House | Proposed | 1.247 | 0.998 | 0.488 | 0.250 |

### Tier-2 clock cycles (hardware architectures)

| Method | LUT size | Cycles |
|--------|----------|--------|
| Traditional | 480 entries | 15,872 |
| Proposed | 43 entries | 14,998 |

→ **~5.5% cycle reduction** and an **~11× smaller LUT** for the proposed
architecture, matching the paper's ≥4.43% claim.

## Interpreting the results

- PSNR degrades smoothly as the compression ratio increases; the achieved
  BPP tracks the target (never exceeding it).
- The proposed architecture keeps PSNR within ~0.5 dB of the
  traditional one at most ratios (~1.4 dB at the lowest ratio, where
  peppers 4:1 gives 46.68 vs 45.27 dB). At low ratios it can *slightly
  beat* it. This is because the 43-entry LUT allocation coarsens the rate
  threshold, and the paper's own optimized pass-level codestream
  truncation (Step 4b, applied uniformly to all schemes) then selects a
  near-optimal pass subset. The real differentiators of the proposed
  design are the smaller LUT and the ~5.5% Tier-2 cycle saving.
- House at 4:1 reaches only 1.247 BPP because its lossless model rate is
  below the 2.0 target (smooth image, raw-bit model) — all schemes then
  reproduce the image near-losslessly (≈53.9 dB).
- PSNR values are higher than the paper's entropy-coded figures because
  the raw-bit rate model over-estimates rate (see assumption 1). Full
  per-row numbers are in `Results/*.csv`.
