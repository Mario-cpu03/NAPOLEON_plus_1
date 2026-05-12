function Display_system_snapshot(simulationScenario, snapshotTime, visibilityData, sampleTime)

sats = simulationScenario.Satellites;
gss  = simulationScenario.GroundStations;

viewer = satelliteScenarioViewer(simulationScenario);
hideAll(viewer);

% Computing sample time index from snapshot
timeIdx = round(snapshotTime*60 / sampleTime) + 1;

% Safety check
if timeIdx < 1 || timeIdx > visibilityData.numTimeSteps
    error('Requested snapshotTime is outside the available visibilityData time window.');
end

% Compute actual target time shown by viewer
targetTime = simulationScenario.StartTime + seconds((timeIdx-1)*sampleTime);

% Force viewer to display the selected snapshot time
viewer.CurrentTime = targetTime;

% Satellites visible to at least one ground station/user
visibleSatIdx = unique([visibilityData.visibleSatIdx{timeIdx, :}]);

% Show ground stations
for currentGs = 1:numel(gss)
    %show(gss(currentGs), viewer);
    gss(currentGs).ShowLabel = true;
    gss(currentGs).LabelFontSize = 10;
end
show(gss, viewer);

% Show only visible satellites
for k = 1:numel(visibleSatIdx)
    satIdx = visibleSatIdx(k);

    show(sats(satIdx), viewer);
    sats(satIdx).ShowLabel = true;
    sats(satIdx).LabelFontSize = 10;

    show(orbit(sats(satIdx)), viewer);
    groundTrack(sats(satIdx));
end


%show(sats,viewer); show(orbit(sats),viewer);

% Create all access objects first, without showing them
accessObj = [];

for u = 1:numel(gss)

    userVisibleSatIdx = visibilityData.visibleSatIdx{timeIdx, u};

    for k = 1:numel(userVisibleSatIdx)

        satIdx = userVisibleSatIdx(k);

        newAccess = access(gss(u), sats(satIdx));
        accessObj = [accessObj; newAccess];

    end
end

% Show them all at once
if ~isempty(accessObj)
    show(accessObj, viewer);
end


end