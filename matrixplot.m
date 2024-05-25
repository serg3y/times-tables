function matrixplot(x, y, V, varargin)
%Display values as grid with color and values shown as text.
%  gridplot(x, y, V)     - x labels, y labels, value array
%
%Example:
% matrixplot(["Joe" "Bob"], [2 7 5], randi(20, 3, 2))
%
%See also: heatmap

hold on, axis equal tight % Prepre axis
surf(0:numel(x), 0:numel(y), zeros(numel(y)+1, numel(x)+1), ... % Display matrix
    'CData', V, 'EdgeColor', 'w', 'LineWidth', 2, varargin{:}) % Set grid style
set(gca, 'XTick', 0.5:numel(x), 'XTickLabel', x) % Set x tick marks 
set(gca, 'YTick', 0.5:numel(y), 'YTickLabel', y) % Set y tick marks
set(gca, 'XAxisLocation', 'top', 'YDir','reverse') % Change axis location
[X, Y] = ndgrid(0.5:numel(x), 0.5:numel(y)); % Text locations
text(X(:), Y(:), V+"", 'HorizontalAlignment', 'center'); % Show text