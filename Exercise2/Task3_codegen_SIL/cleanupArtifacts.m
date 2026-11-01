function cleanupArtifacts()
%CLEANUPARTIFACTS Remove Simulink and code generation artifacts in the
% current directory
%
% Removes recursively:
%   *.slxc
%   *_rtw/
%   slprj/
%   codegen/

rootDir = pwd;

fprintf('Cleaning artifacts under:\n  %s\n\n', rootDir);

%% Delete *.slxc
files = dir(fullfile(rootDir, '**', '*.slxc'));

for k = 1:numel(files)
    filePath = fullfile(files(k).folder, files(k).name);

    if isfile(filePath)
        fprintf('Deleting file: %s\n', filePath);
        delete(filePath);
    end
end

%% Delete slprj directories
deleteFolders(rootDir, 'slprj');

%% Delete codegen directories
deleteFolders(rootDir, 'codegen');

%% Delete *_rtw directories
deleteFolders(rootDir, '*_rtw');

fprintf('\nCleanup complete.\n');
end


function deleteFolders(rootDir, pattern)

folders = dir(fullfile(rootDir, '**', pattern));
folders = folders([folders.isdir]);

% Remove "." and ".." if applicable
folders = folders(~ismember({folders.name}, {'.', '..'}));

if isempty(folders)
    return;
end

paths = arrayfun(@(x) fullfile(x.folder, x.name), ...
    folders, 'UniformOutput', false);

% Delete deepest directories first
[~, idx] = sort(cellfun(@length, paths), 'descend');
paths = paths(idx);

for k = 1:numel(paths)
    folderPath = paths{k};

    if isfolder(folderPath)
        fprintf('Deleting folder: %s\n', folderPath);

        try
            rmdir(folderPath, 's');
        catch ME
            warning('Could not delete "%s": %s', ...
                folderPath, ME.message);
        end
    end
end
end