function allCoeffs = j2k_tiledwt(I, tileSize, levels)
%J2K_TILEDWT Partition image into tiles and apply multi-level CDF 9/7 DWT.
%   allCoeffs = j2k_tiledwt(I, tileSize, levels)
%
%   I: input image (grayscale double, 0-255)
%   tileSize: tile dimension (e.g., 128 for 128x128 tiles)
%   levels: number of wavelet decomposition levels (e.g., 5)
%
%   Returns: cell array allCoeffs, one tile per cell, each with the
%   wavelet coefficient matrix for that tile.
%
%   Matches JPEG 2000 tiling: image is padded if needed, tiles are
%   non-overlapping. Tiles are processed independently.

    I = double(I);
    [h, w] = size(I);

    % Pad image to integer number of tiles
    padH = ceil(h / tileSize) * tileSize - h;
    padW = ceil(w / tileSize) * tileSize - w;
    if padH > 0 || padW > 0
        I = padarray(I, [padH, padW], 'replicate', 'post');
    end
    [hP, wP] = size(I);

    % Tile indices
    nTilesH = hP / tileSize;
    nTilesW = wP / tileSize;
    nTiles = nTilesH * nTilesW;

    allCoeffs = cell(nTiles, 1);
    idx = 1;
    for ty = 1:nTilesH
        for tx = 1:nTilesW
            r1 = (ty-1) * tileSize + 1;
            r2 = ty * tileSize;
            c1 = (tx-1) * tileSize + 1;
            c2 = tx * tileSize;
            tile = I(r1:r2, c1:c2);
            % Apply CDF 9/7 DWT
            allCoeffs{idx} = cdf97_forward(tile, levels);
            idx = idx + 1;
        end
    end
end