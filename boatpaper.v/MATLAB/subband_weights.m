function W = subband_weights(tileSize, levels)
%SUBBAND_WEIGHTS JPEG 2000-style subband gain weight map for a tile.
%   W = subband_weights(tileSize, levels)
%
%   Returns a tileSize x tileSize map where W(i,j) is the L2-norm gain
%   weight of the subband containing pixel (i,j). Used to weight the
%   distortion contribution of each wavelet coefficient (PCRD weighting).
%
%   Standard 9/7 gains (squared): HL/LH at level l = 2^(2l-2)*2,
%   HH at level l = 2^(2l-2)*4, LL = 1.
%   (Matches the JPEG 2000 default subband weights.)

    W = ones(tileSize, tileSize);
    for l = 1:levels
        s = tileSize / 2^l;            % subband size at this level
        wH = 2^(2*l - 2) * 2;          % HL / LH weight (squared gain)
        wD = 2^(2*l - 2) * 4;          % HH  weight (squared gain)
        % Level-l subbands live in the top-left 2s x 2s region:
        % HL = top-right, LH = bottom-left, HH = bottom-right
        W(1:s,   s+1:2*s) = wH;        % HL
        W(s+1:2*s, 1:s)   = wH;        % LH
        W(s+1:2*s, s+1:2*s) = wD;      % HH
    end
    % Deepest LL region (top-left s x s) stays weight 1
end