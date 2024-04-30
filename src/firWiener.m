function xhat = firWiener(y, n, nfft, noverlap, fs)

    % computing Ryx for computing h
    len = length(y);
    Syy = pwelch(y, hann(nfft, "periodic"), noverlap, nfft, fs, "twosided");
    Snn = pwelch(n, hann(nfft, "periodic"), noverlap, nfft, fs, "twosided");
    Syx = Syy - Snn;
    ryx = ifft(Syx);
    rxy=flip(ryx);

    % computing T(Ryy) to compute h- Toeplitz matrix solver
    K=nfft; % I think this defines the order of the matrix
    [ryy, lags] = xcorr(y, y);
    lagZero = find(lags == 0);
    firstRow = ryy(lagZero:-1:(lagZero+1-K));
    firstCol = ryy(lagZero:(lagZero+K-1));  
    %Tryy = toeplitz(firstCol);
    Tryy = toeplitz(firstCol, firstRow);

    % computing h
    h = rxy\Tryy;
    %h = Tryy\rxy;
    xhat = fftfilt(h, y);
    %xhat=conv(y,h);
    xhat = xhat(1:len);

    % xhat at this point seems to be amplifying the noise exponentially
    % more than the signal, trying to use that to cancel out the noise in y
    if 1
        xhat=(xhat./max(xhat))*max(y)*0.1;
        
        %xhat=y+xhat;
    end
end