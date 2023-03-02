clc; clear; close all;

set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultAxesFontSize', 10);
set(groot, 'defaultAxesGridAlpha', 0.3);
set(groot, 'defaultAxesLineWidth', 0.75);
set(groot, 'defaultAxesXMinorTick', 'on');
set(groot, 'defaultAxesYMinorTick', 'on');
set(groot, 'defaultFigureRenderer', 'OpenGL');
set(groot, 'defaultLegendBox', 'on');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultLegendLocation', 'best');
set(groot, 'defaultLineLineWidth', 1);
set(groot, 'defaultLineMarkerSize', 1);
set(groot, 'defaultTextInterpreter', 'latex');

%% Paths
addpath(genpath('S2023-01 post-pro'));

%% Load filtering by day and double starlink mode
day = 29; % select 01,02,...,31
starlink_twice = 0; % 0=NO, 1=YES

data = [];
Files=dir('S2023-01 post-pro'); % name of all the 92 files
for i=3:length(Files) % from 3 to 94 (without '.' and '..' leftover names)
    FileName=Files(i).name; % i-th file name
    if str2double(FileName(18:19)) == day
        data = [data; load(FileName).data];
    end
end

% Eliminate double starlink conjunctions
if starlink_twice == 0
    for i=1:length(data)
        if contains(data{i,1}{1,2},'STARLINK') && contains(data{i,1}{1,5},'STARLINK')
            data{i,1} = {};
        end
    end
end
empty = cellfun('isempty',data);
data(all(empty,2),:) = [];

%% max prob & min range
for i=1:length(data)
    prob(i) = str2double(data{i,1}{1,7});
    range(i) = str2double(data{i,1}{1,9});
end

figure()
semilogx(prob,range,'.')
title(strcat('Range vs Probability (',num2str(day),'-01-2023)'))
xlabel('Maximum probability')
ylabel('Minimum range [km]')

figure()
histogram(range,50)
title(strcat('Histogram of minimum range (',num2str(day),'-01-2023)'))
xlabel('Minimum range [km]')
ylabel('Number of conjuctions')

figure()
histogram(log10(prob),50)
title(strcat('Histogram of maximum probability (',num2str(day),'-01-2023)'))
xlabel('$log_{10}$(Maximum probability)')
ylabel('Number of conjuctions')

%% Repeatability
track = {{},[]}; %{'name','count'}
for i=1:length(data)

    name1 = data{i,1}{1,2};
    if contains(name1,'DEB')
        name1 = 'Debris';
    else
        if contains(name1,' ') 
            name1 = extractBefore(name1,' ');
        end
        if contains(name1,'-')
            name1 = extractBefore(name1,'-');
        end
    end
    if any(strcmp(track{1,1},name1)) % if already exists
        idx = find(strcmp(track{1,1},name1));
        track{1,2}(1,idx) = track{1,2}(1,idx) + 1;
    else
        track{1,1} = [track{1,1},name1];
        track{1,2} = [track{1,2},1];
    end

    name2 = data{i,1}{1,5};
    if contains(name2,'DEB')
        name2 = 'Debris';
    else
        if contains(name2,' ') 
            name2 = extractBefore(name2,' ');
        end
        if contains(name2,'-')
            name2 = extractBefore(name2,'-');
        end
    end
    if any(strcmp(track{1,1},name2)) % if already exists
        idx = find(strcmp(track{1,1},name2));
        track{1,2}(1,idx) = track{1,2}(1,idx) + 1;
    else
        track{1,1} = [track{1,1},name2];
        track{1,2} = [track{1,2},1];
    end

end

% Sort in descending direction
[sorted_track_count, I] = sort(track{1,2},'descend');
sorted_track_name = track{1,1}(I);

% Plot bar graph
Nnames = 30; % number of names plotted
figure()
bar(sorted_track_count(1:Nnames))
title(strcat('Repeatability (',num2str(day),'-01-2023)'))
set(gca,'xtick',[1:Nnames],'xticklabel',sorted_track_name)
ylabel('Number of occurrences')
