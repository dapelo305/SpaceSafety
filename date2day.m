function dayOfYear = date2day(dateStr)

% Convert input date string to datetime format
dateVal = datetime(dateStr,'InputFormat','yyyy MMM dd HH:mm:ss.SSS'); % yyyy MMM dd HH:mm:ss.SSS

% Get start of year
startOfYear = datetime(dateVal.Year,1,1); % 01-Jan-2023

% Calculate number of days since start of year
dayOfYear = days(dateVal - startOfYear) + 1;

end

