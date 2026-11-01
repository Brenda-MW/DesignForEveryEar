function HearingLossApp
%HearingLossApp  Exercise 1: Hear Through Other Ears.
%
%   Pick a speech clip, play it, switch listening effects on and off, and
%   compare spectrograms. Run from this folder:
%
%       >> HearingLossApp
%
%   Effects come from simulateHearingLoss.m (based on File Exchange 79541).
%   Playback uses sound(), which also works in MATLAB Online.
%   Requires Audio Toolbox, Signal Processing Toolbox, DSP System Toolbox.

% ---- shared state ------------------------------------------------------
original  = [];          % clean speech excerpt (mono)
processed = [];          % last processed result; cleared when a setting changes
Fs        = [];          % sample rate (Hz)
specLim   = [-100 -30];  % spectrogram colour range (dB), set from the original

% Shipped clips and the stretch of each to play [start stop] in seconds.
% The counting excerpt is "five, six, seven": listen for the s-sounds.
clipFiles    = ["SpeechDFT-16-8-mono-5secs.wav", "Counting-16-44p1-mono-15secs.wav"];
clipLabels   = ["Speech sentence (8 kHz)",       "Counting 5-6-7 (44.1 kHz)"];
clipSegments = [0 6;                             6.9 11.8];
found        = arrayfun(@(f) exist(f, "file") == 2, clipFiles);
clipFiles    = clipFiles(found);
clipLabels   = clipLabels(found);
clipSegments = clipSegments(found, :);
if isempty(clipFiles)   % fallback so the app always runs
    clipFiles    = "mtlb";
    clipLabels   = "Built-in 'MATLAB' clip";
    clipSegments = [0 6];
end

% ---- UI ----------------------------------------------------------------
fig = uifigure("Name", "Hear Through Other Ears - EX1", ...
    "Position", [100 100 1000 600]);

outer = uigridlayout(fig, [1 2]);
outer.ColumnWidth = {340, '1x'};
outer.RowHeight   = {'1x'};

% left: controls
panel = uipanel(outer, "Title", "Controls", "FontWeight", "bold");
c = uigridlayout(panel, [8 1]);
c.RowHeight   = {'fit','fit','fit','fit','fit', 300, 'fit','fit'};
c.RowSpacing  = 8;

uilabel(c, "Text", "Hear Through Other Ears", ...
    "FontSize", 16, "FontWeight", "bold");

uilabel(c, "Text", "Hear how speech can sound to other listeners, " + ...
    "then see it in the spectrogram. Use headphones at a comfortable volume.", ...
    "WordWrap", "on");

clipRow = uigridlayout(c, [1 2]);
clipRow.ColumnWidth = {'fit', '1x'};
clipRow.RowHeight   = {'fit'};
clipRow.Padding     = [0 0 0 0];
uilabel(clipRow, "Text", "Speech clip");
ddClip = uidropdown(clipRow, "Items", clipLabels, "ItemsData", clipFiles, ...
    "Value", clipFiles(1), "ValueChangedFcn", @(~,~) loadClip());

lblStatus = uilabel(c, "Text", "Loading clip...", "WordWrap", "on", ...
    "FontAngle", "italic");

btnOrig = uibutton(c, "Text", "Play original", ...
    "ButtonPushedFcn", @(~,~) onPlayOriginal());

settings = uipanel(c, "Title", "Listening effects");
sg = uigridlayout(settings, [7 2]);
sg.ColumnWidth = {'fit', '1x'};
sg.RowHeight   = repmat({'fit'}, 1, 7);

uilabel(sg, "Text", "Attenuation");
ddAtt = uidropdown(sg, "Items", ["Bypass" "Mild" "Moderate"], "Value", "Mild");

uilabel(sg, "Text", "Smearing");
ddSmear = uidropdown(sg, "Items", ["Bypass" "Low" "High"], "Value", "Bypass");

uilabel(sg, "Text", "Loudness growth");
cbLoud = uicheckbox(sg, "Text", "", "Value", false);

uilabel(sg, "Text", "Temporal disruption");
cbTemp = uicheckbox(sg, "Text", "", "Value", false);

% noise is added before the effects: a noisy room through other ears
uilabel(sg, "Text", "Background noise");
cbNoise = uicheckbox(sg, "Text", "", "Value", false);

uilabel(sg, "Text", "Noise type");
ddNoise = uidropdown(sg, "Items", ["White" "Pink"], "Value", "White");

uilabel(sg, "Text", "SNR (dB)");
spNoise = uispinner(sg, "Limits", [-5 30], "Value", 10, "Step", 1);

% any setting change means the next play or compare recomputes
set([ddAtt ddSmear cbLoud cbTemp cbNoise ddNoise spNoise], ...
    "ValueChangedFcn", @(~,~) clearProcessed());

btnProc = uibutton(c, "Text", "Play through other ears", ...
    "ButtonPushedFcn", @(~,~) onPlayProcessed());

btnCompare = uibutton(c, "Text", "Compare spectrograms", ...
    "ButtonPushedFcn", @(~,~) onCompare());

% right: spectrograms
plots = uigridlayout(outer, [2 1]);
plots.RowSpacing = 10;
axOrig = uiaxes(plots);
title(axOrig, "Original");
axProc = uiaxes(plots);
title(axProc, "Through other ears");

loadClip();

% ---- callbacks ---------------------------------------------------------
    function loadClip()
        file = string(ddClip.Value);
        if file == "mtlb"
            s = load("mtlb");
            x = s.mtlb; Fs = s.Fs;
        else
            [x, Fs] = audioread(file);
            x = x(:, 1);                           % mono
        end
        sel = clipFiles == file;
        seg = clipSegments(sel, :);
        original = x(round(seg(1)*Fs) + 1 : min(size(x,1), round(seg(2)*Fs)));
        clearProcessed();

        % Both plots share the original's colour range (80 dB below its
        % peak), so any loss shows up as darker.
        P = specPower(original);
        top = ceil(max(P(:)) / 10) * 10;
        specLim = [top - 80, top];

        lblStatus.Text = sprintf("Loaded: %s, %.1f s", ...
            clipLabels(sel), numel(original)/Fs);
        plotSpec(axOrig, original, "Original");
        cla(axProc);
        title(axProc, "Through other ears");
    end

    function onPlayOriginal()
        clear sound                                % stop any playback first
        sound(original, Fs);
    end

    function onPlayProcessed()
        busy(true);
        try
            p = getProcessed();
            clear sound
            sound(p, Fs);
            busy(false, settingsSummary());
        catch err
            busy(false, "Error: " + string(err.message));
        end
    end

    function onCompare()
        busy(true);
        try
            plotSpec(axProc, getProcessed(), "Through other ears", settingsSummary());
            busy(false, settingsSummary());
        catch err
            busy(false, "Error: " + string(err.message));
        end
    end

    function clearProcessed()
        processed = [];
    end

% ---- helpers -----------------------------------------------------------
    function p = getProcessed()
        % Reuse the last result until a setting changes, so Compare shows
        % exactly what you just heard (smearing, timing and noise are random).
        if isempty(processed)
            in = original;
            if cbNoise.Value
                in = addBackgroundNoise(in, string(ddNoise.Value), spNoise.Value);
            end
            p = simulateHearingLoss(in, Fs, ...
                Attenuation        = string(ddAtt.Value), ...
                Smearing           = string(ddSmear.Value), ...
                LoudnessGrowth     = cbLoud.Value, ...
                TemporalDisruption = cbTemp.Value);
            processed = matchLevel(p, original);
        end
        p = processed;
    end

    function y = matchLevel(y, ref)
        % Same loudness (RMS) as the original, so you compare clarity, not
        % volume. Peaks are capped at 1 so playback never clips.
        y = y * rms(ref) / max(rms(y), eps);
        y = y / max(1, max(abs(y)));
    end

    function y = addBackgroundNoise(x, noiseType, snrDB)
        % white or pink noise at the target SNR (dB)
        if noiseType == "Pink"
            n = pinknoise(numel(x));
        else
            n = randn(numel(x), 1);
        end
        y = x + n * rms(x) / (rms(n) * 10^(snrDB/20));
    end

    function [P, F, T] = specPower(sig)
        [S, F, T] = spectrogram(sig, hamming(256), 128, 256, Fs);
        P = 10*log10(abs(S).^2 + eps);
    end

    function plotSpec(ax, sig, ttl, subttl)
        [P, F, T] = specPower(sig);
        imagesc(ax, T, F/1000, P);
        ax.YDir = "normal";
        ylim(ax, [0 Fs/2/1000]);                   % kHz
        clim(ax, specLim);
        xlabel(ax, "Time (s)");
        ylabel(ax, "Frequency (kHz)");
        if nargin < 4
            title(ax, ttl);
        else
            title(ax, ttl, subttl);
        end
    end

    function s = settingsSummary()
        s = "Attenuation " + ddAtt.Value + ", smearing " + ddSmear.Value;
        if cbLoud.Value; s = s + ", loudness growth"; end
        if cbTemp.Value; s = s + ", temporal disruption"; end
        if cbNoise.Value
            s = s + ", " + ddNoise.Value + " noise at " + spNoise.Value + " dB SNR";
        end
    end

    function busy(isBusy, msg)
        set([btnOrig btnProc btnCompare], "Enable", ~isBusy);
        if isBusy
            msg = "Applying listening effects...";
        end
        lblStatus.Text = msg;
        drawnow;
    end
end
