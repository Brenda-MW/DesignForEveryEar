function plotFilterBankResponses()
%plotFilterBankResponses  Plot the response of the selected cochlear filter bank.
%   Reads the filter_type selected in the "Filter bank signal processing"
%   block and plots that bank's frequency response, all 8 channels overlaid.
%   Wired to the "Plot Filter Response" button on the CochlearImplantModel canvas.

    MODEL = 'CochlearImplantModel';
    FB    = [MODEL '/Filter bank signal processing'];

    % Font sizes / line widths enlarged for projector display.
    FS_TICK  = 11;
    FS_LABEL = 12;
    FS_AXTTL = 13;
    FS_LEGEND= 12;
    LW_LINE  = 2.5;

    % Okabe-Ito colorblind-safe palette for the 8 channels.
    CB_COLORS = [ ...
        0.00 0.00 0.00;   % Ch0
        0.90 0.60 0.00;   % Ch1
        0.35 0.70 0.90;   % Ch2
        0.00 0.60 0.50;   % Ch3
        0.95 0.90 0.25;   % Ch4
        0.00 0.45 0.70;   % Ch5
        0.80 0.40 0.00;   % Ch6
        0.80 0.60 0.70];  % Ch7

    % Build the filter banks if they are not already in the base workspace.
    if evalin('base', "~exist('cochleardemo_h0','var') || ~exist('cochleardemo_f0','var')")
        evalin('base', 'dspcochlearfilterdesign;');
    end
    fs = evalin('base', 'fs');

    % Pick the bank that is currently selected in the model.
    if bdIsLoaded(MODEL) && getSimulinkBlockHandle(FB) ~= -1
        filterType = get_param(FB, 'filter_type');
    else
        filterType = 'Cascade multirate multi-stage FIR';
    end

    switch filterType
        case 'Parallel single-rate SOS IIR'
            prefix  = 'cochleardemo_f';
            axTitle = 'Parallel Single-Rate SOS IIR Filter Bank';
        otherwise
            prefix  = 'cochleardemo_h';
            axTitle = 'Cascaded Multirate Multistage FIR Filter Bank';
    end

    N    = 4096;
    fvec = linspace(0, fs/2, N);
    todb = @(H) 20*log10(max(abs(H), 1e-6));

    fig = findall(0, 'Type', 'figure', 'Tag', 'CIFilterBankResp');
    if isempty(fig)
        fig = figure('Tag', 'CIFilterBankResp');
    else
        clf(fig(1)); fig = fig(1);
    end
    figure(fig);
    fPosition = fig.Position;
    
    set(fig, 'Name', 'Cochlear Filter Bank Frequency Response', ...
             'NumberTitle', 'off', 'Color', 'w','Position',[fPosition(1) fPosition(2),...
             fPosition(4)*4 fPosition(4)]);

    ax = axes(fig);
    hold(ax, 'on');
    for k = 0:7
        coeffs = evalin('base', sprintf('%s%d', prefix, k));
        H = freqz(coeffs, fvec, fs);
        plot(ax, fvec, todb(H), 'LineWidth', LW_LINE, 'Color', CB_COLORS(k+1,:));
    end
    hold(ax, 'off');
    grid(ax, 'on');
    ax.FontSize = FS_TICK;
    title(ax, axTitle, 'FontSize', FS_AXTTL);
    xlabel(ax, 'Frequency (Hz)', 'FontSize', FS_LABEL);
    ylabel(ax, 'Magnitude (dB)', 'FontSize', FS_LABEL);
    ylim(ax, [-80 5]); xlim(ax, [0 fs/2]);
    legend(ax, compose('Ch%d', (0:7).'), 'Location', 'eastoutside', 'FontSize', FS_LEGEND);
end
