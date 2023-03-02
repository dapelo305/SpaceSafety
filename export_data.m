clc; clear; close all;
tic
%% Paths
addpath(genpath('S2023-01'));

mkdir('S2023-01 post-pro');
addpath(genpath('S2023-01 post-pro'));

%% 
tic
Folders=dir('S2023-01'); % name of all the 92 internal folders
for i=3:length(Folders) % from 3 to 94 (without '.' and '..' leftover names)
    lines = {}; % reset the cell array every loop step
    FolderName=Folders(i).name; % i-th folder name
    FolderPath = fullfile('S2023-01',FolderName,'sort-minRange.txt'); % form the path of the file inside the i-th folder
    file = fopen(FolderPath,'r'); % open the file
        line = fgetl(file); % read the first line
        while ischar(line) % while there is a line
            lines{end+1,1} = line; % add the line to the cell array
            line = fgetl(file); % read next line
        end
    fclose(file); % close file
    % Function handle to split each row by comma delimiter 
    func = @(input)strsplit(input, ',');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    data = cellfun(func,lines,'UniformOutput',false); % split each line in the cathegories delimited by a comma in the original file
    postproPath = fullfile('S2023-01 post-pro',strcat(FolderName,'.mat'));
    save(postproPath,'data')
end
toc
