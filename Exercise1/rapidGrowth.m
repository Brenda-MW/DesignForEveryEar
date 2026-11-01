function [y] = rapidGrowth(x, Fs, T, attackTime, releaseTime)
%rapidGrowth Simulate abnormal loudness recruitment above a threshold.
%
%   Based on open-source compressor code from "Hack Audio: An Introduction
%   to Computer Programming and Digital Signal Processing in MATLAB"
%   (c) 2019 Taylor & Francis.
%   Original plugin by Angeliki Mourgela (File Exchange 79541).
%
%   Levels between the threshold T (dB) and -20 dB are expanded, so they
%   grow louder faster than normal; other levels pass unchanged. Gain
%   changes are smoothed with the attack and release times (seconds).

kneeDB = -20;     % expansion stops here
ratio  = 0.6;     % below 1 means expansion

alphaA = exp(-log(9) / (Fs * attackTime));
alphaR = exp(-log(9) / (Fs * releaseTime));

y = zeros(size(x));
gainSmooth = 0;                                    % smoothed gain (dB)
for n = 1:numel(x)
    x_dB = max(20 * log10(abs(x(n))), -144);
    if x_dB > T && x_dB < kneeDB
        gain = T + (x_dB - T) / ratio - x_dB;
    else
        gain = 0;
    end

    if gain < gainSmooth
        alpha = alphaA;
    else
        alpha = alphaR;
    end
    gainSmooth = (1 - alpha) * gain + alpha * gainSmooth;
    y(n) = 10^(gainSmooth / 20) * x(n);
end
end
