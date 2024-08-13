% Features
% - Lets user select which operators and which numbers to test.
% - Logs results to files.
% - Shows results in realtime.
% - Prioretises questions that were answered incorrectly or slowly.

% TODO
% - Include addition and subtraction
% - New user button
% - Grey out input during pause

classdef TimesTables < handle
    properties
        % Default values
        Operators = ["Times" "Divide"]
        Numbers1 = [2:11]
        Numbers2 = [2:11]
        MaxTime = 20
        MaxCount = 3
        Gamma = 1
        Display = 'Count'

        % Internal parameters
        Data
        FigH
        StartH
        CounterH
        QuestionH
        AnswerH
        ResponceH
        Results1H
        Results2H
        numpadH = [];
        History = cell(1, 2);
        
    end

    methods
        function obj = TimesTables
            obj.readIniFile;
            obj.createFigure;
            obj.createSettingsPanel;
            obj.createQuizPanel;
            obj.createResultsPanel;
            obj.readData;
            obj.updateResults;
        end

        function readIniFile(obj)
            if isfile('TimesTables.ini')
                t = readlines('TimesTables.ini'); % Read the file
                t = regexpi(t, '(\w+) *[:=] *([^%#]+)', 'tokens', 'once'); % Extract property value pairs
                t = cat(1, t{~cellfun(@isempty,t)})'; % Skip empty
                t = struct(t{:}); % Make a struct
                for f = string(intersect(fieldnames(obj), fieldnames(t)))' % Step through common fields
                    if f == "Operators"
                        obj.Operators = string(regexp(t.(f),'\w*','match'));
                    else
                        obj.(f) = str2num(t.(f), 'Evaluation', 'restricted'); %#ok<ST2NM>
                    end
                end
            end
        end

        function createFigure(obj)
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

        function createSettingsPanel(obj)
            h = uipanel(obj.FigH, 'Position', [0 0.0 0.33 1.0]);
            lbl = {'Operators' 'Numbers1' 'Numbers2' 'Selectivity' 'Max Time' 'Max Count' 'Display'};
            pos = [0.9 0.8 0.7 0.5 0.3 0.2 0.1];
            for i = 1:numel(lbl)
                annotation(h, 'textbox', 'Position', [0.0 pos(i) 0.3 0.05], 'String', lbl{i});
            end
            uicontrol(h, 'Style', 'chec', 'Position', [0.35 0.9 0.3 0.05], 'String', 'Times',  'Value', ismember("Times", obj.Operators),  'Callback', @(o, ~)setOperators('Times',  o.Value))
            uicontrol(h, 'Style', 'chec', 'Position', [0.65 0.9 0.3 0.05], 'String', 'Divide', 'Value', ismember("Divide", obj.Operators), 'Callback', @(o, ~)setOperators('Divide', o.Value));
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.8 0.65 0.05], 'String', mat2str(obj.Numbers1), 'Callback', @(o, ~)setVal('Numbers1', str2num(o.String, 'Evaluation', 'restricted'))); %#ok<ST2NM>
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.7 0.65 0.05], 'String', mat2str(obj.Numbers2), 'Callback', @(o, ~)setVal('Numbers2', str2num(o.String, 'Evaluation', 'restricted'))); %#ok<ST2NM>
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.5 0.40 0.05], 'String', obj.Gamma,    'Callback', @(o, ~)setVal('Gamma',    str2double(o.String)), 'Tooltip', 'Selectivity');
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.3 0.40 0.05], 'String', obj.MaxTime,  'Callback', @(o, ~)setVal('MaxTime',  str2double(o.String)), 'Tooltip', 'Maximum time per question (sec)');
            uicontrol(h, 'Style', 'edit', 'Position', [0.3 0.2 0.40 0.05], 'String', obj.MaxCount, 'Callback', @(o, ~)setVal('MaxCount', str2double(o.String)), 'Tooltip', 'Limit assessment to this many results');
            uicontrol(h, 'Style', 'popu', 'Position', [0.3 0.1 0.40 0.05], 'String', {'Count' 'Time'}, 'FontSize', 12, 'Callback', @(o, ~)setVal('Display', o.String{o.Value}), 'Value', 1);
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


        function createQuizPanel(obj)
            h = uipanel(obj.FigH, 'Position', [0.33 0.0 0.33 1]);
            obj.QuestionH = annotation(h, 'textbox', 'Position', [0.1 0.7 0.8 0.1], 'String', 'Press START', 'FontSize', 36, 'FontWeight', 'bold');
            obj.AnswerH = annotation(h, 'textbox', 'Position', [0.1 0.6 0.8 0.1], 'String', '', 'FontSize', 36, 'FontWeight', 'bold');
            obj.ResponceH = uicontrol(h, 'Style', 'edit', 'Position', [0.2 0.5 0.6 0.1], 'FontSize', 36, 'KeyPressFcn', @responceCallback, 'Enable', 'off');
            obj.StartH = uicontrol(h, 'Style', 'pushbutton', 'Position', [0.01 0.89 0.25 0.1], 'String', 'START', 'Callback', @(~, ~)obj.start);
            obj.CounterH = annotation(h, 'textbox', 'Position', [0.3 0.9  0.4 0.1], 'String', '', 'FontAngle', 'italic');
            h2 = uipanel(h, 'Position', [0.1 0.05 0.8 0.4], 'Enable', 'off');
            t = {'7' '8' '9'; '4' '5' '6'; '1' '2' '3'; 'Del' '0' 'Enter'}; % Num pad buttons
            for r = 1:4
                for c = 1:3
                    obj.numpadH(end+1) = uicontrol(h2, 'Style', 'pushbutton', 'String', t{r, c}, 'Position', [c/3-1/3 1-r/4 1/3 1/4], 'Callback', @(o, ~)numPadCallback(o.String), 'Enable', 'off');
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

        function createResultsPanel(obj)
            p = uipanel(obj.FigH, 'OuterPosition', [0.66 0 0.34 1]);
            obj.Results1H = axes(p, 'Position', [0.1 0.52 0.9 0.4]);
            obj.Results2H = axes(p, 'Position', [0.1 0.02 0.9 0.4]);
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
        function plotResults(obj, ax, operator)
            cla(ax), hold(ax, 'on'), axis(ax, 'tight') % Prepare axis
            [Time, Count] = obj.getStats(operator);
            title(ax, sprintf('%s   %.2f sec', operator, mean(Time(Time>0))), 'FontSize', 14)
            if obj.Display == "Time"
                Text = Time;
            else
                Text = Count;
            end
            plotmatrix(ax, obj.Numbers1, obj.Numbers2, Time, Count, round(Text, 3, 'significant'))
            colormap(ax, interp1(0:1, [0 1 0; 1 0 0], linspace(0, 1, 256)).^(1/2.4))
            clim(ax, [0 obj.MaxTime])
            alim(ax, [0 obj.MaxCount])
            colorbar(ax)
        end

        function start(obj)
            if isempty(obj.Operators)
                return
            elseif obj.StartH.String == "START" % User pressed START
                obj.StartH.String = "STOP";
                counter = 0;
            elseif obj.StartH.String == "STOP" % User pressed STOP
                obj.StartH.String = "START";
                obj.QuestionH.String = "";
                obj.CounterH.String = "";
                return
            end

            % Prepare to write results to file
            if ~isfolder('log')
                mkdir('log')
            end
            file = sprintf('log/%s_[%s]_%s_%s.log', datetime('now', 'Format', 'yyyyMMdd_HHmm'), strjoin(obj.Operators), mat2str(obj.Numbers1), mat2str(obj.Numbers2));

            % Main loop
            pause(1)
            while obj.StartH.String == "STOP"
                
                % Display question number
                counter = counter + 1;
                obj.CounterH.String = "#" + counter;

                % Analyse past results
                for k = numel(obj.Operators) : -1 : 1
                    [~, ~, prob(:,:,k)] = obj.getStats(obj.Operators(k));
                end

                % Pick a question
                for retry = 1:50 % Avoid asking same question twice
                    [x, y, z] = ndgrid(obj.Numbers1, obj.Numbers2, obj.Operators);
                    n = rand(1, 1) * sum(prob(:));
                    [~, i] = max(n < cumsum(prob(:)), [], 1);
                    num1 = x(i);
                    num2 = y(i);
                    opp  = z(i);
                    if any(cellfun(@(x)isequal(x, {num1 num2 opp}), obj.History))
                        if retry==50
                            disp(1)
                        end
                        continue % Try again

                    else
                        break
                    end
                end
                obj.History{1} = {num1 num2 opp}; % Remember for next time
                obj.History = circshift(obj.History,1);
                
                switch opp
                    case 'Times'
                        Question = sprintf('%3d × %2d = ', num1, num2);
                        voicequestion(num1, opp, num2);
                        answer = num1 * num2;
                    case 'Divide'
                        Question = sprintf('%3d ÷ %2d = ', num1 * num2, num1);
                        voicequestion(num1 * num2, opp, num1);
                        answer = num2;
                end

                % Wait for user responce
                set(obj.QuestionH, 'String', Question);
                set(obj.AnswerH, 'String', '');
                set(obj.ResponceH, 'UserData', [], 'String', '', 'Enable', 'on');
                set(obj.numpadH, 'Enable', 'on');
                uicontrol(obj.ResponceH) % Give focus to input box
                tic
                while isempty(obj.ResponceH.UserData) && obj.StartH.String == "STOP"
                    pause(0.1)
                end
                if obj.StartH.String == "START"
                    break
                end
                
                reply_str = obj.ResponceH.String;
                set(obj.ResponceH, 'Enable', 'off');
                set(obj.numpadH, 'Enable', 'off');
                reply = str2double(reply_str); % Convert to number
                
                % Append results to Data
                obj.Data(end+1, :) = {opp, num1, num2, answer, reply, reply==answer, toc};

                % Create output file
                if ~isfile(file)
                    writelines('Operator,Number1,Number2,Answer,Responce,Correct,Time', file)
                end

                % Append results to log file
                writelines(sprintf('%6s, %3.0f, %3.0f, %3.0f, %3.0f, %3.0f, %4.1f', obj.Data{end, :}), file, 'WriteMod', 'append')

                % Give user feedback
                obj.AnswerH.String = answer;
                if reply == answer
                    obj.AnswerH.Color = [0 0.7 0];
                    sound(wavread('right')*4, 8000)
                    pause(1)
                else
                    reply_str, reply, answer % Debugging
                    obj.AnswerH.Color = [1 0 0];
                    sound(wavread('wrong')*5, 4000)
                    pause(5)
                end
                
                % Plot Results
                obj.updateResults
            end
        end

        function readData(obj)
            files = dir('log/*.log');
            if isempty(files)
                obj.Data = table('Size',[0 7], ...
                    'VariableNames',["Operator" "Number1" "Number2" "Answer" "Responce" "Correct" "Time"  ], ...
                    'VariableTypes',["string"   "double"  "double"  "double" "double"   "double"  "double"]);
            else
                for k = numel(files) : -1 : 1
                    data{k} = readtable(fullfile(files(k).folder, files(k).name), 'TextType', 'string');
                end
                obj.Data = cat(1, data{:});
            end
        end


        function [Time, Count, Prob] = getStats(obj, Operator)

            % Filter the data
            data = obj.Data; % Make a temporary copy
            data = data(strcmpi(data.Operator, Operator) & ismember(data.Number1, obj.Numbers1) & ismember(data.Number2, obj.Numbers2), :);
            max_N1 = max(obj.Numbers1); % Expected array size
            max_N2 = max(obj.Numbers2);

            % Keep only MaxCount latest results
            if size(data, 1) > obj.MaxCount
                [~, i] = sortrows([data.Number1 data.Number2]);
                data = data(i, :);
                idx = [data.Number1  data.Number2];
                ind = all(idx(obj.MaxCount + 1 : end, :) == idx(1 : end - obj.MaxCount, :), 2);
                data(ind, :) = [];
            end

            % Treat incorrect and long answers as max time
            data.Time(data.Time > obj.MaxTime | ~data.Correct) = obj.MaxTime;

            % Main
            ind = [data.Number1 data.Number2];
            Time = accumarray(ind, data.Time, [max_N1 max_N2], @mean);
            Count = accumarray(ind, data.Time>0, [max_N1 max_N2], @sum);

            % Subset
            xi = ismember(1 : max_N1, obj.Numbers1);
            yi = ismember(1 : max_N2, obj.Numbers2);
            Time = Time(xi, yi);
            Count = Count(xi, yi);

            % Probability
            % Prob = 1 means all answers were wrong or not yet answered or a mix,
            % as user provides more answers Prob tend to mean(Time)/MaxTime.
            Prob = ((Time / obj.MaxTime).*(Count/obj.MaxCount) + (obj.MaxCount-Count)./obj.MaxCount) .^obj.Gamma;
        end

    end
end


function voicequestion(n1, operator, n2)
sound([num2wav(n1); wavread(operator)*0.6; num2wav(n2)], 8000);
end


function w = num2wav(num)
if     num > 0 && num<100,     w = wavread(num);
elseif num < 0,                w = [wavread("minus"); num2wav(-num)];
elseif num == 100,              w = wavread(100);
elseif num > 100 && num < 199, w = [wavread(100); num2wav(num - 100)];
elseif num == 200,              w = wavread(200);
elseif num > 200 && num < 299, w = [wavread(200); num2wav(num - 200)];
else,  fprintf(2, 'ERROR: %g is not supported\n', num)
end
end


function y = wavread(name)
[y, f] = audioread("wav/" + name + ".wav"); % Read file
y = y(1 : round(f/8000) : end, 1); % Use ~8000 bits/sec mono (hack)
i1 = find(y > 0.01, 1, 'first'); % Trim silence from start
i2 = find(y > 0.01, 1, 'last') + 0.2*8000; % Append 0.2 sec silence to end
y = y(i1 : min(i2, end)); % Output
end


function plotmatrix(ax, X, Y, Color, Alpha, Text)
% Display a matrix as a grid of cells with color, alpha, text.
set(ax, ...
    'XTick', 0.5:numel(X), 'XTickLabel', X, ... % Set x tick marks
    'YTick', 0.5:numel(Y), 'YTickLabel', Y, ... % Set y tick marks
    'XAxisLocation', 'top', 'YDir', 'reverse') % Change axis location
surf(ax, 0:numel(X), 0:numel(Y), zeros(numel(Y) + 1, numel(X) + 1), ... % Display matrix
    'FaceColor', 'flat', 'CData', Color', 'EdgeColor', 'w', 'LineWidth', 2,... % Set color
    'FaceAlpha', 'flat', 'AlphaData', Alpha', 'AlphaDataMapping', 'scaled') % Set alpha
[X, Y] = ndgrid(0.5:numel(X), 0.5:numel(Y)); % Text locations
text(ax, X(:), Y(:), string(Text), 'Clipping', 'on', 'HorizontalAlignment', 'center'); % Show text
end