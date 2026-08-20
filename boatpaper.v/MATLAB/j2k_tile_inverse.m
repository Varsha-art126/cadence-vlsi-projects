function I = j2k_tile_inverse(allCoeffs, outSize, tileSize, levels)
%J2K_TILE_INVERSE Apply inverse tile-based DWT and reconstruct image.
%   I = j2k_tile_inverse(allCoeffs, outSize, tileSize, levels)
%
%   allCoeffs: cell array from j2k_tiledwt (or after quantization/modification)
%   outSize: [h, w] original image dimensions before padding
%   tileSize: tile dimension
%   levels: wavelet decomposition levels
%
%   Returns: reconstructed image (double, original dimensions)

    nTiles = numel(allCoeffs);
    tilesPerSide = sqrt(nTiles);
    nTilesH = ceil(outSize(1) / tileSize);
    nTilesW = ceil(outSize(2) / tileSize);

    % Reconstruct tiles
    I = zeros(nTilesH * tileSize, nTilesW * tileSize);
    idx = 1;
    for ty = 1:nTilesH
        for tx = 1:nTilesW
            tile = cdf97_inverse(allCoeffs{idx}, levels);
            r1 = (ty-1) * tileSize + 1;
            r2 = ty * tileSize;
            c1 = (tx-1) * tileSize + 1;
            c2 = tx * tileSize;
            I(r1:r2, c1:c2) = tile;
            idx = idx + 1;
        end
    end

    % Crop to original size
    I = I(1:outSize(1), 1:outSize(2));
end