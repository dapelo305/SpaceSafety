function monthNum = getMonthNum(monthName)
% This function takes as input the abbreviated name of a month and returns
% the corresponding two digit number from 01 to 12.

% Define a cell array of the abbreviated month names and their corresponding
% numbers.
abbrevs = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
nums = {'01', '02', '03', '04', '05', '06', ...
        '07', '08', '09', '10', '11', '12'};

% Find the index of the input month name in the cell array of abbreviations.
index = find(strcmpi(monthName, abbrevs));

% Check if the index was found (i.e., if the input month name is valid).
if isempty(index)
    error('Invalid month name.');
end

% Return the corresponding number.
monthNum = nums{index};

end
