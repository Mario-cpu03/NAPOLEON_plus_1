%% compute_visibility_snapshot function
% This helper function computes the elevation angle and slant distance
% between one ground station and all satellites at a given time step.
%
% The computation is performed in ECEF coordinates. The elevation angle is
% computed from the angle between the line-of-sight unit vector and the
% local zenith unit vector.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. satPositionCurrent : matrix of size [3,numSats] containing the
%       ECEF position vectors of all satellites at the current time step
%
%       2. userPositionCurrent : column vector of size [3,1] containing the
%       ECEF position vector of the current user

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. elevationCurrent : row vector of size [1,numSats] containing the
%       elevation angle [deg] of each satellite with respect to the user
%
%       2. distanceCurrentKm : row vector of size [1,numSats] containing the
%       slant distance [km] of each satellite with respect to the user

function [elevationCurrent, distanceCurrentKm] = compute_visibility_snapshot(satPositionCurrent, userPositionCurrent)


end