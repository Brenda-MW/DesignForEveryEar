function plotFilterBankResponses()
%plotFilterBankResponses  Show FIR and IIR cochlear filter bank responses.
%   Opens a single figure with a 2x1 tiled layout: the cascaded multirate
%   multistage FIR bank on top and the parallel single-rate SOS IIR bank
%   on the bottom, with all 8 channels overlaid on each. Wired to the
%   "Plot Filter Response" button on the CochlearImplantDemo canvas.
%
%   Fonts and line widths are enlarged for presentation to a live audience,
%   including visually impaired participants.

    % Presentation font sizes / line widths (tuned for a projector).
    FS_TICK  = 11;   % axis tick labels
    FS_LABEL = 12;   % axis labels
    FS_AXTTL = 13;   % per-axes titles
    FS_LEGEND= 12;   % legend entries (channel names)
    FS_SUPTL = 15;   % overall figure title
    LW_LINE  = 2.5;  % response curves

    % Colorblind-safe palette (Okabe-Ito), so the 8 channels stay
    % distinguishable for all types of color vision deficiency.
    CB_COLORS = [ ...
        0.00 0.00 0.00;   % Ch0 black
        0.90 0.60 0.00;   % Ch1 orange
        0.35 0.70 0.90;   % Ch2 sky blue
        0.00 0.60 0.50;   % Ch3 bluish green
        0.95 0.90 0.25;   % Ch4 yellow
        0.00 0.45 0.70;   % Ch5 blue
        0.80 0.40 0.00;   % Ch6 vermilion
        0.80 0.60 0.70];  % Ch7 reddish purple

    % Build both filter banks if they are not already in the base workspace.
    if evalin('base', "~exist('cochleardemo_h0','var') || ~exist('cochleardemo_f0','var')")
        evalin('base', 'dspcochlearfilterdesign;');
    end
    fs = evalin('base', 'fs');

    % Frequency grid (0 .. Nyquist).
    N    = 4096;
    fvec = linspace(0, fs/2, N);
    todb = @(H) 20*log10(max(abs(H), 1e-6));   % floor to keep the axis sane

    fig = findall(0, 'Type', 'figure', 'Tag', 'CIFilterBankResp');
    if isempty(fig)
        fig = figure('Tag', 'CIFilterBankResp');
    else
        clf(fig(1)); fig = fig(1);
    end
    figure(fig);
    set(fig, 'Name', 'Cochlear Filter Bank Frequency Responses', ...
             'NumberTitle', 'off', 'Color', 'w');

    t = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    % --- FIR bank (top tile) ---
    axFIR = nexttile(t);
    hold(axFIR, 'on');
    for k = 0:7
        h = evalin('base', sprintf('cochleardemo_h%d', k));
        H = freqz(h, fvec, fs);
        plot(axFIR, fvec, todb(H), 'LineWidth', LW_LINE, ...
            'Color', CB_COLORS(k+1,:));
    end
    hold(axFIR, 'off');
    grid(axFIR, 'on');
    axFIR.FontSize = FS_TICK;
    title(axFIR, 'Cascaded Multirate Multistage FIR Filter Bank', 'FontSize', FS_AXTTL);
    xlabel(axFIR, 'Frequency (Hz)', 'FontSize', FS_LABEL);
    ylabel(axFIR, 'Magnitude (dB)', 'FontSize', FS_LABEL);
    ylim(axFIR, [-80 5]); xlim(axFIR, [0 fs/2]);
    legend(axFIR, compose('Ch%d', (0:7).'), 'Location', 'eastoutside', 'FontSize', FS_LEGEND);

    % --- IIR bank (bottom tile) ---
    axIIR = nexttile(t);
    hold(axIIR, 'on');
    for k = 0:7
        f = evalin('base', sprintf('cochleardemo_f%d', k));
        H = freqz(f, fvec, fs);
        plot(axIIR, fvec, todb(H), 'LineWidth', LW_LINE, ...
            'Color', CB_COLORS(k+1,:));
    end
    hold(axIIR, 'off');
    grid(axIIR, 'on');
    axIIR.FontSize = FS_TICK;
    title(axIIR, 'Parallel Single-Rate SOS IIR Filter Bank', 'FontSize', FS_AXTTL);
    xlabel(axIIR, 'Frequency (Hz)', 'FontSize', FS_LABEL);
    ylabel(axIIR, 'Magnitude (dB)', 'FontSize', FS_LABEL);
    ylim(axIIR, [-80 5]); xlim(axIIR, [0 fs/2]);
    legend(axIIR, compose('Ch%d', (0:7).'), 'Location', 'eastoutside', 'FontSize', FS_LEGEND);

    title(t, 'Filter Bank Frequency Responses:  FIR vs IIR', ...
        'FontWeight', 'bold', 'FontSize', FS_SUPTL);
end
