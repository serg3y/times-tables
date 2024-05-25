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