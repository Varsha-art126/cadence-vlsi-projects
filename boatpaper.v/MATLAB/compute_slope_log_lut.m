function [S, lut1, lut2] = compute_slope_log_lut(deltaD, deltaR)
%COMPUTE_SLOPE_LOG_LUT Compute slope using the paper's log-LUT method (Eq. 8).
%   [S, lut1, lut2] = compute_slope_log_lut(deltaD, deltaR)
%
%   Implements the paper's Eqs. 5-8 approach:
%
%   Eq. 5: S = alpha * (log2(ΔD) - log2(ΔR))  with alpha = 16
%
%   Eq. 6-7: X = 2^beta * (1 + gamma/2^delta)
%            log2(X) = beta + log2(1 + gamma/2^delta)
%
%   Eq. 8: S = [2^4*(n1-n2) + 2*LUT(gamma1) - 2*LUT(gamma2)] / 2
%
%   Using alpha = 16 on the same scale as the traditional method (Eq. 5),
%   this gives:
%
%     S = 16*(n1-n2) + lut1 - lut2
%       ~ 16*(log2(ΔD) - log2(ΔR))
%
%   where lut = round(16*log2(1 + gamma/256)) approximates the fractional
%   term with a 256-entry lookup table (no division required).
%
%   The paper's Fig. 3 shows slopes in range [0, 480], so slopes are
%   later clamped/binned by the Tier-2 allocation LUT.

    persistent LUT lutBuilt
    if isempty(lutBuilt)
        LUT = zeros(256, 1);
        for g = 0:255
            % LUT = 16 * log2(1 + g/256)
            % Range: g=0 -> 0, g=255 -> round(16*log2(1+255/256)) = 16
            LUT(g + 1) = round(16 * log2(1 + g / 256));
        end
        lutBuilt = true;
    end

    % Clamp to positive integers
    deltaD = max(round(deltaD), 1);
    deltaR = max(round(deltaR), 1);

    % Highest non-zero bit position (n = floor(log2(X)))
    n1 = floor(log2(deltaD));
    n2 = floor(log2(deltaR));

    % gamma = remaining bits after MSB
    gamma1 = deltaD - 2^n1;
    gamma2 = deltaR - 2^n2;

    % Guard against floating-point rounding
    gamma1 = max(gamma1, 0);
    gamma2 = max(gamma2, 0);
    gamma1 = min(gamma1, 255);
    gamma2 = min(gamma2, 255);

    lut1 = LUT(gamma1 + 1);
    lut2 = LUT(gamma2 + 1);

    % Eq. 8 with alpha = 16:
    % S = [16*(n1-n2) + 2*LUT(gamma1) - 2*LUT(gamma2)] / 2
    %   = 8*(n1-n2) + lut1 - lut2    -- if LUT held 32*log2 values
    %
    % Here LUT already includes the alpha=16 scale (16*log2(1+g/256)),
    % so S = 16*(n1-n2) + lut1 - lut2, matching the traditional scale.
    S = 16 * (n1 - n2) + lut1 - lut2;
end
