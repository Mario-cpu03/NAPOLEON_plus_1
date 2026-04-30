%% get_satellite_ecef_positions function
% This helper function extracts the satellite ECEF (earth-centered, earth-fixed)
% position vectors from the satelliteScenario object. 
% The result is stored in the satPositionECEF(:,s,t) tensor, 
% where s indicizes satellite and t indicizes the time.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. S : Satellite objects 
%
%       2. numtimeIndex:number of time samples in the simulation computed
%       from the simulation window parameters

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. satPositionECEF : array of size [3,numSats,numtimeIndex]
%       containing the ECEF position vector (x,y,z) of each satellite at each time
%       sample

function [satPositionECEF] = get_satellite_ecef_positions(S, numtimeIndex)
numSats = numel(S);

satPositionECEF = zeros(3, numSats, numtimeIndex);

for currentSat = 1:numSats
    % Extraction of the satellite position history in the Earth-fixed frame.
    satPosition = states(S(currentSat), "CoordinateFrame", "ecef");
    %Storage of the current satellite position history
    satPositionECEF(:,currentSat,:) = reshape(satPosition, [3,1,numtimeIndex]);
end

end