clc; clear; close all;

% 1) NORAD 1
% 2) NAME 1
% 3) DAYS SINCE EPOCH 1
% 4) NORAD 2
% 5) NAME 2
% 6) DAYS SINCE EPOCH 2
% 7) MAX PROBABILITY 
% 8) DILUTION THRESHOLD [KM]
% 9) MINIMUM RANGE [KM]
% 10) RELATIVE VELOCITY
% 11) START (BOTH ENTER THE COMPUTATIONAL REGION OF EACH OTHER)
% 12) TCA (TIME OF CLOSEST APPROACH)
% 13) STOP (BOTH LEAVE THE COMPUTATIONAL REGION OF EACH OTHER)

%% spacetrack
% import py.spacetrack.SpaceTrackClient
% op = py.importlib.import_module('spacetrack.operators');
% st = SpaceTrackClient('email', 'password');

%% spacetracktool
% st = py.importlib.import_module('spacetracktool');
% query = st.SpaceTrackClient('email', 'password');

%% Python (spacetrack)
pyrun(["from spacetrack import SpaceTrackClient;", ...
    "import spacetrack.operators as op", ...
    "import json"])

st = pyrun("st = SpaceTrackClient('davidperezlopez305@gmail.com', 'orquidea318110318110')",'st');

%% Paths
addpath(genpath('S2023-01 post-pro'));
addpath(genpath('SGP4_2.1.0\SGP4')); % SGP4: final state || SGP4_Vectorized: one state per timestep

%% Load filtering by day, calculation of the day, and double starlink mode
day = 29; % 01,02,...,31
calc = 0; % 0=all, 1=first, 2=second, 3=third (calculation of the day)
starlink_twice = 0; % 0=NO, 1=YES

data = [];
calc_count = 0;
calc_dates = [];
Files=dir('S2023-01 post-pro'); % name of all the 92 files
for i=3:length(Files) % from 3 to 94 (without '.' and '..' leftover names)
    FileName=Files(i).name; % i-th file name
    if str2double(FileName(18:19)) == day
        calc_count = calc_count + 1;
        if calc_count == calc || calc == 0
            data = [data; load(FileName).data];
            calc_dates = [calc_dates, str2double(FileName(18:24))];
        end
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

%% Analysis
Nranges = 8; % (0,1], (1,2], ..., (Nranges-1, Nranges]
Nsamples = 5;
result_r = NaN(Nranges,Nsamples);
result_v = NaN(Nranges,Nsamples);
names = cell(Nranges,Nsamples,2);

% Range loop
for r = 1:Nranges
    r
    % Loop over all data
    i = 0;
    samples_count = 1;
    while i<length(data) && samples_count<=Nsamples
        samples_count
        i = i + 1;
        % If a line complies the range restriction (both objects DSE are inside the range (r-1,r])
        if (str2double(data{i,1}{1,3})>r-1 && str2double(data{i,1}{1,3})<=r) && (str2double(data{i,1}{1,6})>r-1 && str2double(data{i,1}{1,6})<=r)
            
            % Conjuction
            conj = data{i,1}; % 1x13 cell
            TCAdate = conj{12}; % Time of Closest Approach date
            TCAday = date2day(TCAdate); % Time of Closest Approach day

            % Object 1
            NORAD_1 = str2double(conj{1}); % NORAD catalogue number of object 1
            DSE_1 = str2double(conj{3}); % Days Since Epoch (days <from the TLE used to compute the prediction> to <Time of closest Approach>)
            [TLE_1,flag_1] = getTLE(TCAday,NORAD_1,DSE_1); % TLE of object 1
            pause(5);
            
            % Object 2
            NORAD_2 = str2double(conj{4}); % NORAD catalogue number of object 1
            DSE_2 = str2double(conj{6}); % Days Since Epoch (days <from the TLE used to compute the prediction> to <Time of closest Approach>)
            [TLE_2,flag_2] = getTLE(TCAday,NORAD_2,DSE_2); % TLE of object 2
            pause(5);

            % If both TLE are correctly obtained -> compute propagation and store result
            if flag_1==1 && flag_2==1
                % Propagation (SGP4 final state)
                [r1,v1] = propagate(TLE_1,TCAday);
                [r2,v2] = propagate(TLE_2,TCAday);
                
                distance = norm(r2-r1); %[km]
                comp_r = abs(distance-str2double(conj{9})); %[km]
                result_r(r,samples_count) = comp_r; %[km]

                rel_vel = norm(v2-v1); %[km/s]
                comp_v = abs(rel_vel-str2double(conj{10})); %[km/s]
                result_v(r,samples_count) = comp_v; %[km/s]

                names{r,samples_count,1} = conj{2};
                names{r,samples_count,2} = conj{5};

                samples_count = samples_count + 1;
            end
        end
    end
end

%% Save/Load
% Save workspace except the python variable 'st'
% save('29all_8x5 .mat', 'result_r', 'result_v', 'names', 'day', 'calc', 'Nranges', 'Nsamples')
% Load results
load('29all_8x5.mat')

%% Plot result
run('remove_groot.m')
sz = 20; % size of scatter dots

% Distance
x_axis = 0.5:1:Nranges;
yl = [0,2.5];
figure()
hold on
for i=1:size(result_r,1)
    scatter(x_axis(i)*ones(size(result_r,2)), result_r(i,:)*1e3, sz, 'bo', 'filled') % convert to [m]
    plot([x_axis(i)+0.5,x_axis(i)+0.5], yl, 'color', [0.5 0.5 0.5])
end
title(strcat('Conjuction calculations of',{' '},num2str(day),'-01-2023 (',num2str(Nranges),{' '},'ranges,',{' '},num2str(Nsamples),{' '},'samples)'),'interpreter','latex')
xlabel('Days since epoch','interpreter','latex')
ylabel('Error in position at TCA [m]','interpreter','latex')

% Relative velocity
x_axis = 0.5:1:Nranges;
yl = [0,1];
figure()
hold on
for i=1:size(result_v,1)
    scatter(x_axis(i)*ones(size(result_v,2)), result_v(i,:)*1e3, sz, 'bo', 'filled') % convert to [km/s]
    plot([x_axis(i)+0.5,x_axis(i)+0.5], yl, 'color', [0.5 0.5 0.5])
end
title(strcat('Conjuction calculations of',{' '},num2str(day),'-01-2023 (',num2str(Nranges),{' '},'ranges,',{' '},num2str(Nsamples),{' '},'samples)'),'interpreter','latex')
xlabel('Days since epoch','interpreter','latex')
ylabel('Error in relative velocity at TCA [m/s]','interpreter','latex')

%% Conjuction 1
% conj = data{1,1}; % 1x13 cell
% TCAdate = conj{12}; % Time of Closest Approach date
% TCAday = date2day(TCAdate); % Time of Closest Approach day

%% Object 1 with function getTLE
% NORAD_1 = str2double(conj{1}); % NORAD catalogue number of object 1
% DSE_1 = str2double(conj{3}); % Days Since Epoch (days <from the TLE used to compute the prediction> to <Time of closest Approach>)
% 
% TLE_1 = getTLE(TCAday,NORAD_1,DSE_1);

%% Object 1 without function
% NORAD_1 = str2double(conj{1}); % NORAD catalogue number of object 1
% DSE_1 = str2double(conj{3}); % Days Since Epoch (days <from the TLE used to compute the prediction> to <Time of closest Approach>)
% 
% TLEday_1 = TCAday - DSE_1; % Day of the TLE of the object 1
% TLEdate_1 = day2date(TLEday_1); % Date of the TLE of the object 1
% 
% TLEshortdate_1 = TLEdate_1(1:11);
% TLEnextshortdate_1 = getNextDay(TLEshortdate_1);
% %
% TLEshortdate_1_day = TLEshortdate_1(10:11);
% TLEshortdate_1_month = num2str(getMonthNum(TLEshortdate_1(6:8)));
% TLEshortdate_1_year = TLEshortdate_1(1:4);
% %
% TLEnextshortdate_1_day = TLEnextshortdate_1(10:11);
% TLEnextshortdate_1_month = num2str(getMonthNum(TLEnextshortdate_1(6:8)));
% TLEnextshortdate_1_year = TLEnextshortdate_1(1:4);
% 
% range_1 = strcat(TLEshortdate_1_year,'-',TLEshortdate_1_month,'-',TLEshortdate_1_day,'--', ...
%                TLEnextshortdate_1_year,'-',TLEnextshortdate_1_month,'-',TLEnextshortdate_1_day); % Example: '2003-10-29--2003-11-04'
% pyTLErange_1 = pyrun("tle_1 = st.tle(norad_cat_id=NORAD, epoch=range, iter_lines=False, format='tle', limit=100)", 'tle_1', NORAD=NORAD_1, range=range_1);
% TLErange_1 = split(py2mat(pyTLErange_1)); % split(string(py.str(pyTLErange_1)));
% 
% TLE_1 = filterTLE(TLErange_1,TLEday_1);

%% Object 2 with function getTLE
% NORAD_2 = str2double(conj{4}); % NORAD catalogue number of object 1
% DSE_2 = str2double(conj{6}); % Days Since Epoch (days <from the TLE used to compute the prediction> to <Time of closest Approach>)
% 
% TLE_2 = getTLE(TCAday,NORAD_2,DSE_2);

%% Object 2 without function
% NORAD_2 = str2double(conj{4}); % NORAD catalogue number of object 1
% DSE_2 = str2double(conj{6}); % Days Since Epoch (days <from the TLE used to compute the prediction> to <Time of closest Approach>)
% 
% TLEday_2 = TCAday - DSE_2; % Day of the TLE of the object 1
% TLEdate_2 = day2date(TLEday_2); % Date of the TLE of the object 1
% 
% TLEshortdate_2 = TLEdate_2(1:11);
% TLEnextshortdate_2 = getNextDay(TLEshortdate_2);
% %
% TLEshortdate_2_day = TLEshortdate_2(10:11);
% TLEshortdate_2_month = num2str(getMonthNum(TLEshortdate_2(6:8)));
% TLEshortdate_2_year = TLEshortdate_2(1:4);
% %
% TLEnextshortdate_2_day = TLEnextshortdate_2(10:11);
% TLEnextshortdate_2_month = num2str(getMonthNum(TLEnextshortdate_2(6:8)));
% TLEnextshortdate_2_year = TLEnextshortdate_2(1:4);
% 
% range_2 = strcat(TLEshortdate_2_year,'-',TLEshortdate_2_month,'-',TLEshortdate_2_day,'--', ...
%                TLEnextshortdate_2_year,'-',TLEnextshortdate_2_month,'-',TLEnextshortdate_2_day); % Example: '2003-10-29--2003-11-04'
% 
% pyTLErange_2 = pyrun("tle_2 = st.tle(norad_cat_id=NORAD, epoch=range, iter_lines=False, format='tle', limit=100)", 'tle_2', NORAD=NORAD_2, range=range_2);
% TLErange_2 = split(py2mat(pyTLErange_2)); % split(string(py.str(pyTLErange_2)))
% 
% TLE_2 = filterTLE(TLErange_2,TLEday_2);

%% Propagation (SGP4 for final state)
% [r1,v1] = propagate(TLE_1,TCAday);
% [r2,v2] = propagate(TLE_2,TCAday);
% 
% distance = norm(r2-r1); % [km]
% difference = abs(distance-str2double(conj{9})); % [km]
