function TimesTables

% Figure
close(findobj(0, 'Name', 'Times Tables')) % For convenience only
fig = figure(...
    Position = get(0).ScreenSize([3 4 3 4]).*[0.2 0.1 0.6 0.8], ...
    Name = 'Times Tables', NumberTitle = 'off', ...
    ToolBar = 'none', MenuBar = 'none', ...
    DefaultUipanelUnits = 'normalized', ...
    DefaultUicontrolUnits = 'normalized', ...
    DefaultTextboxshapeUnits = 'normalized', ...
    DefaultUicontrolFontSize = 14, ...
    DefaultTextboxshapeFontSize = 14, ...
    DefaultUicontrolFontWeight = 'bold', ...
    DefaultTextboxshapeEdgeColor = 'n', ...
    DefaultTextboxshapeInterpreter = 'n', ...
    DefaultTextboxshapeVerticalAlignment = 'middle', ...
    DefaultTextboxshapeHorizontalAlignment = 'cen');

% Setting
N1 = 2:11;   % Numbers
N2 = 2:11;   % Numbers
OP = ["times" "divide"]; % Opperators
dynamic = true;
p1 = uipanel(fig, 'OuterPosition', [0 0.75 0.5 0.25], 'BorderType', 'beveledin');
annotation(p1, 'textbox', 'Position', [0.0 0.7 0.25 0.2], 'String', 'Numbers');
annotation(p1, 'textbox', 'Position', [0.0 0.4 0.25 0.2], 'String', 'Numbers');
annotation(p1, 'textbox', 'Position', [0.0 0.1 0.25 0.2], 'String', 'Operators');
N1h = uicontrol (p1, 'Style', 'edit', 'Position', [0.25 0.7 0.7 0.2], 'String', strjoin(string(N1)));
N2h = uicontrol (p1, 'Style', 'edit', 'Position', [0.25 0.4 0.7 0.2], 'String', strjoin(string(N2)));
O1h = uicontrol (p1, 'Style', 'chec', 'Position', [0.35 0.1 0.3 0.2], 'String', 'Times', 'Value', 1);
O2h = uicontrol (p1, 'Style', 'chec', 'Position', [0.65 0.1 0.3 0.2], 'String', 'Divide', 'Value', 1);

% Assessment
p2 = uipanel(fig, 'OuterPosition', [0.5 0.75 0.5 0.25], 'BorderType', 'beveledin');
annotation(p2, 'textbox', 'Position', [0.0 0.7 0.3 0.2], 'String', 'Max Time');
annotation(p2, 'textbox', 'Position', [0.0 0.4 0.3 0.2], 'String', 'Max History');
annotation(p2, 'textbox', 'Position', [0.0 0.1 0.3 0.2], 'String', 'Gamma');
max_time_h = uicontrol(p2, 'Style', 'edit', 'Position', [0.25 0.7 0.7 0.2], 'String', 20);
max_hist_h = uicontrol(p2, 'Style', 'edit', 'Position', [0.25 0.4 0.7 0.2], 'String', 5);
gamma_h    = uicontrol(p2, 'Style', 'edit', 'Position', [0.25 0.1 0.7 0.2], 'String', 1);

% Results
p3 = uipanel(fig, 'OuterPosition', [0.5 0.0 0.5 0.75], 'BorderType', 'beveledin');

num_questions = 50;
max_time = 20; % Maximum time per question
max_hist = 5;  % Look at only this many previous results
gamma = 1;

T = read_logs(dir('log/*.log'));
plotResults(p3, N1, N2, OP, max_time, max_hist, gamma, T)

% Answer box
hAns = uicontrol('Style', 'edit', 'Units', 'normalized', 'Position', [0.05 0.4 0.4 0.1], 'FontSize', 14, 'HorizontalAlignment', 'right');

% Number pad
hPanel = uipanel(fig, 'Units', 'normalized', 'Position', [0.05 0.05 0.4 0.3]);
t = {'7' '8' '9'; '4' '5' '6'; '1' '2' '3'; '<' '0' 'Enter'};
for r = 1:4
    for c = 1:3
        if ~isempty(t{r, c})
            h(r, c) = uicontrol(hPanel, 'Style', 'pushbutton', 'String', t{r, c}, ...
                'Units', 'normalized', 'Position', [c/3-1/3 1-r/4 1/3 1/4], ...
                'Callback', @(obj, ~)buttonCallback(obj.String, hAns));
        end
    end
end



% Generate nubers
if dynamic
    % Read previous results
    num_questions = 50;
    max_time = 20; % Maximum time per question
    max_hist = 5;  % Look at only this many previous results
    gamma = 1;
    T = read_logs(dir('log/*.log'));
    for k = numel(OP) : -1 : 1
        [~, ~, p(:,:,k)] = calc_stats(T, OP(k),  N1, N2, max_time, max_hist, gamma);
    end

    % Pick questions
    [x, y, z] = ndgrid(N1, N2, OP);
    n = rand(1, num_questions) * sum(p(:));
    [~, i] = max(n < cumsum(p(:)), [], 1);
    V1 = x(i);
    V2 = y(i);
    V3 = z(i);

else
    [V1, V2, V3] = ndgrid(N1, N2, OP);
    ind = randperm(numel(V1), numel(V1));
    V1 = V1(ind);
    V2 = V2(ind);
    V3 = V3(ind);
end

% Output log file
if ~isfolder('log')
    mkdir('log')
end
file = sprintf('log/%s_[%s]_[%s]_%s_%g.log', ...
    string(datetime('now', 'Format', 'yyyyMMdd_HHmm')), ...
    strjoin(string(N1)), strjoin(string(N2)), strjoin(OP), numel(V1));
pause(1)

% Loop through number of questions
for k = 1 : numel(V1)

    % Generate question
    num1 = V1(k);
    num2 = V2(k);
    opp  = V3(k);
    switch opp
        case 'times'
            fprintf('%3d × %2d = ', num1, num2); % Print question
            speak_question(num1, opp, num2); % Say question
            answer = num1 * num2;
        case 'divide'
            fprintf('%3d ÷ %2d = ', num1 * num2, num1); % Print question
            speak_question(num1 * num2, opp, num1); % Say question
            answer = num2;
            num1 = num1 * num2;
        case 'square'
            fprintf('%3d^2 = ', num1); % Print question
            speak_question(num1, opp, 'none'); % Say question
            answer = num1 * num1;
            num2 = NaN;
        case 'sqrt'
            fprintf('sqrt(%3d) = ', num1^2); % Print question
            speak_question('none', opp, num1^2); % Say question
            answer = num1;
            num2 = NaN;
    end

    % Wait for user
    tic % Measure time
    reply = input('', 's');
    fprintf('\b%*s', max(5 - numel(reply), 0), ''); % Pad reply with upto 5 spaces
    reply = str2double(reply); % Convert to number
    t = toc;

    % Check answer
    if reply == answer
        sound(wavread('right')*4, 8000)
        fprintf(   ' %3s ', 'OK');
    else
        sound(wavread('wrong')*5, 4000)
        fprintf(2, ' %3d ', answer); % Show correct answer in red
    end
    % fprintf(' %4.1fs\n', t); % Show time taken
    fprintf('\n'); 
    pause(1)

    % Log to file
    log(file, '%3d, %3d, %6s, %3d, %3d, %1d, %4.1f', num1, num2, opp, answer, reply, reply==answer, toc);

    % TimesTablesResults(N1, N2, OP, max_time, max_hist, gamma, T)
end
end

function speak_question(n1, operator, n2)
sound([num2wav(n1); wavread(operator)*0.6; num2wav(n2)], 8000);
end

function w = num2wav(num)
if     num > 0 && num<100,     w = wavread(num);
elseif num < 0,                w = [wavread("minus"); num2wav(-num)];
elseif num > 100 && num < 199, w = [num2wav(100); num2wav(num - 100)];
elseif num > 200 && num < 299, w = [num2wav(100); num2wav(num - 200)];
elseif num > 300 && num < 399, w = [num2wav(100); num2wav(num - 300)];
elseif num > 400 && num < 499, w = [num2wav(100); num2wav(num - 400)];
elseif num > 500 && num < 599, w = [num2wav(100); num2wav(num - 500)];
elseif num > 600 && num < 699, w = [num2wav(100); num2wav(num - 600)];
elseif num > 700 && num < 799, w = [num2wav(100); num2wav(num - 700)];
elseif num > 800 && num < 899, w = [num2wav(100); num2wav(num - 800)];
elseif num > 900 && num < 999, w = [num2wav(100); num2wav(num - 900)];
else,  error('not yet supported')
end
end

function y = wavread(name)
[y, f] = audioread("wav/" + name + ".wav"); % Read file
y = y(1 : round(f/8000) : end, 1); % Use ~8000 bits/sec mono (hack)
i1 = find(y > 0.01, 1, 'first'); % Trim silence from start
i2 = find(y > 0.01, 1, 'last') + 0.2*8000; % Append 0.2 sec silence to end
y = y(i1 : min(i2, end)); % Output
end

function log(file, varargin)
fid = fopen(file, 'a');
str = sprintf(varargin{:});
fprintf(fid, '%s\n', str);
fclose(fid);
end

function buttonCallback(str, h)
if isfinite(str2double(str))
    h.String = [h.String str];
elseif str == "<"
    h.String = h.String(1:end-1);
else
    disp Enter
end
end

function plotResults(h, N1, N2, OP, max_time, max_count, gamma, T)
% Step through operators
for k = 1:numel(OP)
    [Time, Count] = calc_stats(T, OP(k), N1, N2, max_time, max_count, gamma);
    
    % Plot stats
    axes(h, 'Position', [0.05 (k-1)/numel(OP)+0.01 0.9 0.4]);
    title(sprintf('%s\navg = %.2f sec', OP(k), mean(Time(Time>0))))
    plotMatrix(N1, N2, Count, round(Time), Count/max_count)
    
    col = interp1(0:1, [0 1 0; 1 0 0], linspace(0, 1, 64)).^(1/2.4);
    colormap([0.8 0.8 0.8; col])
    clim([0 max_time])
    colorbar
end
end

function plotMatrix(X, Y, Text, Color, Alpha)
% Display a matrix as a grid of cells, with text, color and alpha.
hold on, axis equal tight % Prepre axis
surf(0:numel(X), 0:numel(Y), zeros(numel(Y) + 1, numel(X) + 1), ... % Display matrix
    'CData', Color', 'FaceColor', 'flat','EdgeColor', 'w', 'LineWidth', 2,... % Color
    'FaceAlpha', 'flat', 'AlphaData', Alpha', 'AlphaDataMapping', 'none') % Alpha
set(gca, 'XTick', 0.5:numel(X), 'XTickLabel', X) % Set x tick marks
set(gca, 'YTick', 0.5:numel(Y), 'YTickLabel', Y) % Set y tick marks
set(gca, 'XAxisLocation', 'top', 'YDir', 'reverse') % Change axis location
[X, Y] = ndgrid(0.5:numel(X), 0.5:numel(Y)); % Text locations
text(gca, X(:), Y(:), string(Text), 'HorizontalAlignment', 'center', 'Clipping', 'on'); % Show text
end

function logs = read_logs(files)
for k = numel(files) : -1 : 1
    logs{k} = readtable(fullfile(files(k).folder, files(k).name));
end
logs = cat(1, logs{:});
end

function [Time, Count, Prob] = calc_stats(logs, op, x, y, max_time, max_count, gamma)
% Filter on operator
logs = logs(logs.Var3 == op, :);

% FIX
if op == "divide"
    logs.Var1 = logs.Var1./logs.Var2;
end

% Filter old results
if size(logs, 1) > max_count
    [~, i] = sortrows([logs.Var1  logs.Var2]);
    logs = logs(i, :);
    idx = [logs.Var1  logs.Var2];
    ind = all(idx(max_count + 1 : end, :) == idx(1 : end - max_count, :), 2);
    logs(ind, :) = [];
end

% Main
X = 1:max(logs.Var1);
Y = 1:max(logs.Var2);
sz = [max(X) max(Y)];
ind = [logs.Var1  logs.Var2];
time_list = max( min(logs.Var7, max_time), ~logs.Var6 * max_time); % Replace wrong answers with max time
Time = accumarray(ind, time_list,   sz, @median);
Count = accumarray(ind, time_list>0, sz, @sum);

% Subset
xi = ismember(X, x);
yi = ismember(Y, y);
Time = Time(xi, yi);
Count = Count(xi, yi);

% Edge case
Time(Count==0) = max_time;

% Relative probability (coef)
Prob = (Time/max_time).^gamma;
end