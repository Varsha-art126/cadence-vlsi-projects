function cycles = estimate_cycles(nBlocks, method)
%ESTIMATE_CYCLES Estimate EBCOT Tier-2 clock cycles (paper Sec. 4).
%   cycles = estimate_cycles(nBlocks, method)
%
%   Model based on the paper's Tier-2 state machine (Fig. 8):
%     - CAL_SLOPE_1..3: 3 clock cycles per rate-distortion slope
%     - Rate-distortion slope + byte-correspondence LUT accumulation:
%       * traditional: full 480-entry table (0..479)
%       * proposed:    simplified 43-entry table
%     - The paper reports ~4.43-4.88% cycle reduction for the proposed
%       architecture over the traditional one.
%
%   nBlocks: total number of code-blocks in the image
%   method : 'exact' (software PCRD reference -- no hardware LUT),
%            'trad' (traditional HW), or 'proposed' (proposed HW)
%
%   NOTE: the 'exact' reference is a software-style floating-point PCRD
%   (Jasper-like). It performs no hardware LUT search, so its cycle count
%   is only the slope-computation + fixed overhead and is shown for
%   completeness; only 'trad' vs 'proposed' are comparable hardware
%   architectures.

    avgPlanes = 9;   % average bit-planes per code-block (8-bit + wavelet gain)
    nSlopes   = nBlocks * avgPlanes;   % total slope computations

    % 3 cycles per slope (CAL_SLOPE_1, CAL_SLOPE_2, CAL_SLOPE_3)
    slopeCycles = 3 * nSlopes;

    switch method
        case 'proposed'
            % Simplified 43-entry LUT: 43 accumulation + search steps
            lutCycles = 43 * 2;
        case 'exact'
            % Software reference: no hardware LUT search
            lutCycles = 0;
        otherwise
            % Traditional 480-entry LUT: 480 accumulation + search steps
            lutCycles = 480 * 2;
    end

    % Fixed overhead (state machine, RAM access, FIFO, codestream org.)
    overhead = 8000;

    cycles = slopeCycles + lutCycles + overhead;
end
