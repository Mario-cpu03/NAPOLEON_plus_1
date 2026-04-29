%% geodetic_to_ecef_spherical function
% This helper function converts geodetic latitude and longitude into ECEF
% coordinates by using a spherical Earth approximation.
%
% The altitude of the ground station is assumed to be zero.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. latDeg : geodetic latitude [deg]
%       2. lonDeg : geodetic longitude [deg]

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. rECEF : ECEF position vector [m]

function [rECEF] = geodetic_to_ecef_spherical(latDeg, lonDeg)
earthRadius = 6371e3;
latRad = deg2rad(latDeg);
lonRad = deg2rad(lonDeg);

x = earthRadius*cos(latRad)*cos(lonRad);
y = earthRadius*cos(latRad)*sin(lonRad);
z = earthRadius*sin(latRad);

rECEF = [x; y; z];

end