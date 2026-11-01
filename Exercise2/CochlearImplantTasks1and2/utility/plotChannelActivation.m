function plotChannelActivation(channels, fs)
%plotChannelActivation  Show the 8 stimulation channels in a 4x2 grid.
%   plotChannelActivation(CHANNELS, FS) plots CHANNELS (a [time x 8] matrix
%   ordered Ch0..Ch7) as a 4-row by 2-column grid of subplots sharing a common
%   time axis. Ch0..Ch3 run down the left column, Ch4..Ch7 down the right. With
%   a chirp input the energy appears in Ch0 (lowest frequency) first and Ch7
%   (highest) last, so the activation marches down each column over time.

    % Font sizes / line widths enlarged for projector display.
    FS_TICK  = 10;
    FS_LABEL = 12;
    FS_TITLE = 14;
    LW_LINE  = 1.5;

    % Okabe-Ito colorblind-safe palette, one color per channel.
    CB_COLORS = [ ...
        0.00 0.00 0.00;   % Ch0
        0.90 0.60 0.00;   % Ch1
        0.35 0.70 0.90;   % Ch2
        0.00 0.60 0.50;   % Ch3
        0.95 0.90 0.25;   % Ch4
        0.00 0.45 0.70;   % Ch5
        0.80 0.40 0.00;   % Ch6
        0.80 0.60 0.70];  % Ch7

    % Normalize to [time x 8] regardless of how the signal was logged.
    if size(channels, 1) == 8 && size(channels, 2) ~= 8
        channels = channels.';
    end

    nCh  = size(channels, 2);
    t    = (0:size(channels, 1) - 1) / fs;
    ymax = max(abs(channels(:)));

    nCols = 2;
    nRows = ceil(nCh / nCols);

    fig = findall(0, 'Type', 'figure', 'Tag', 'CIChannelActivation');
    if isempty(fig)
        fig = figure('Tag', 'CIChannelActivation');
    else
        clf(fig(1)); fig = fig(1);
    end
    set(fig, 'Name', 'Channel activation over time', ...
             'NumberTitle', 'off', 'Color', 'w');

    tl = tiledlayout(fig, nRows, nCols, 'TileSpacing', 'tight', 'Padding', 'compact');
    for k = 1:nCh
        % Fill column-major: Ch0..Ch3 down the left column, Ch4..Ch7 the right.
        col  = ceil(k / nRows);
        row  = k - (col - 1) * nRows;
        tile = (row - 1) * nCols + col;

        ax = nexttile(tl, tile);
        plot(ax, t, channels(:, k), 'LineWidth', LW_LINE, 'Color', CB_COLORS(k,:));
        grid(ax, 'on');
        ax.FontSize = FS_TICK;
        ylabel(ax, sprintf('Ch%d', k-1), 'FontSize', FS_LABEL, ...
            'Rotation', 0, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
        ylim(ax, [-ymax ymax]);
        if row < nRows
            ax.XTickLabel = [];
        else
            xlabel(ax, 'Time (s)', 'FontSize', FS_LABEL);
        end
    end
    title(tl, 'Chirp sweep across the eight channels (low to high frequency)', ...
        'FontSize', FS_TITLE);
end
