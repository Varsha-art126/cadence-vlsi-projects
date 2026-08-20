function [recon, bpp, stats] = j2k_compress(orig, tileSize, levels, targetBPP, method)
%J2K_COMPRESS JPEG 2000-style compression with EBCOT Tier-2 truncation.
%   [recon, bpp, stats] = j2k_compress(orig, tileSize, levels, targetBPP, method)
%
%   method: 'exact'    -> full PCRD (floating point slopes)
%           'trad'     -> traditional integer-division slopes + 480-entry LUT
%           'proposed' -> log-LUT slopes (Eq. 8) + simplified 43-entry LUT
%
%   Pipeline (per the paper):
%     1. Tile-based 5-level CDF 9/7 DWT
%     2. Per-code-block bit-plane RD truncation points (distortion & rate)
%     3. Rate-distortion slope per truncation point
%     4. Tier-2 rate allocation via LUT byte accumulation to target budget
%     5. Pass-level codestream truncation to enforce the byte budget
%     6. Truncate coefficients, inverse DWT, return reconstructed image
%
%   References: Yu et al., "Efficient VLSI design for real-time JPEG 2000
%   EBCOT module with optimized codestream truncation", JRTIP 2025.

    orig = double(orig);
    [h, w] = size(orig);
    nPixels = h * w;
    targetBytes = round(targetBPP * nPixels / 8);

    % Step 1: tile-based DWT
    allCoeffs = j2k_tiledwt(orig, tileSize, levels);
    nTiles = numel(allCoeffs);

    % Precompute subband weight map (identical for every tile)
    Wtile = subband_weights(tileSize, levels);

    % Step 2: partition into code-blocks and build RD truncation points
    blockSize = 32;
    nBperTile_h = ceil(tileSize / blockSize);
    nBperTile_w = ceil(tileSize / blockSize);
    nBlocks = nTiles * nBperTile_h * nBperTile_w;

    blockR = cell(nBlocks, 1);
    blockD = cell(nBlocks, 1);
    blockMaxBp = zeros(nBlocks, 1);
    blockIncS = cell(nBlocks, 1);   % per-block increment slopes (method-specific)

    blkIdx = 0;
    for tt = 1:nTiles
        C = allCoeffs{tt};
        for by = 1:nBperTile_h
            for bx = 1:nBperTile_w
                r1 = (by-1)*blockSize + 1; r2 = by*blockSize;
                c1 = (bx-1)*blockSize + 1; c2 = bx*blockSize;
                blk = C(r1:r2, c1:c2);
                wblk = Wtile(r1:r2, c1:c2);
                blkIdx = blkIdx + 1;

                coeffs = blk(:);
                weights = wblk(:);
                mags = abs(coeffs);
                maxMag = max(mags);
                if maxMag == 0
                    blockR{blkIdx} = 0;
                    blockD{blkIdx} = 0;
                    blockMaxBp(blkIdx) = 0;
                    blockIncS{blkIdx} = [];
                    continue;
                end

                maxBp = floor(log2(maxMag)) + 1;
                blockMaxBp(blkIdx) = maxBp;

                nbitsPerCoef = zeros(numel(coeffs), 1);
                nz = mags > 0;
                nbitsPerCoef(nz) = floor(log2(mags(nz))) + 1;

                % Index convention: cumR(t+1) = rate when t LSB planes
                % dropped (t=0 -> lossless, t=maxBp -> all dropped).
                cumR = zeros(maxBp + 1, 1);
                cumD = zeros(maxBp + 1, 1);
                for t = 0:maxBp
                    thresh = 2^t;
                    q = sign(coeffs) .* (floor(mags / thresh) .* thresh);
                    err = (coeffs - q) .* weights;
                    cumD(t+1) = sum(err.^2);
                    nzAtT = mags >= thresh;
                    bits = sum(max(nbitsPerCoef - t, 0)) + sum(nzAtT);
                    cumR(t+1) = bits / 8;
                end
                blockR{blkIdx} = cumR;
                blockD{blkIdx} = cumD;
            end
        end
    end

    % Step 3: incremental (deltaR, deltaD) pairs + slopes per block.
    % Pass tp (tp=1..maxBp) adds plane (tp-1): going from tp planes
    % dropped to (tp-1) dropped. Both dR and dD are positive.
    for k = 1:nBlocks
        if blockMaxBp(k) < 1
            continue;
        end
        cumR = blockR{k}; cumD = blockD{k};
        maxBp = blockMaxBp(k);
        ss = zeros(maxBp, 1);
        for tp = 1:maxBp
            dR = cumR(tp) - cumR(tp+1);
            dD = cumD(tp+1) - cumD(tp);
            if dR > 0 && dD >= 0
                switch method
                    case 'exact'
                        ss(tp) = dD / dR;
                    case 'trad'
                        % Eq. 5: S = alpha*(log2(dD) - log2(dR)), alpha=16.
                        % Traditional HW computes this via division + log,
                        % stored in a 480-entry table.
                        ss(tp) = min(max(round(16 * log2(dD / dR)), 0), 480);
                    case 'proposed'
                        % Eq. 8: LUT-based log slope (no division).
                        ss(tp) = compute_slope_log_lut(round(dD), round(dR));
                end
            else
                ss(tp) = -inf;   % never selected
            end
        end
        blockIncS{k} = ss;
    end

    % Collect all valid increments for global rate allocation
    incR = []; incS = [];
    for k = 1:nBlocks
        if blockMaxBp(k) < 1
            continue;
        end
        cumR = blockR{k};
        maxBp = blockMaxBp(k);
        ss = blockIncS{k};
        for tp = 1:maxBp
            if ss(tp) > -inf && cumR(tp) - cumR(tp+1) > 0
                incR(end+1) = cumR(tp) - cumR(tp+1);
                incS(end+1) = ss(tp);
            end
        end
    end

    if isempty(incR)
        recon = max(0, min(255, j2k_tile_inverse(allCoeffs, [h,w], tileSize, levels)));
        bpp = 0;
        stats = struct('targetSlope', 0, 'selectedBytes', 0, 'nBlocks', nBlocks);
        return;
    end

    % --- Tier-2 rate allocation (paper Section 3.3) ---
    if strcmp(method, 'proposed')
        targetSlope = allocate_simplified_lut(incS, incR, targetBytes);
    else
        targetSlope = allocate_full_lut(incS, incR, targetBytes, ...
                                        strcmp(method, 'exact'));
    end

    % Step 4: per-block truncation. Keep every pass with slope >= lambda.
    % t = maxBp - (#kept passes). This is standard PCRD greedy allocation.
    bestT = zeros(nBlocks, 1);
    selectedBytes = 0;
    for k = 1:nBlocks
        if blockMaxBp(k) < 1
            continue;
        end
        cumR = blockR{k};
        maxBp = blockMaxBp(k);
        ss = blockIncS{k};
        if strcmp(method, 'proposed')
            % Compare the simplified-LUT bin keys (consistent with the
            % allocation step). Passes whose mapped key >= target are kept.
            % Invalid passes (slope = -inf) are never kept.
            valid = ss > -inf;
            keys = arrayfun(@map_slope_to_bin, ss(valid));
            kept = sum(keys >= targetSlope);
        else
            kept = sum(ss >= targetSlope);
        end
        t = maxBp - kept;               % planes dropped
        t = min(max(t, 0), maxBp);
        bestT(k) = t;
        selectedBytes = selectedBytes + cumR(t+1);
    end

    % Step 4b: Tier-2 final codestream-length enforcement (pass-level
    % truncation to the byte budget). The LUT allocation is byte-coarse,
    % so it can overshoot the target when many passes fall into the lowest
    % LUT bin (e.g. proposed slope floor 100). Drop the globally-lowest-
    % slope kept pass, one at a time, until the accumulated codestream fits
    % the target byte budget. This is the paper's "optimized codestream
    % truncation" and is the dual of greedy inclusion in descending slope
    % order: the highest-quality passes are always kept first.
    if selectedBytes > targetBytes
        remSlope = inf(nBlocks, 1);    % slope of each block's lowest kept pass
        remBytes = zeros(nBlocks, 1);  % bytes freed by dropping that pass
        for k = 1:nBlocks
            if blockMaxBp(k) < 1
                continue;
            end
            t = bestT(k);
            if t >= blockMaxBp(k)
                continue;              % nothing kept, nothing to drop
            end
            cumR = blockR{k};
            ss = blockIncS{k};
            tp = t + 1;                % lowest kept pass (adds plane t)
            remSlope(k) = max(ss(tp), -1e9);  % -inf (empty plane) drops for free
            remBytes(k) = cumR(t+1) - cumR(t+2);
        end
        while selectedBytes > targetBytes
            [mn, k] = min(remSlope);
            if isinf(mn)               % no more passes to drop
                break;
            end
            selectedBytes = selectedBytes - remBytes(k);
            bestT(k) = bestT(k) + 1;
            t = bestT(k);
            if t >= blockMaxBp(k)
                remSlope(k) = inf;
            else
                cumR = blockR{k};
                ss = blockIncS{k};
                tp = t + 1;
                remSlope(k) = max(ss(tp), -1e9);  % -inf (empty plane) drops for free
                remBytes(k) = cumR(t+1) - cumR(t+2);
            end
        end
    end

    % Step 5: quantize coefficients to chosen truncation and reconstruct
    truncatedCoeffs = cell(nTiles, 1);
    blkIdx = 0;
    for tt = 1:nTiles
        C = allCoeffs{tt};
        for by = 1:nBperTile_h
            for bx = 1:nBperTile_w
                r1 = (by-1)*blockSize + 1; r2 = by*blockSize;
                c1 = (bx-1)*blockSize + 1; c2 = bx*blockSize;
                blkIdx = blkIdx + 1;
                if blockMaxBp(blkIdx) < 1
                    C(r1:r2, c1:c2) = 0;
                    continue;
                end
                thresh = 2^bestT(blkIdx);
                blk = C(r1:r2, c1:c2);
                C(r1:r2, c1:c2) = sign(blk) .* (floor(abs(blk)/thresh) .* thresh);
            end
        end
        truncatedCoeffs{tt} = C;
    end

    recon = j2k_tile_inverse(truncatedCoeffs, [h, w], tileSize, levels);
    recon = max(0, min(255, recon));

    bpp = selectedBytes * 8 / nPixels;
    stats = struct('targetSlope', targetSlope, 'selectedBytes', selectedBytes, ...
                   'nBlocks', nBlocks);
end

% ------------------------------------------------------------------------
function targetSlope = allocate_simplified_lut(slopes, incR, targetBytes)
%ALLOCATE_SIMPLIFIED_LUT 43-entry simplified LUT allocation (paper Sec 3.3).
%   Byte distribution: slopes <100 -> 100, [100,300) grouped every 5,
%   >=300 -> 480. Keys: [0, 100, 105:5:300, 480] = 43 entries.

    keys = [0, 100, 105:5:300, 480];
    binBytes = zeros(numel(keys), 1);

    for i = 1:numel(slopes)
        s = slopes(i);
        if s < 100
            key = 100;
        elseif s >= 300
            key = 480;
        else
            key = ceil(s / 5) * 5;
            key = min(max(key, 100), 300);
        end
        idx = find(keys == key, 1);
        if ~isempty(idx)
            binBytes(idx) = binBytes(idx) + incR(i);
        end
    end

    [~, order] = sort(keys, 'descend');
    cum = 0; targetSlope = 0;
    for i = 1:numel(order)
        k = order(i);
        cum = cum + binBytes(k);
        if cum >= targetBytes
            targetSlope = keys(k);
            break;
        end
    end
    if targetSlope == 0
        targetSlope = keys(order(end));
    end
end

% ------------------------------------------------------------------------
function targetSlope = allocate_full_lut(slopes, incR, targetBytes, isExact)
%ALLOCATE_FULL_LUT 480-entry (traditional) or exact-float PCRD allocation.
    if isExact
        [ss, idx] = sort(slopes, 'descend');
        cum = 0; targetSlope = ss(end);
        for i = 1:numel(ss)
            cum = cum + incR(idx(i));
            if cum >= targetBytes
                targetSlope = ss(i);
                break;
            end
        end
    else
        maxSlope = 480;
        binBytes = zeros(maxSlope + 1, 1);
        for i = 1:numel(slopes)
            s = min(max(round(slopes(i)), 0), maxSlope);
            binBytes(s + 1) = binBytes(s + 1) + incR(i);
        end
        cum = 0; targetSlope = 0;
        for s = maxSlope:-1:0
            cum = cum + binBytes(s + 1);
            if cum >= targetBytes
                targetSlope = s;
                break;
            end
        end
    end
end

function key = map_slope_to_bin(s)
%MAP_SLOPE_TO_BIN Map a proposed-method slope to its simplified LUT bin key.
%   Paper Sec 3.3: slopes <100 -> 100, [100,300) grouped every 5 (ceil),
%   >=300 -> 480.
    if s < 100
        key = 100;
    elseif s >= 300
        key = 480;
    else
        key = ceil(s / 5) * 5;
        key = min(max(key, 100), 300);
    end
end
