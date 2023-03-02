function [r_vec,v_vec,doy] = propagate_vec(TLE,TCAday,step,margin)

format long g

ge = 398600.8; % Earth gravitational constant [km3/s2]
TWOPI = 2*pi;
MINUTES_PER_DAY = 1440;
MINUTES_PER_DAY_SQUARED = (MINUTES_PER_DAY * MINUTES_PER_DAY);
MINUTES_PER_DAY_CUBED = (MINUTES_PER_DAY * MINUTES_PER_DAY_SQUARED);

% Read first line
Cnum = TLE{2}(1:end-1);                     % Catalog number (NORAD)
SC = TLE{2}(end);                           % Security classification
ID = TLE{3};                                % Identification number
year = str2double(TLE{4}(1:2));             % Year
doy = str2double(TLE{4}(3:end));            % Day of year
epoch = str2double(TLE{4});                 % Epoch
TD1 = str2double(TLE{5});                   % 1st time derivative
TD2 = str2double(TLE{6}(1:end-2));          % 2nd time derivative
ExTD2 = str2double(TLE{6}(end-1:end));      % Exponent of 2nd time derivative
BStar = str2double(TLE{7}(1:end-2));        % Bstar/drag Term
ExBStar = str2double(TLE{7}(end-1:end));    % Exponent of Bstar/drag Term
BStar = BStar*1e-5*10^ExBStar;
Etype = str2double(TLE{8});                 % Ephemerides type
Enum = str2double(TLE{9});                  % Element number

% Read second line
i = str2double(TLE{12});                    % Orbit inclination (degrees)
raan = str2double(TLE{13});                 % Right Ascension of Ascending Node (degrees)
e = str2double(strcat('0.',TLE{14}));       % Eccentricity
omega = str2double(TLE{15});                % Argument of perigee (degrees)
M = str2double(TLE{16});                    % Mean anomaly (degrees)
no = str2double(TLE{17}(1:11));             % Mean motion
a = (ge/(no*2*pi/86400)^2 )^(1/3);          % Semi-major axis (km)
rNo = str2double(TLE{17}(12:end));          % Revolution number at epoch

% sat data
satdata.epoch = epoch;
satdata.norad_number = Cnum;
satdata.bulletin_number = ID;
satdata.classification = SC; % almost always 'U'
satdata.revolution_number = rNo;
satdata.ephemeris_type = Etype;
satdata.xmo = M * (pi/180);
satdata.xnodeo = raan * (pi/180);
satdata.omegao = omega * (pi/180);
satdata.xincl = i * (pi/180);
satdata.eo = e;
satdata.xno = no * TWOPI / MINUTES_PER_DAY;
satdata.xndt2o = TD1 * TWOPI / MINUTES_PER_DAY_SQUARED;
satdata.xndd6o = TD2 * 10^ExTD2 * TWOPI / MINUTES_PER_DAY_CUBED;
satdata.bstar = BStar;

tspan = 1:step:floor((TCAday-doy)*24*60) + margin; %[min] +margin in case the closest approach happens after the SOCRATES TCA

[r_vec,v_vec] = sgp4(tspan,satdata);

end