function nextDay = getNextDay(currentDay)
% This function takes a date string in format "yyyy mmm dd" and returns the
% date of the next day in the same format.

% Convert the input string to a date number
dateNum = datenum(currentDay,'yyyy mmm dd');

% Add one day to the date number
nextDayNum = dateNum + 1;

% Convert the date number of the next day to a date string
nextDay = datestr(nextDayNum, 'yyyy mmm dd');
end
