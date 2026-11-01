function [audioOut, Fs] = simulateHearingLoss(audioIn, Fs, options)
%simulateHearingLoss Apply perceptual hearing-loss effects to a speech signal.
%
%   [audioOut, Fs] = simulateHearingLoss(audioIn, Fs, Name=Value)
%   [audioOut, Fs] = simulateHearingLoss(fileName, Name=Value)
%
%   Works on one channel: stereo input is mixed to mono, and audioOut is a
%   column vector the same length as the input.
%
%   Effects (all off by default):
%     Attenuation        "Bypass" | "Mild" | "Moderate"  high frequencies fade
%     Smearing           "Bypass" | "Low"  | "High"      frequency detail blurs
%     LoudnessGrowth     true | false   loud sounds grow too loud too fast
%     TemporalDisruption true | false   timing detail is jittered
%
%   How it works: a gammatone filter bank splits the speech into 32 bands,
%   like the cochlea. Timing jitter is applied to the 11 lowest bands, and
%   smearing, attenuation and loudness growth to the 21 upper bands. The
%   two parts are then added back together.
%
%   Based on the Hearing Loss Simulation plugin by Angeliki Mourgela,
%   Queen Mary University of London & BBC R&D (File Exchange 79541).
%
%   Example:
%     [y, fs] = simulateHearingLoss("Counting-16-44p1-mono-15secs.wav", ...
%               Attenuation="Moderate");

arguments
    audioIn
    Fs {mustBeNumeric} = []
    options.Attenuation (1,1) string {mustBeMember(options.Attenuation, ...
        ["Bypass","Mild","Moderate"])} = "Bypass"
    options.Smearing (1,1) string {mustBeMember(options.Smearing, ...
        ["Bypass","Low","High"])} = "Bypass"
    options.LoudnessGrowth (1,1) logical = false
    options.TemporalDisruption (1,1) logical = false
end

if ischar(audioIn) || (isstring(audioIn) && isscalar(audioIn))
    [audioIn, Fs] = audioread(audioIn);
elseif isempty(Fs)
    error("simulateHearingLoss:missingFs", ...
        "Provide the sample rate Fs together with the audio signal.");
end
x = mean(audioIn, 2);                              % mono

% --- Split into cochlea-like bands ---
numBands    = 32;
numLowBands = 11;
maxFreq  = min(16000, floor(Fs/2) - 1);
filtBank = gammatoneFilterBank([20 maxFreq], numBands, Fs);
bands = filtBank(x);
low   = sum(bands(:, 1:numLowBands), 2);
high  = bands(:, numLowBands+1:end);

% --- Upper bands: smearing, attenuation, loudness growth ---
high = smearBands(high, Fs, options.Smearing);    % also sums the bands
high = attenuateHighs(high, Fs, options.Attenuation);
if options.LoudnessGrowth
    % threshold -50 dB, attack 0.3 s, release 0.2 s
    high = rapidGrowth(high, Fs, -50, 0.3, 0.2);
end

% --- Lower bands: timing ---
if options.TemporalDisruption
    low = jitterPhase(low);
end

% The phase jitter can leave a tiny imaginary part; keep the audio real.
audioOut = real(high + low);
end

function y = smearBands(bands, Fs, level)
% Blur frequency detail: multiply each band by slowly varying random noise
% (lowpass at 100 Hz for "Low", 200 Hz for "High"), then sum the bands.
if level == "Bypass"
    y = sum(bands, 2);
    return
end
cutoff = 100;
if level == "High"
    cutoff = 200;
end
lowpass = dsp.VariableBandwidthIIRFilter('FilterType', 'Lowpass', ...
    'FilterOrder', 10, 'PassbandFrequency', cutoff, 'SampleRate', Fs);
noise = 0.5 * lowpass(randn(size(bands)));
y = sum(20 * bands .* noise, 2);                   % gain of 20 as in the plugin
end

function y = attenuateHighs(x, Fs, level)
% Turn down the higher frequencies with a multiband EQ (gains in dB).
if level == "Bypass"
    y = x;
    return
end
freqs = [250 500 1000 2000 4000 6000 8000];
if level == "Mild"
    gains = [0 0 -10 -15 -15 -20 -20];
else
    gains = [0 0 -15 -20 -20 -25 -30];
end

% Keep only the bands below Nyquist so any sample rate works (lower rates
% show less high-frequency loss, as there is less content to remove).
keep  = freqs < Fs/2;
freqs = freqs(keep);
args = {'NumEQBands', numel(freqs), 'Frequencies', freqs, ...
    'QualityFactors', 2.3 * ones(1, numel(freqs)), ...
    'PeakGains', gains(keep), 'SampleRate', Fs};

% High-shelf and lowpass guards, only where they fit below Nyquist.
cutoff = min(8000, floor(Fs/2) - 1);
if cutoff > max(freqs)
    args = [args, {'HasHighShelfFilter', true, 'HighShelfCutoff', cutoff, ...
        'HasLowpassFilter', true, 'LowpassCutoff', cutoff, 'LowpassSlope', 48}];
end

eq = multibandParametricEQ(args{:});
y  = eq(x);
end

function y = jitterPhase(x)
% Blur timing: every 16 samples, take a short-time spectrum, shift the
% phase of each bin by a random 0 to 90 degrees, and resynthesize.
winLength = 512;
hop       = 16;
win       = hamming(winLength, 'periodic');
toSpec    = dsp.STFT(win, winLength - hop, winLength);
toSignal  = dsp.ISTFT(win, winLength - hop, 1, 0);

N = numel(x);
x = [x; zeros(mod(-N, hop), 1)];                   % whole number of hops
y = zeros(size(x));
for k = 1:hop:numel(x)
    idx = k:k+hop-1;
    X = toSpec(x(idx));
    y(idx) = toSignal(X .* exp(1i * pi/2 * rand(size(X))));
end
y = y(1:N);
end
