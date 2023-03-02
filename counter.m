clc; clear; close all;

%% Load filtering by day and double starlink mode
count = 0;
data = [];
Files=dir('S2023-01 post-pro'); % name of all the 92 files
for i=3:length(Files) % from 3 to 94 (without '.' and '..' leftover names)
    FileName=Files(i).name; % i-th file name
        data = load(FileName).data;
        count = count + length(data);
end
count