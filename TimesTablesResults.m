function TimesTablesResults(N1, N2, OP, max_time, max_hist, gamma, T)
% Defaults
if nargin<1 || isempty(N1),       N1 = 2:11; end
if nargin<2 || isempty(N2),       N2 = 2:11; end
if nargin<3 || isempty(OP),       OP = ["times" "divide"]; end
if nargin<4 || isempty(max_time), max_time = 20; end % Maximum time per question
if nargin<5 || isempty(max_hist), max_hist = 2; end % Look at only this many previous results
if nargin<6 || isempty(gamma),    gamma = 1; end
if nargin<7 || isempty(T),        T = read_logs(dir('log/*.log')); end

% Prepare figure
isNewPlot = isempty(get(gcf, 'UserData'));
isNewPlot = 1;
if isNewPlot
    set(clf(gcf), 'WindowStyle', 'docked') % New figure
else
    ax = get(gcf, 'UserData'); % Use old figure
end
figure(gcf)

% Step through operators
for k = 1:numel(OP)
    [Time, Count] = calc_stats(T, OP(k), N1, N2, max_time, max_hist, gamma);
    
    % Plot stats
    if isNewPlot
        ax(1,k) = axes('Position', [(k-1)/numel(OP)+0.05 0.70 0.45 0.25]);
        ax(2,k) = axes('Position', [(k-1)/numel(OP)+0.05 0.02 0.45 0.5]);
    else
        cla(ax(2,k))
    end

    title(ax(1,k), sprintf('%s (%.2f sec)', OP(k), mean(Time(Time>0))))
    matrixplot(ax(2,k), N1, N2, round(Time), Count/max_hist)
    
    if isNewPlot
        ylabel(ax(2,k), 'Time (sec)')
        col = interp1(0:1, [0 1 0; 1 0 0], linspace(0, 1, 64)).^(1/2.4);
        colormap(ax(2,k), [0.8 0.8 0.8; col])
        clim(ax(2,k), [0 max_time])
    end
end

if isNewPlot
    set(gcf, 'UserData', ax)
end
end

function matrixplot(ax, X, Y, Value, Alpha)
% Display a matrix as a grid of cells, with text, color and alpha.
% eg, matrixplot(["Joe" "Bob"], [2 7 5], randi(20, 3, 2))
if nargin>4 && ~isempty(Alpha)
    arg = {'FaceAlpha', 'flat', 'AlphaData', Alpha', 'AlphaDataMapping', 'none'};
else
    arg = {};
end
hold(ax, 'on')
axis(ax, 'equal', 'tight') % Prepre axis
surf(ax, 0:numel(X), 0:numel(Y), zeros(numel(Y) + 1, numel(X) + 1), ... % Display matrix
    'CData', Value', 'FaceColor', 'flat','EdgeColor', 'w', 'LineWidth', 2, arg{:}) % Set grid style
set(ax, 'XTick', 0.5:numel(X), 'XTickLabel', X) % Set x tick marks
set(ax, 'YTick', 0.5:numel(Y), 'YTickLabel', Y) % Set y tick marks
set(ax, 'XAxisLocation', 'top', 'YDir', 'reverse') % Change axis location
[X, Y] = ndgrid(0.5:numel(X), 0.5:numel(Y)); % Text locations
text(ax, X(:), Y(:), string(Value), 'HorizontalAlignment', 'center', 'Clipping', 'on'); % Show text
end