function TimesTables(N1, N2, OP, m)

% Defaults
N1 = 2:11;   % Numbers
N2 = 2:11;   % Numbers
OP = ["times" "divide"]; % Opperators
num_questions = 50;
dynamic = true;
max_time = 20; % Maximum time per question
max_hist = 5;  % Look at only this many previous results
gamma = 1;

% Checks
cd(fileparts(mfilename('fullpath')))

% Generate nubers
if dynamic
    % Read previous results
    T = read_logs(dir('log/*.log'));

    % Give each question a probability based on past results
    if isempty(T)
        p = ones(numel(N1), numel(N2));
    else
        for k = numel(OP) : -1 : 1
            [~, ~, p(:,:,k)] = calc_stats(T, OP(k), N1, N2, max_time, max_hist, gamma);
        end
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
file = sprintf('log/%s_[%s]_[%s]_[%s]_%g.log', datetime('now', 'Format', 'yyyyMMdd_HHmm'), strjoin(string(N1)), strjoin(string(N2)), strjoin(OP), numel(V1));
%eg log/20240525_2225_[2 3 4 5 6 7 8 9 10 11]_[2 3 4 5 6 7 8 9 10 11]_[times divide]_50.log
pause(1)

% Step through questions
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
    log(file, '%3d, %3d, %6s, %3d, %3d, %1d, %4.1f', num1, num2, opp, answer, reply, reply==answer, t);

    TimesTablesResults(N1, N2, OP, max_time, max_hist, gamma, T)
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