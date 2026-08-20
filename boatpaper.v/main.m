%% JPEG 2000 EBCOT Tier-2 — Optimized Codestream Truncation
%  MATLAB implementation of:
%    Yu, K., Shi, L., Dai, Y., Li, Q., Liu, Y.
%    "Efficient VLSI design for real-time JPEG 2000 EBCOT module
%     with optimized codestream truncation"
%    Journal of Real-Time Image Processing, 2025.
%
%  Reproduces the paper's experiments:
%    - Images : Peppers, House (512x512 grayscale)
%    - Tiles  : 128x128, 5-level 9/7 DWT
%    - Ratios : 4:1, 8:1, 16:1, 32:1
%    - Tier-2 : Exact PCRD (reference), Traditional (division + 480-entry
%               LUT), Proposed (log-LUT Eq.8 + simplified 43-entry LUT)

clear; clc; close all;

% Add MATLAB functions folder to the path
if ~exist('j2k_compress', 'file')
    addpath(fullfile(pwd, 'MATLAB'));
end
fprintf('=== JPEG 2000 EBCOT Tier-2 Optimized Truncation ===\n');
fprintf('    Yu et al., J. Real-Time Image Process. (2025)\n\n');

%% Configuration
config.imageDir   = fullfile(pwd, 'Input');
config.outputDir  = fullfile(pwd, 'Output');
config.resultsDir = fullfile(pwd, 'Results');
config.figDir     = fullfile(pwd, 'Figures');

for d = {'outputDir','resultsDir','figDir'}
    if ~exist(config.(d{1}), 'dir')
        mkdir(config.(d{1}));
    end
end

% JPEG 2000 parameters (per paper)
config.tileSize  = 128;      % 128x128 tiles
config.levels    = 5;        % 5-level CDF 9/7 DWT
config.ratios    = [4, 8, 16, 32];
config.images    = {'peppers', 'house'};

% Tier-2 architectures to evaluate
config.methods   = {'exact', 'trad', 'proposed'};
config.methodLabels = {'Exact PCRD (Reference)', ...
                       'Traditional (Int-Div + 480 LUT)', ...
                       'Proposed (Log-LUT + 43 LUT)'};

fprintf('Config: tiles=%dx%d  DWT=%d levels  ratios=', ...
        config.tileSize, config.tileSize, config.levels);
fprintf('%d:1 ', config.ratios);
fprintf('\n\n');

%% Run pipeline for each image
allResults = struct();
for ii = 1:numel(config.images)
    imgName = config.images{ii};
    fprintf('========================================================\n');
    fprintf('IMAGE: %s\n', upper(imgName));
    fprintf('========================================================\n');

    % Load and prepare image
    p = fullfile(config.imageDir, [imgName '.tiff']);
    if ~exist(p, 'file'), p = fullfile(config.imageDir, [imgName '.tif']); end
    if ~exist(p, 'file'), error('Image %s not found in Input/', imgName); end
    I = imread(p);
    if size(I, 3) > 1, I = rgb2gray(I); end
    I = double(I);
    if size(I,1) ~= 512 || size(I,2) ~= 512
        I = imresize(I, [512 512]);
    end
    fprintf('  Loaded %s: %d x %d\n', imgName, size(I,1), size(I,2));

    % Per-method results table
    nRows = numel(config.methods) * numel(config.ratios);
    tbl = cell(nRows, 8);
    row = 0;

    for m = 1:numel(config.methods)
        method = config.methods{m};
        label  = config.methodLabels{m};
        for r = 1:numel(config.ratios)
            ratio = config.ratios(r);
            targetBPP = 8 / ratio;

            tic;
            [recon, bpp, stats] = j2k_compress(I, config.tileSize, ...
                config.levels, targetBPP, method);
            met = compute_metrics(I, recon);

            % Clock-cycle estimate (paper Sec. 4: 3 cycles/slope + LUT search)
            nBlocks = stats.nBlocks;
            cycles = estimate_cycles(nBlocks, method);

            row = row + 1;
            tbl{row,1} = label;
            tbl{row,2} = sprintf('%d:1', ratio);
            tbl{row,3} = bpp;
            tbl{row,4} = bpp * numel(I) / 8 / 1024;   % codestream KB
            tbl{row,5} = met.PSNR_dB;
            tbl{row,6} = met.SSIM;
            tbl{row,7} = cycles;
            tbl{row,8} = stats.targetSlope;

            fprintf('  %-42s %5s  BPP=%.4f  PSNR=%6.2f dB  SSIM=%.4f  Cyc=%d\n', ...
                    label, sprintf('%d:1', ratio), bpp, met.PSNR_dB, ...
                    met.SSIM, cycles);
        end
    end

    allResults.(imgName) = struct('table', {tbl}, ...
        'methods', {config.methods}, 'methodLabels', {config.methodLabels}, ...
        'ratios', {config.ratios});

    % Save CSV
    csvFile = fullfile(config.resultsDir, [imgName '_results.csv']);
    fid = fopen(csvFile, 'w');
    fprintf(fid, 'Architecture,CompRatio,BPP,CodestreamKB,PSNR_dB,SSIM,ClockCycles,TargetSlope\n');
    for r = 1:nRows
        fprintf(fid, '%s,%s,%.4f,%.2f,%.2f,%.4f,%d,%.2f\n', ...
                tbl{r,1}, tbl{r,2}, tbl{r,3}, tbl{r,4}, ...
                tbl{r,5}, tbl{r,6}, tbl{r,7}, tbl{r,8});
    end
    fclose(fid);
    fprintf('  Saved %s\n', csvFile);
end

%% Summary table
fprintf('\n\n================ FINAL RESULTS ================\n');
for ii = 1:numel(config.images)
    imgName = config.images{ii};
    res = allResults.(imgName);
    fprintf('\n--- %s ---\n', upper(imgName));
    fprintf('%-42s %-6s %-8s %-9s %-9s\n', 'Architecture', 'Ratio', ...
            'BPP', 'PSNR', 'SSIM');
    for r = 1:size(res.table,1)
        fprintf('%-42s %-6s %-8.4f %-9.2f %-9.4f\n', res.table{r,1}, ...
                res.table{r,2}, res.table{r,3}, res.table{r,5}, res.table{r,6});
    end
end

%% Figures
fprintf('\nGenerating figures...\n');
generate_results_figures(allResults, config);
fprintf('\nDone. Results in %s, figures in %s\n', ...
        config.resultsDir, config.figDir);
fprintf('=== Execution complete ===\n');