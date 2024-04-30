function xhat = denoise(y, fs, noiseLengthSec, nfft, noverlap)
    if nargin < 3
        noiseLengthSec = 3.0;
    end

    if nargin < 4
        nfft = 4096;
    end

    if nargin < 5
        noverlap = nfft/2;
    end

    % noiseLengthSampl = floor(noiseLengthSec * fs);
    y = y(:); 
    % noise_profile = y(1:noiseLengthSampl);
    % xhat = firWiener(y, noise_profile, nfft, noverlap, fs);
    xhat = removeCorrNoise(y, fs, 0.8, noiseLengthSec, noverlap, nfft);
end