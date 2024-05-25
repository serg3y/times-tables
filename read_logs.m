function logs = read_logs(files)
for k = numel(files) : -1 : 1
    logs{k} = readtable(fullfile(files(k).folder, files(k).name));
end
logs = cat(1, logs{:});
end