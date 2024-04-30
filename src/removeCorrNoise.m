function xhat = removeCorrNoise(y, fs, thresh,  noiseLengthSec, noverlap, nfft)

% y= full input signal
% fs= sample rate
% thresh= thresholding for normalized cross correlation values
% noiseLengthSec=length of the noise in seconds
% noverlap= window overlap for FIR wiener filter
% nfft= length of the fft and window for it for FIR wiener filter

if nargin<6
    nfft = 2048;
    if nargin<5
        noverlap = nfft/2;
        if nargin<4
            noiseLengthSec = 3.0;
            if nargin<3
                thresh=0.8;
            end
        end
    end
end

noiseLengthSample = noiseLengthSec * fs;

% isolating the signal+noise part of y for cross correlation
end_ind=floor(fs*noiseLengthSec); % finding the noise length in samples(floor is incase the sample count isn't an integer)
noise=y(1:end_ind); % isolating the just noise part
% y=y(end_ind:length(y)); % isolating the signal+noise part

[autocorr, lags] = xcorr(noise, noise); % comuputing the unnormalized crosscorrelation to find the max possible correlation value
corr_max=max(autocorr); % finding the theoretical  maximum possible autocorrelation value

[crosscorr, lags] = xcorr(y, noise); % compute cross corr
crosscorr=crosscorr./corr_max; % normalizing to the theoretical max value
[peaks, inds] = findpeaks(crosscorr, "MinPeakHeight", thresh, MinPeakDistance=noiseLengthSample); % finding the peaks above a defined threshold of the normalized crosscorr

% converting the autocorrelation lags to time indices in y
time_inds = zeros(1, length(inds)); 
for i = 1:length(inds) 
    time_inds(i) = lags(inds(i)); 
end
time_inds = time_inds + 1;
time_inds = time_inds(time_inds > 0);

if ~isempty(time_inds) % if some crosscorrelation is found
    diff_locs = diff(inds);
    % T = round(mean(diff_locs) / fs);
    % num_segments = floor(length(y) / (T * fs));
    % audio_segments = reshape(y(1 : num_segments * T * fs), T * fs, num_segments);
    % noise_overlap = mean(audio_segments, 2);
    % noise = [noise; noise_overlap];
    if max(diff_locs) > noiseLengthSample
        noise_rest = zeros(max(diff_locs) - length(noise), 1);
        counter = 0;
        for i = 1:length(time_inds) - 1
            % add [x + 3fs, x + 5fs) to noise [3fs, 5fs)
            x = time_inds(i);
            next_x = min(time_inds(i + 1), length(y));
            noise_rest(1:next_x - x - noiseLengthSample) = noise_rest(1:next_x - x - noiseLengthSample) + y(x + noiseLengthSample:next_x - 1);
            counter = counter + 1;
        end
        noise_rest = noise_rest / counter;
        noise = [noise; noise_rest];
    end
    % audiowrite("estim_noise.wav", noise, fs);
    for x=time_inds
        if (x+length(noise)-1)<length(y)
            y(x:(x+length(noise)-1))=y(x:(x+length(noise)-1))-noise;
        else
            diff_len=(x+length(noise))-length(y);
            new_noise=noise(1:(length(noise)-diff_len));
            y(x:(x+length(noise)-diff_len-1))=y(x:(x+length(noise)-diff_len-1))-new_noise;
        end
    end

    % removing the noise at the beginning manually by replacing with
    % zeros
    % silence=zeros(end_ind-1, 1); % making a vector of zeros 
    % xhat=[silence; y];
    xhat = y;

else % if no cross correlation values above the threshold are found, system will use FIR wiener filter as fallback
    % y=[noise; y];
    xhat = firWiener(y, noise, nfft, noverlap, fs);
end
