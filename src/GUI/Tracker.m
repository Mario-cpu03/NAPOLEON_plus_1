%% 1. Scenario Setup
startTime = datetime(2026,05,13,18,27,57); 
stopTime = startTime + hours(3);            
sampleTime = 60;                           % 60-second discrete steps
sc = satelliteScenario(startTime,stopTime,sampleTime,"AutoSimulate",false);

% Load your Starlink Shell 2 constellation from TLE
tleFileName = 'starlink_shell2.tle';
sat = satellite(sc, tleFileName); 
numSatellites = numel(sat); 

% Set up Ground Stations
gsSource = groundStation(sc, 45.0652, 7.6583, "Name", "Source Ground Station");
gsTarget = groundStation(sc, 17.4351, 78.3824, "Name", "Target Ground Station");

% Calculate the scenario state corresponding to StartTime.
advance(sc);

% Retrieve the elevation angle of each satellite with respect to the ground
% stations.
[~,elSourceToSat] = aer(gsSource,sat);
[~,elTargetToSat] = aer(gsTarget,sat);

% Determine the elevation angles that are greater than or equal to 25
% degrees.
elSourceToSatGreaterThanOrEqual25 = (elSourceToSat >= 25)';
elTargetToSatGreaterThanOrEqual25 = (elTargetToSat >= 25)';

% Find the indices of the elements of elSourceToSatGreaterThanOrEqual25
% whose value is true.
trueID = find(elSourceToSatGreaterThanOrEqual25 == true);

% These indices are essentially the indices of satellites in sat whose
% elevation angle with respect to "Source Ground Station" is at least 25
% degrees. Determine the range of these satellites to "Target Ground
% Station".
[~,~,r] = aer(sat(trueID), gsTarget);

% Determine the index of the element in r bearing the minimum value.
[~,minRangeID] = min(r);

% Determine the element in trueID at the index minRangeID.
id = trueID(minRangeID);

% This is the index of the best satellite for initial access to the
% constellation. This will be the first hop in the path. Initialize a
% variable 'node' that stores the first two nodes of the routing - namely,
% "Source Ground Station" and the best satellite for initial constellation
% access.
nodes = {gsSource sat(id)};

% Minimum elevation angle of satellite nodes with respect to the prior
% node.
minSatElevation = -15; % degrees

% Flag to specify if the complete multi-hop path has been found.
pathFound = false;

% Determine nodes of the path in a loop. Exit the loop once the complete
% multi-hop path has been found.
while ~pathFound
    % Index of the satellite in sat corresponding to current node is
    % updated to the value calculated as index for the next node in the
    % prior loop iteration. Essentially, the satellite in the next node in
    % prior iteration becomes the satellite in the current node in this
    % iteration.
    idCurrent = id;

    % This is the index of the element in elTargetToSatGreaterThanOrEqual25
    % tells if the elevation angle of this satellite is at least 25 degrees
    % with respect to "Target Ground Station". If this element is true, the
    % routing is complete, and the next node is the target ground station.
    if elTargetToSatGreaterThanOrEqual25(idCurrent)
        nodes = {nodes{:} gsTarget}; %#ok<CCAT> 
        pathFound = true;
        continue
    end

    % If the element is false, the path is not complete yet. The next node
    % in the path must be determined from the constellation. Determine
    % which satellites have elevation angle that is greater than or equal
    % to -15 degrees with respect to the current node. To do this, first
    % determine the elevation angle of each satellite with respect to the
    % current node.
    [~,els] = aer(sat(idCurrent),sat); 

    % Overwrite the elevation angle of the satellite with respect to itself
    % to be -90 degrees to ensure it does not get re-selected as the next
    % node.
    els(idCurrent) = -90; 

    % Determine the elevation angles that are greater than or equal to -15
    % degrees.
    s = els >= minSatElevation;

    % Find the indices of the elements in s whose value is true.
    trueID = find(s == true);

    % These indices are essentially the indices of satellites in sat whose
    % elevation angle with respect to the current node is greater than or
    % equal to -15 degrees. Determine the range of these satellites to
    % "Target Ground Station".
    [~,~,r] = aer(sat(trueID), gsTarget);

    % Determine the index of the element in r bearing the minimum value.
    [~,minRangeID] = min(r);

    % Determine the element in trueID at the index minRangeID.
    id = trueID(minRangeID);

    % This is the index of the best satellite among those in sat to be used
    % for the next node in the path. Append this satellite to the 'nodes'
    % variable.
    nodes = {nodes{:} sat(id)}; %#ok<CCAT>
end

sc.AutoSimulate = true;

ac = access(nodes{:});
ac.LineColor = "red";

intvls = accessIntervals(ac)

v = satelliteScenarioViewer(sc,"ShowDetails",false);
    play(sc)