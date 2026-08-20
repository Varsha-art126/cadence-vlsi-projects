function metrics = compute_metrics(original, reconstructed)
%COMPUTE_METICS Calculate PSNR, SSIM, and related quality metrics.
%   metrics = compute_metrics(original, reconstructed)
%
%   original: original image (double, 0-255)
%   reconstructed: compressed/reconstructed image (double, 0-255)
%
%   Returns struct with fields: MSE, PSNR_dB, SSIM, MaxErr, MAE

    orig = double(original);
    recon = double(reconstructed);

    % Ensure same size
    [h, w] = size(orig);
    recon = recon(1:h, 1:w);

    % MSE
    diff = orig - recon;
    mse = mean(diff(:).^2);

    % PSNR
    if mse < 1e-12
        psnr = 100;  % Perfect reconstruction
    else
        maxVal = 255;
        psnr = 10 * log10(maxVal^2 / mse);
    end

    % SSIM (simplified - single-scale, luminance+contrast+structure)
    % Use a simpler implementation to avoid needing Image Processing Toolbox
    mu1 = mean(orig(:));
    mu2 = mean(recon(:));
    sigma1 = std(orig(:), 1);
    sigma2 = std(recon(:), 1);
    sigma12 = mean((orig(:) - mu1) .* (recon(:) - mu2));

    C1 = (0.01 * 255)^2;
    C2 = (0.03 * 255)^2;

    ssim_val = ((2*mu1*mu2 + C1) * (2*sigma12 + C2)) / ...
               ((mu1^2 + mu2^2 + C1) * (sigma1^2 + sigma2^2 + C2));

    metrics = struct('MSE', mse, 'PSNR_dB', psnr, 'SSIM', ssim_val, ...
                     'MaxErr', max(abs(diff(:))), 'MAE', mean(abs(diff(:))));
end