%% get_groundstation_ecef_positions function
% This helper function extracts the latitude and longitude of each
% GroundStation object and converts them into ECEF coordinates.
%
% The current implementation uses a spherical Earth approximation. This is
% sufficient for fast candidate filtering, but it should be validated
% against aer() on a reduced number of samples.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. Gs :GroundStation objects

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. userPositionECEF : array of size [3,numUsers] containing the
%       ECEF position vector of each ground station

function [userPositionECEF] = get_groundstation_ecef_positions(Gs)

end