%% 1. Scenario Setup
startTime = datetime(2026,06,07,19,08,00); 
stopTime = startTime + hours(3);            
sampleTime = 60;                           % 60-second discrete steps
sc = satelliteScenario(startTime,stopTime,sampleTime,"AutoSimulate",false);

% Load your Starlink Shell 2 constellation from TLE
tleFileName = 'starlink_shell2.tle';
sat = satellite(sc, tleFileName); 
numSatellites = numel(sat); 

% Set up Ground Station (Source)
gsSource = groundStation(sc, 45.0652, 7.6583, "Name", "Source Ground Station");

% Define Flight Trajectory between Torino and Milano Malpensa (Target)
% Coordinates: Torino LLA (~45.07, 7.68) to Malpensa LLA (~45.63, 8.72)
startLLA = [45.0700, 7.6800, 8000];       % Latitude, Longitude, Altitude (meters)
endLLA   = [45.6300, 8.7200, 8000];
timeOfTravel = [0, 3*3600];                % Spanned across the 3-hour scenario duration (seconds)

flightTrajectory = geoTrajectory([startLLA; endLLA], timeOfTravel);
gsTarget = platform(sc, flightTrajectory, "Name", "Flight Target");

% Calculate the scenario state corresponding to StartTime.
advance(sc);

%% 2. Routing Algorithm Execution
[~,elSourceToSat] = aer(gsSource,sat);
[~,elTargetToSat] = aer(gsTarget,sat);
elSourceToSatGreaterThanOrEqual25 = (elSourceToSat >= 25)';
elTargetToSatGreaterThanOrEqual25 = (elTargetToSat >= 25)';

trueID = find(elSourceToSatGreaterThanOrEqual25);
if isempty(trueID)
    error('No satellites are currently visible from the Source Ground Station above 25°.');
end

[~,~,r] = aer(sat(trueID), gsTarget);
[~,minRangeID] = min(r);
id = trueID(minRangeID);

% Initialize path tracking
nodes = {gsSource, sat(id)};
visitedSats = false(1, numSatellites); % Keep track of visited satellites to avoid loops
visitedSats(id) = true;

minSatElevation = -15; % degrees
pathFound = false;
maxHops = 15;          % Safety break to avoid infinite loops
hopCount = 0;

while ~pathFound && hopCount < maxHops
    hopCount = hopCount + 1;
    idCurrent = id;
    
    % If current satellite can see the target flight, we are done
    if elTargetToSatGreaterThanOrEqual25(idCurrent)
        nodes{end+1} = gsTarget; 
        pathFound = true;
        continue
    end
    
    % Check elevation angles to all other satellites
    [~,els] = aer(sat(idCurrent), sat); 
    
    % Filter out current satellite and already visited satellites
    els(idCurrent) = -90; 
    els(visitedSats) = -90; 
    
    validSatIDs = find(els >= minSatElevation);
    
    if isempty(validSatIDs)
        warning('Routing failed: Dead end reached. No valid next-hop satellites.');
        break;
    end
    
    % Find the one closest to the target flight
    [~,~,r] = aer(sat(validSatIDs), gsTarget);
    [~,minRangeID] = min(r);
    id = validSatIDs(minRangeID);
    
    % Update tracking
    visitedSats(id) = true;
    nodes{end+1} = sat(id); 
end

%% 3. Visualization and Analysis
if pathFound
    fprintf('Path successfully found with %d hops!\n', numel(nodes)-1);
    
    % Enable AutoSimulate so visualization updates correctly over time
    sc.AutoSimulate = true; 
    
    % Link the hops sequentially
    ac = cell(1, numel(nodes)-1);
    for i = 1:numel(nodes)-1
        ac{i} = access(nodes{i}, nodes{i+1});
        ac{i}.LineColor = "red";
        ac{i}.LineWidth = 2; % Make it more visible
    end
    
    % Display access intervals for the first hop as an example
    intvls = accessIntervals(ac{1});
    disp(intvls);
    
    % Open Viewer
    v = satelliteScenarioViewer(sc, "ShowDetails", false);
    
    % Add a 3D model to make the aircraft visible in the viewer
    gsTarget.Visual3DModel = "NarrowBodyAirliner.glb"; 
    
    play(sc);
else
    error('Could not compute a valid path to the target.');
end