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
addpath(genpath('SGP4_2.1.0\SGP4_Vectorized')); % SGP4: final state || SGP4_Vectorized: one state per timestep

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
Nranges = 1; % (0,1], (1,2], ..., (Nranges-1, Nranges]
Nsamples = 1;
result_r = NaN(Nranges,Nsamples);
result_v = NaN(Nranges,Nsamples);
names = cell(Nranges,Nsamples,2);
result_t = NaN(Nranges,Nsamples);

% Range loop
for r = 1:Nranges
    r
    % Loop over all data
    i = 0;
    samples_count = 1
    while i<length(data) && samples_count<=Nsamples
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
                % Propagation (SGP4 vectorized)
                step = 5; %[min]
                margin = 60; %[min]
                [r1_vec,v1_vec,doy1] = propagate_vec(TLE_1,TCAday,step,margin);
                [r2_vec,v2_vec,doy2] = propagate_vec(TLE_2,TCAday,step,margin);
                
                % Equate vector lengths, erasing the first components of the larger vector to match the length of the shorter vector
                length1 = size(r1_vec,2);
                length2 = size(r2_vec,2);
                d_length = abs(length2-length1);
                if length1 < length2
                    length = length1;
                    r2_vec = r2_vec(:,d_length+1:end);
                    v2_vec = v2_vec(:,d_length+1:end);
                    doy = doy1;
                elseif length2 < length1
                    length = length2;
                    r1_vec = r1_vec(:,d_length+1:end);
                    v1_vec = v1_vec(:,d_length+1:end);
                    doy = doy2;
                end

                TCAidx = length - margin/step; % where the SOCRATES TCA is in the array
                distances = sqrt(sum((r1_vec - r2_vec).^2, 1));
                [minDist,minDist_idx] = min(distances); % where the propagated TCA is in the array
                minDist_day = (doy + minDist_idx*step/(24*60)); %[days]
                diff_day = minDist_day - TCAday; %[days] time difference between the SOCRATES and propagated TCAs
                result_t(r,samples_count) = diff_day; %[days]

                comp_r = abs(minDist-str2double(conj{9})); %[km]
                result_r(r,samples_count) = comp_r; %[km]

                rel_vels = sqrt(sum((v1_vec - v2_vec).^2, 1)); %[km/s]
                rel_vel = rel_vels(minDist_idx); %[km/s]
                comp_v = abs(rel_vel-str2double(conj{10})); %[km/s]
                result_v(r,samples_count) = comp_v; %[km/s]

                names{r,samples_count,1} = conj{2};
                names{r,samples_count,2} = conj{5};

                samples_count = samples_count + 1;
                samples_count
            end
        end
    end
end