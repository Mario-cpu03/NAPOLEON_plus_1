function elevIdx = elevation_to_idx(thetaDeg)
% creating different ekevation indeces. The scope is to perform two tasks in
% a signle simple file: 
%       (i) quantizing the elevations 
%       (ii) align the elevation angles to the indicization standard 
%       adopted by  the channel bank
if thetaDeg < 25
    elevIdx = NaN;

elseif thetaDeg < 37.5
    elevIdx = 1;      % 30 deg

elseif thetaDeg < 52.5
    elevIdx = 2;      % 45 deg

elseif thetaDeg < 65
    elevIdx = 3;      % 60 deg

else
    elevIdx = 4;      % 70 deg

end

end