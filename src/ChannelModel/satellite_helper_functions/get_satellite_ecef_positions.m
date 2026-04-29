%% get_satellite_ecef_positions function
% This helper function extracts the satellite ECEF position vectors from the
% satelliteScenario object. The result is stored in the satPositionECEF(:,s,t)
% tensor, where s indicizes satellite and t indicizes the time.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. S : Satellite objects 
%
%       2. numTimeSteps:number of time samples in the simulation computed
%       from the simulation window parameters

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. satPositionECEF : array of size [3,numSats,numTimeSteps]
%       containing the ECEF position vector of each satellite at each time
%       sample

function [satPositionECEF] = get_satellite_ecef_positions(S, numTimeSteps)
numSats = numel(S);

satPositionECEF = zeros(3, numSats, numTimeSteps);

for currentSat = 1:numSats
    % Extraction of the satellite position history in the Earth-fixed frame.
    satPosition = states(S(currentSat), "CoordinateFrame", "ecef");
    %Storage of the current satellite position history
    satPositionECEF(:,currentSat,:) = reshape(satPosition, [3,1,numTimeSteps]);
end

end