function dateStr = day2date(dayOfYear)

% Get year
year = 2023;

% Get start of year
startOfYear = datetime(year,1,1);

% Calculate number of days since start of year
numDays = floor(dayOfYear);
fracDay = dayOfYear - numDays;

% Get date from number of days
dateVal = startOfYear + days(numDays - 1) + hours(24)*fracDay;

% Format date as string
dateStr = datestr(dateVal, 'yyyy mmm dd HH:MM:SS.FFF');

end
