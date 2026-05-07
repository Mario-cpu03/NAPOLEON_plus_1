%% Display_system_snapshot function
% This function opens the satelliteScenario viewer, creates the access
% objects between all ground stations and satellites, and visualizes the
% whole system at a selected time instant.

function [viewer, accessObj] = Display_system_snapshot(simulationScenario, snapshotTime)

% Retrieve scenario objects
sats = simulationScenario.Satellites;
gss  = simulationScenario.GroundStations;

% Create viewer
viewer = satelliteScenarioViewer(simulationScenario);

% Show labels
for currentSat = 1:numel(sats)
    sats(currentSat).ShowLabel = true;
    sats(currentSat).LabelFontSize = 10;
end

for currentGs = 1:numel(gss)
    gss(currentGs).ShowLabel = true;
    gss(currentGs).LabelFontSize = 10;
end

% Show orbits
show(orbit(sats));

% Create access objects between every ground station and every satellite
accessObj = access(gss, sats);

% Play scenario up to the desired instant
play(simulationScenario);

% Wait until the desired time is reached
while simulationScenario.SimulationTime < snapshotTime
    pause(0.1);
end

% Pause the scenario at the requested instant
pause(simulationScenario);

end