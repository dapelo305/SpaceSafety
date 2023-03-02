function [TLE,flag] = getTLE(TCAday,NORAD,DSE)

TLEday = TCAday - DSE; % Day of the TLE of the object 1
TLEdate = day2date(TLEday); % Date of the TLE of the object 1

TLEshortdate = TLEdate(1:11);
TLEnextshortdate = getNextDay(TLEshortdate);
%
TLEshortdate_day = TLEshortdate(10:11);
TLEshortdate_month = num2str(getMonthNum(TLEshortdate(6:8)));
TLEshortdate_year = TLEshortdate(1:4);
%
TLEnextshortdate_day = TLEnextshortdate(10:11);
TLEnextshortdate_month = num2str(getMonthNum(TLEnextshortdate(6:8)));
TLEnextshortdate_year = TLEnextshortdate(1:4);

range = strcat(TLEshortdate_year,'-',TLEshortdate_month,'-',TLEshortdate_day,'--', ...
               TLEnextshortdate_year,'-',TLEnextshortdate_month,'-',TLEnextshortdate_day); % Example: '2003-10-29--2003-11-04'
pyTLErange = pyrun("tle = st.tle(norad_cat_id=NORAD, epoch=range, iter_lines=False, format='tle', limit=100)", 'tle', NORAD=NORAD, range=range);
TLErange = split(py2mat(pyTLErange)); % split(string(py.str(pyTLErange_1)));

% Check if the obtained TLE is valid (number of components must be multiple of 17)
if mod(length(TLErange)-1, 17) == 0
    TLE = filterTLE(TLErange,TLEday);
    flag = 1;
else
    TLE = NaN;
    flag = 0;
end



end

