%% Filtered_satellite function
% This function computes the time-evolution filtering of the full
% constellation. The goal is determine, for each time step and
% for each ground station, the set of satellites that are visible above a
% prescribed elevation threshold, which is in compliance with the 
% FCC 21-48 directives.
% The main idea is to make the expensive visibility computation via a numerical 
% ECEF-based engine, avoiding repeated calls to aer().
%
% The output is a time-indexed data structure containing:
%       (i) the simulation time vector,
%       (ii) the visible satellites for each user at each time step,
%       (iii) the corresponding elevation angles,
%       (iv) the corresponding slant distances.
%
% IMPORTANT:
% The function assumes that the input satelliteScenario object already
% contains both Satellite objects and GroundStation objects.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. simulationScenario : satelliteScenario object of the toolbox
%       containing the full constellation and the ground stations
%
%       2. minimumElev : minimum elevation threshold [deg] used to decide
%       whether a satellite is visible or not at a given time step

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. visibilityData : Data Structure containing the dynamic
%       visibility information:
%                   (i) timeVec : row vector of simulation times
%                   (ii) visibleSatIdx : cell array of size [T,U], where
%                         each cell contains the indices of the satellites
%                         visible to user u at time step t
%                   (iii) elevationDeg : cell array of size [T,U], where
%                         each cell contains the elevations of the visible
%                         satellites
%                   (iv)distanceKm : cell array of size [T,U], where each
%                         cell contains the slant distances of the visible
%                         satellites
%                   (v) visibilityMask : logical array of size [U,S,T]
%                   (vi) elevationMatrix : array of size [U,S,T]
%                   (vii) distanceMatrix : array of size [U,S,T]
%                   (viii) numUsers : number of ground stations
%                   (ix)numSats : number of satellites
%                   (x) numTimeSteps : number of time samples


%% %% %% AN IMPORTANT NOTE %% %% %%
%% AT THE MOMENT, THE FUNCTION HERE DESCRIBED DEFINES THE visibilityData DATA 

%%STRUCTURE IN ORDER TO CONTAIN BOTH MATRIX BASED AND CELL-LIKE DATA. 
%%NAMELY, THE visibilityMask, elevationMatrix AND distanceMatrix ARE DENSE MATRIX
%%WHOSE USAGE IS MORE SUITABLE BYMEANS OF ASSOCIATION PROBELM SOLUTIONS. 
%%ON THE OTHER HAND, THE visibleSatIdx, elevationDeg, AND distanceKm ARE 
%%CELLs CONTAINING, FOR EACH TIME SAMPLE A SET OF VALUES REFERING TO THE {time, user}
%%PAIR ORDERED WITH RESPECT TO THE SATELLITES AVAILABLE THROUGH THE INDICIZATION visibleSatIdx{time, user}

%%FOR THIS VERY REASON, IT MAY BE MORE THAN PLAUSIBLE THAT ONLY THE CELL LIKE STRUCTURES
%%WILL HAVE AN ACTUAL RELEVANCE AS THEY REPRESENT A per-link EVALUATION.

%%HOEVER, THE MATRICES WILL BE KEPT FOR THE MOMENT, AS THEY MAY BECOME USEFUL IN FUTURE.


function [visibilityData] = Filter_constellation(simulationScenario, minimumElev)

%%Retrieval of the objects already stored in the scenario
S = simulationScenario.Satellites; numSats = numel(S);
Gs = simulationScenario.GroundStations; numGs = numel(Gs);

%%Time vector construction
timeVec = simulationScenario.StartTime : seconds(simulationScenario.SampleTime) : simulationScenario.StopTime; timeIndex = numel(timeVec);

%%Preallocation of the output data structures
visibleSatIdx = cell(timeIndex, numGs);
elevationDeg  = cell(timeIndex, numGs);
distanceKm    = cell(timeIndex, numGs);

% Dense matrices are useful? The matrix convention is:
%       dimension 1 -> users
%       dimension 2 -> satellites
%       dimension 3 -> time samples
visibilityMask  = false(numGs, numSats, timeIndex);
elevationMatrix = NaN(numGs, numSats, timeIndex);
distanceMatrix  = NaN(numGs, numSats, timeIndex);

% Extraction of satellite ECEF positions
% satPositionECEF has size: 3 x numSats x numTimeSteps
% each "first dimension" represents an axis (x,y,z)
satPositionECEF = get_satellite_ecef_positions(S, timeIndex);

% Extraction of ground station ECEF positions in a similar way to satPositionECEF, 
% but for the user, which is stationary. Thus, the size neglects 
% time evloution: 3 x numUsers
userPositionECEF = get_groundstation_ecef_positions(Gs);

%% Dynamic visibility computation
for currentTimeIdx = 1:timeIndex

    % Every satellite' position at the current time step: 3 x numSats
    satPositionCurrent = satPositionECEF(:,:,currentTimeIdx);

    for currentUser = 1:numGs

        % Current user ECEF position: 3 x 1
        userPositionCurrent = userPositionECEF(:,currentUser);

        % Numerical computation of elevation and slant distance between the
        % current user and all satellites at the current time step.
        [elevationCurrent, slantCurrentKm] = compute_visibility_snapshot( ...
            satPositionCurrent, ...
            userPositionCurrent);

        % Check the visibility wioth the threshold for the current
        currentVisibilityMask = elevationCurrent >= minimumElev;

        % Visible satellite indices for the current user and time step
        currentVisibleSatIdx = find(currentVisibilityMask);

        %visibilityMask(currentUser,:,currentTimeIdx) = currentVisibilityMask;
        %elevationMatrix(currentUser,:,currentTimeIdx) = elevationCurrent;
        %distanceMatrix(currentUser,:,currentTimeIdx) = slantCurrentKm;

        %Cell
        visibleSatIdx{currentTimeIdx,currentUser} = currentVisibleSatIdx;
        elevationDeg{currentTimeIdx,currentUser} = elevationCurrent(currentVisibleSatIdx);
        distanceKm{currentTimeIdx,currentUser} = slantCurrentKm(currentVisibleSatIdx);

    end
end

% Building the actual output structure
visibilityData.timeVec = timeVec;

%%CURRENTLY RELEVANT PUTPUT
visibilityData.visibleSatIdx = visibleSatIdx;
visibilityData.elevationDeg = elevationDeg;
visibilityData.distanceKm = distanceKm;

%%FUTURE-PROOF OUTPUT
%visibilityData.visibilityMask = visibilityMask;
%visibilityData.elevationMatrix = elevationMatrix;
%visibilityData.distanceMatrix = distanceMatrix;

visibilityData.numUsers = numGs;
visibilityData.numSats = numSats;
visibilityData.numTimeSteps = timeIndex;

end

