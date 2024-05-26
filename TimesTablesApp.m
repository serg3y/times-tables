classdef TimesTablesApp < handle
    properties
        % Default values
        Numbers1 = [2 3 4 5 6 7 8 9]
        Numbers2 = [2 3 4 5 6 7 8 9]
        Operators= ["Times"]
        MaxTime  = 20
        MaxCount = 5
        Gamma    = 1

        % Internal parameters
        Data
        FigH
        StartH
        CounterH
        QuestionH
        ResponceH
        Results1H
        Results2H
    end

    methods
        function obj = TimesTablesApp
            obj.initFigure;
            obj.initSettingsPanel;
            obj.initQuizPanel;
            obj.initResultsPanel;
            obj.readData;
            obj.updateResults;
        end

        function updateResults(obj)
            if ismember("Times", obj.Operators)
                obj.plotResults(obj.Results1H, "Times")
            end
            if ismember("Divide", obj.Operators)
                obj.plotResults(obj.Results2H, "Divide")
            end
            set([obj.Results1H; obj.Results1H.Children; obj.Results1H.Colorbar], 'Visible', ismember("Times", obj.Operators));
            set([obj.Results2H; obj.Results2H.Children; obj.Results2H.Colorbar], 'Visible', ismember("Divide", obj.Operators));
        end

        function initFigure(obj)
            close(findobj(0, 'Name', 'Times Tables'));
            obj.FigH = figure( ...
                'Position', get(0).ScreenSize([3 4 3 4]) .* [0.2 0.2 0.6 0.6], ...
                'Name', 'Times Tables', 'NumberTitle', 'off', ...
                'ToolBar', 'none', 'MenuBar', 'none', ...
                'DefaultUipanelUnits', 'normalized', ...
                'DefaultUicontrolUnits', 'normalized', ...
                'DefaultUipanelBorderType', 'beveledin', ...
                'DefaultUicontrolFontSize', 14, ...
                'DefaultTextboxshapeFontSize', 14, ...
                'DefaultUicontrolFontWeight', 'bold', ...
                'DefaultTextboxshapeEdgeColor', 'n', ...
                'DefaultTextboxshapeVerticalAlignment', 'middle', ...
                'DefaultTextboxshapeHorizontalAlignment', 'center');
        end

        function initSettingsPanel(obj)
            h = uipanel(obj.FigH, 'Position', [0 0.0 0.33 1.0]);
            lbl = {'Operators' 'Numbers1' 'Numbers2' 'Max Time' 'Max Count' 'Selectivity'};
            pos = [0.9 0.8 0.7 0.5 0.4 0.3];
            for i = 1:numel(lbl)
                annotation(h, 'textbox', 'Position', [0.0 pos(i) 0.3 0.07], 'String', lbl{i});
            end
            uicontrol(h, 'Style', 'checkbox', 'Position', [0.35 0.9 0.3 0.07], 'String', 'Times',  'Value', ismember("Times", obj.Operators),  'Callback', @(o, ~)setOperators('Times',  o.Value))
            uicontrol(h, 'Style', 'checkbox', 'Position', [0.65 0.9 0.3 0.07], 'String', 'Divide', 'Value', ismember("Divide", obj.Operators), 'Callback', @(o, ~)setOperators('Divide', o.Value));
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.8 0.65 0.07], 'String', strjoin(string(obj.Numbers1)), 'Callback', @(o, ~)setVal('Numbers1', str2num(o.String)));
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.7 0.65 0.07], 'String', strjoin(string(obj.Numbers2)), 'Callback', @(o, ~)setVal('Numbers2', str2num(o.String)));
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.5 0.4 0.07], 'String', obj.MaxTime,  'Callback', @(o, ~)setVal('MaxTime',  str2double(o.String)), 'Tooltip', 'Maximum time per question (sec)');
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.4 0.4 0.07], 'String', obj.MaxCount, 'Callback', @(o, ~)setVal('MaxCount', str2double(o.String)), 'Tooltip', 'Limit assessment to this many results');
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.3 0.4 0.07], 'String', obj.Gamma,    'Callback', @(o, ~)setVal('Gamma',    str2double(o.String)), 'Tooltip', 'Selectivity');
            function setVal(prop, val)
                obj.(prop) = val;
                obj.updateResults;
            end
            function setOperators(prop, val)
                if val
                    obj.Operators = union(obj.Operators, prop);
                else
                    obj.Operators = setdiff(obj.Operators, prop);
                end
                obj.updateResults;
            end
        end

        function initQuizPanel(obj)
            h = uipanel(obj.FigH, 'Position', [0.33 0.0 0.33 1]);
            obj.QuestionH = annotation(h, 'textbox', 'Position', [0.1 0.65 0.8 0.2], 'String', 'Press START', 'FontSize', 36);
            obj.ResponceH = uicontrol(h, 'Style', 'edit', 'Position', [0.2 0.5 0.6 0.1], 'KeyPressFcn', @responceCallback);
            obj.StartH = uicontrol(h, 'Style', 'pushbutton', 'Position', [0.01 0.89 0.25 0.1], 'String', 'START', 'Callback', @(~, ~)obj.start);
            obj.CounterH = annotation(h, 'textbox', 'Position', [0.3 0.9  0.4 0.1], 'String', '#');
            h2 = uipanel(h, 'Position', [0.1 0.05 0.8 0.4]);
            t = {'7' '8' '9'; '4' '5' '6'; '1' '2' '3'; 'Del' '0' 'Enter'}; % Num pad buttons
            for r = 1:4
                for c = 1:3
                    uicontrol(h2, 'Style', 'pushbutton', 'String', t{r, c}, 'Position', [c/3-1/3 1-r/4 1/3 1/4], 'Callback', @(o, ~)numPadCallback(o.String));
                end
            end
            function numPadCallback(str)
                if isfinite(str2double(str))
                    obj.ResponceH.String = [obj.ResponceH.String str];
                elseif str == "Del"
                    obj.ResponceH.String = obj.ResponceH.String(1:end-1);
                elseif str == "Enter"
                    obj.ResponceH.UserData = 1;
                end
            end
            function responceCallback(o, e)
                if e.Key == "return"
                    o.UserData = 1;
                end
            end
        end

        function initResultsPanel(obj)
            p = uipanel(obj.FigH, 'OuterPosition', [0.66 0 0.34 1]);
            obj.Results1H = axes(p, 'Position', [0.1 0.52 0.9 0.4]);
            obj.Results2H = axes(p, 'Position', [0.1 0.02 0.9 0.4]);
        end

        function plotResults(obj, ax, operator)
            cla(ax), hold(ax, 'on'), axis(ax, 'tight') % Prepare axis
            [Time, Count] = getStats(obj.Data, operator, obj.Numbers1, obj.Numbers2, obj.MaxTime, obj.MaxCount, obj.Gamma);
            title(ax, sprintf('%s: %.2f sec', operator, mean(Time(Time>0))), 'FontSize', 14)
            plotmatrix(ax, obj.Numbers1, obj.Numbers2, Time, Count/obj.MaxCount, Count)
            colormap(ax, [0.8 0.8 0.8; interp1(0:1, [0 1 0; 1 0 0], linspace(0, 1, 64)).^(1/2.4)])
            clim(ax, [0 obj.MaxTime])
            colorbar(ax)
        end

        function start(obj)
            if obj.StartH.String == "START"
                obj.StartH.String = "STOP";
                obj.CounterH.String = "#";
                counter = 0;
            else
                obj.StartH.String = "START";
                obj.QuestionH.String = "";
                return
            end

            % Prepare to write results to file
            if ~isfolder('log')
                mkdir('log')
            end
            file = sprintf('log/%s_[%s]_[%s]_[%s].log', ...
                string(datetime('now', 'Format', 'yyyyMMdd_HHmm')), ...
                strjoin(obj.Operators), strjoin(string(obj.Numbers1)), strjoin(string(obj.Numbers2)));
            pause(1)

            % Main loop
            while obj.StartH.String == "STOP"
                counter = counter + 1;
                obj.CounterH.String = counter;

                % Analyse past results
                for k = numel(obj.Operators) : -1 : 1
                    [~, ~, p(:,:,k)] = getStats(obj.Data, obj.Operators(k), obj.Numbers1, obj.Numbers2, obj.MaxTime, obj.MaxCount, obj.Gamma);
                end

                % Pick a question
                [x, y, z] = ndgrid(obj.Numbers1, obj.Numbers2, obj.Operators);
                n = rand(1, 1) * sum(p(:));
                [~, i] = max(n < cumsum(p(:)), [], 1);
                num1 = x(i);
                num2 = y(i);
                opp  = z(i);
                switch opp
                    case 'Times'
                        Question = sprintf('%3d × %2d = ', num1, num2);
                        voicequestion(num1, opp, num2);
                        answer = num1 * num2;
                    case 'Divide'
                        Question = sprintf('%3d ÷ %2d = ', num1 * num2, num1);
                        voicequestion(num1 * num2, opp, num1);
                        answer = num2;
                        num1 = num1 * num2;
                end

                % Wait for user responce
                obj.QuestionH.String = Question;
                obj.ResponceH.UserData = [];
                obj.ResponceH.String = '';
                tic
                while isempty(obj.ResponceH.UserData) && obj.StartH.String == "STOP"
                    pause(0.1)
                end
                if obj.StartH.String == "START"
                    break
                end
                reply = str2double(obj.ResponceH.String); % Convert to number
                t = toc;

                % Check answer
                obj.QuestionH.String = Question + " " + answer;
                if reply == answer
                    sound(wavread('right')*4, 8000)
                else
                    sound(wavread('wrong')*5, 4000)
                end
                pause(1)

                % Log to file
                log(file, '%3d, %3d, %6s, %3d, %3d, %1d, %4.1f', num1, num2, opp, answer, reply, reply==answer, t);

                % Plot Results
                obj.updateResults

            end

            obj.CounterH.String = "#";
        end

        function readData(obj)
            files = dir('log/*.log');
            if isempty(files)
                obj.Data = [];
            else
                for k = numel(files) : -1 : 1
                    data{k} = readtable(fullfile(files(k).folder, files(k).name));
                end
                obj.Data = cat(1, data{:});
            end
        end
    end
end

function plotmatrix(ax, X, Y, Color, Alpha, Text)
% Display a matrix as a grid of cells with color, alpha, text.
set(ax, ...
    'XTick', 0.5:numel(X), 'XTickLabel', X, ... % Set x tick marks
    'YTick', 0.5:numel(Y), 'YTickLabel', Y, ... % Set y tick marks
    'XAxisLocation', 'top', 'YDir', 'reverse') % Change axis location
surf(ax, 0:numel(X), 0:numel(Y), zeros(numel(Y) + 1, numel(X) + 1), ... % Display matrix
    'FaceColor', 'flat', 'CData', Color', 'EdgeColor', 'w', 'LineWidth', 2,... % Set color
    'FaceAlpha', 'flat', 'AlphaData', Alpha', 'AlphaDataMapping', 'none') % Set alpha
[X, Y] = ndgrid(0.5:numel(X), 0.5:numel(Y)); % Text locations
text(ax, X(:), Y(:), string(Text), 'Clipping', 'on', 'HorizontalAlignment', 'center'); % Show text
end

function [Time, Count, Prob] = getStats(Data, Operator, Numbers1, Numbers2, MaxTime, MaxCount, Gamma)
% Select operator
Data = Data(strcmpi(Data.Var3, Operator), :);

% BUG FIX / TODO
if Operator == "Divide"
    Data.Var1 = Data.Var1./Data.Var2;
end

% Keep only n latest results
if size(Data, 1) > MaxCount
    [~, i] = sortrows([Data.Var1  Data.Var2]);
    Data = Data(i, :);
    idx = [Data.Var1  Data.Var2];
    ind = all(idx(MaxCount + 1 : end, :) == idx(1 : end - MaxCount, :), 2);
    Data(ind, :) = [];
end

% Main
X = 1 : max([Numbers1 idx(:,1)']);
Y = 1 : max([Numbers2 idx(:,2)']);
sz = [max(X) max(Y)];
ind = [Data.Var1 Data.Var2];
time_list = max(min(Data.Var7, MaxTime), ~Data.Var6 * MaxTime); % Replace wrong answers with max time
Time = accumarray(ind, time_list, sz, @median, MaxTime);
Count = accumarray(ind, time_list>0, sz, @sum, 0);

% Subset
xi = ismember(X, Numbers1);
yi = ismember(Y, Numbers2);
Time = Time(xi, yi);
Count = Count(xi, yi);

% Probability
Prob = (Time / MaxTime).^Gamma;
end









function voicequestion(n1, operator, n2)
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
