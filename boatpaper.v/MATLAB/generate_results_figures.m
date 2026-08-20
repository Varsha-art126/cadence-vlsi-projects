function generate_results_figures(allResults, config)
%GENERATE_RESULTS_FIGURES Plot PSNR vs bit-rate curves for all methods.
%   generate_results_figures(allResults, config)

    imgNames = fieldnames(allResults);
    colors = {[0.0 0.45 0.74], [0.85 0.33 0.10], [0.47 0.67 0.19]};
    markers = {'o', 's', 'd'};

    for ii = 1:numel(imgNames)
        imgName = imgNames{ii};
        res = allResults.(imgName);
        tbl = res.table;

        nMethods = numel(res.methods);
        fig1 = figure('Visible', 'off', 'Position', [100 100 700 500]);
        hold on;
        for m = 1:nMethods
            label = res.methodLabels{m};
            bpp  = []; psnr = [];
            for r = 1:size(tbl,1)
                if strcmp(tbl{r,1}, label)
                    bpp(end+1)  = tbl{r,3};
                    psnr(end+1) = tbl{r,5};
                end
            end
            plot(bpp, psnr, ['-' markers{m}], 'Color', colors{m}, ...
                 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', label);
        end
        xlabel('Bit rate (bpp)', 'FontSize', 12);
        ylabel('PSNR (dB)', 'FontSize', 12);
        title(sprintf('%s - Rate-Distortion curves (Tier-2 truncation)', ...
              upper(imgName)), 'FontSize', 13);
        legend('Location', 'southwest');
        grid on;
        saveas(fig1, fullfile(config.figDir, sprintf('%s_RD_curves.png', imgName)));
        close(fig1);

        % PSNR vs compression ratio (paper Fig. 9 style)
        fig2 = figure('Visible', 'off', 'Position', [100 100 700 500]);
        hold on;
        for m = 1:nMethods
            label = res.methodLabels{m};
            rat = []; psnr = [];
            for r = 1:size(tbl,1)
                if strcmp(tbl{r,1}, label)
                    rat(end+1)  = str2double(tbl{r,2}(1:end-2));
                    psnr(end+1) = tbl{r,5};
                end
            end
            plot(rat, psnr, ['-' markers{m}], 'Color', colors{m}, ...
                 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', label);
        end
        xlabel('Compression ratio (N:1)', 'FontSize', 12);
        ylabel('PSNR (dB)', 'FontSize', 12);
        title(sprintf('%s - PSNR vs compression ratio', upper(imgName)), ...
              'FontSize', 13);
        legend('Location', 'southwest');
        grid on;
        set(gca, 'XDir', 'reverse');
        saveas(fig2, fullfile(config.figDir, sprintf('%s_PSNR_ratio.png', imgName)));
        close(fig2);

        % Clock cycles comparison (paper Fig. 8 / Table 2 style).
        % Only the two hardware architectures (traditional & proposed) are
        % shown; the exact/reference is a software PCRD without a hardware
        % LUT, so its cycle figure is not meaningful in a bar comparison.
        hwMethods = find(~cellfun(@(s) contains(lower(s), 'exact'), ...
                         res.methodLabels));
        if ~isempty(hwMethods)
            fig3 = figure('Visible', 'off', 'Position', [100 100 700 500]);
            hold on;
            cycData = zeros(numel(hwMethods), numel(res.ratios));
            for mi = 1:numel(hwMethods)
                m = hwMethods(mi);
                label = res.methodLabels{m};
                for r = 1:size(tbl,1)
                    if strcmp(tbl{r,1}, label)
                        ri = find(res.ratios == str2double(tbl{r,2}(1:end-2)), 1);
                        cycData(mi, ri) = tbl{r,7};
                    end
                end
            end
            h = bar(cycData', 'grouped');
            for mi = 1:numel(hwMethods)
                m = hwMethods(mi);
                h(mi).FaceColor = colors{m};
            end
            set(gca, 'XTickLabel', arrayfun(@(x) sprintf('%d:1', x), ...
                     res.ratios, 'UniformOutput', false));
            xlabel('Compression ratio', 'FontSize', 12);
            ylabel('Clock cycles', 'FontSize', 12);
            title(sprintf('%s - Tier-2 clock cycles (hardware)', ...
                  upper(imgName)), 'FontSize', 13);
            legend(res.methodLabels{hwMethods}, 'Location', 'northeast');
            grid on;
            saveas(fig3, fullfile(config.figDir, sprintf('%s_cycles.png', imgName)));
            close(fig3);
        end

        fprintf('  %s: %d figures saved\n', imgName, 2 + ~isempty(hwMethods));
    end
end
