function [TLE] = filterTLE(TLErange,TLEday)

k = 0;
for i=1:17:length(TLErange)-1 % go over all the TLEs in the TLErange
    k = k + 1;
    epoch = convertStringsToChars(TLErange(i+3)); % extract the epoch
    day = str2double(epoch(3:end)); % get the day of the year
    diff(k) = abs(TLEday - day); % compare with the TLEday
end

[~,I] = min(diff); % the minimum difference will be the desired index

TLE = TLErange( (I-1)*17+1 : I*17 );

end

