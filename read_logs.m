function T = read_logs(files)
% Reads previous log files and returns all results in a single table.
% T = read_logs(files)

if isempty(files)
    T = [];
else
    for k = numel(files) : -1 : 1
        T{k} = readtable(fullfile(files(k).folder, files(k).name));
    end
    T = cat(1, T{:});
end
end