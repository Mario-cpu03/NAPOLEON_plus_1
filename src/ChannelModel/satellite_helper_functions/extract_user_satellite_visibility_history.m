
%% extract_user_satellite_visibility_history function
% This helper extracts the time history of visibility, elevation and
% distance for one fixed user-satellite pair from the cell-based
% visibilityData structure.

function [linkHistory] = extract_user_satellite_visibility_history( ...
    visibilityData, ...
    userIdx, ...
    satIdx)

numTimeSteps = visibilityData.numTimeSteps;

timeIdxList = [];
elevationDegList = [];
distanceKmList = [];

for currentTimeIdx = 1:numTimeSteps

    currentVisibleSatIdx = visibilityData.visibleSatIdx{currentTimeIdx,userIdx};

    localIdx = find(currentVisibleSatIdx == satIdx, 1);

    if isempty(localIdx)
        continue;
    end

    timeIdxList(end+1) = currentTimeIdx;

    elevationDegList(end+1) = visibilityData.elevationDeg{currentTimeIdx,userIdx}(localIdx);
    distanceKmList(end+1)   = visibilityData.distanceKm{currentTimeIdx,userIdx}(localIdx);

end

linkHistory.userIdx = userIdx;
linkHistory.satIdx = satIdx;

linkHistory.timeIdx = timeIdxList;
linkHistory.timeVec = visibilityData.timeVec(timeIdxList);

linkHistory.elevationDeg = elevationDegList;
linkHistory.distanceKm = distanceKmList;

linkHistory.numVisibleSamples = numel(timeIdxList);

end