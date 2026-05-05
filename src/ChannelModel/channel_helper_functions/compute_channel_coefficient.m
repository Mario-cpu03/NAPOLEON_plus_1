function [channelGainTensor, channelStateTensor, distanceTensor, elevationTensor, validLinkMask] = ...
    compute_channel_coefficient(configChannel, visibilityData, groundEnv)

% Constants
c = 3e8;
lambda = c/configChannel.carrierFrequency;

% Dimensions
numUsers     = visibilityData.numUsers;
numSats      = visibilityData.numSats;
numTimeSteps = visibilityData.numTimeSteps;

% Input cell structures
visibleSatIdx = visibilityData.visibleSatIdx;   % [T x U]
elevationDeg  = visibilityData.elevationDeg;    % [T x U]
distanceKm    = visibilityData.distanceKm;      % [T x U]

% Output tensors
channelGainTensor  = zeros(numUsers, numSats, numTimeSteps);
channelStateTensor = NaN(numUsers, numSats, numTimeSteps);
distanceTensor     = NaN(numUsers, numSats, numTimeSteps);
elevationTensor    = NaN(numUsers, numSats, numTimeSteps);
validLinkMask      = false(numUsers, numSats, numTimeSteps);

% -------------------------------------------------------------------------
% Step 1:
% Build visible histories per user-satellite pair.
% -------------------------------------------------------------------------
visibleTimeList = cell(numUsers, numSats);
visibleElevList = cell(numUsers, numSats);
visibleDistList = cell(numUsers, numSats);

for currentTimeIdx = 1:numTimeSteps

    for currentUser = 1:numUsers

        currentVisibleSatIdx = visibleSatIdx{currentTimeIdx,currentUser};

        if isempty(currentVisibleSatIdx)
            continue;
        end

        currentElevationDeg = elevationDeg{currentTimeIdx,currentUser};
        currentDistanceKm   = distanceKm{currentTimeIdx,currentUser};

        for k = 1:numel(currentVisibleSatIdx)

            currentSat = currentVisibleSatIdx(k);

            visibleTimeList{currentUser,currentSat}(end+1) = currentTimeIdx;
            visibleElevList{currentUser,currentSat}(end+1) = currentElevationDeg(k);
            visibleDistList{currentUser,currentSat}(end+1) = currentDistanceKm(k);

        end
    end
end

% -------------------------------------------------------------------------
% Step 2:
% Create one LMS fading sequence per visible user-satellite pair.
% -------------------------------------------------------------------------
for currentUser = 1:numUsers

    currentEnv = groundEnv(currentUser);%map_environment_to_p681(groundEnv(currentUser));

    for currentSat = 1:numSats

        timeIdxList = visibleTimeList{currentUser,currentSat};

        if isempty(timeIdxList)
            continue;
        end

        elevationSeqDeg = visibleElevList{currentUser,currentSat};
        distanceSeqKm   = visibleDistList{currentUser,currentSat};

        numVisibleSamples = numel(timeIdxList);

        % p681LMSChannel requires a scalar ElevationAngle for the sequence.
        % Here we use a representative elevation for this specific pair.
        representativeElevationDeg = mean(elevationSeqDeg);

        lmsChannel = p681LMSChannel( ...
            'CarrierFrequency', configChannel.carrierFrequency, ...
            'Environment',      currentEnv, ...
            'MobileSpeed',      configChannel.mobileSpeed, ...
            'SampleRate',       configChannel.sampleRate, ...
            'ElevationAngle',   representativeElevationDeg);

        txSignal = ones(numVisibleSamples, 1);

        [~, pathGainsComplex, ~, stateSequence] = lmsChannel(txSignal);
        %TESTdisp(unique(stateSequence).');
        release(lmsChannel);

        fadingGainLinear = abs(pathGainsComplex(:)).^2;

        distanceSeqM = distanceSeqKm(:)*1e3;

        fsplGainLinear = (lambda ./ (4*pi.*distanceSeqM)).^2;

        totalGainLinear = fsplGainLinear .* fadingGainLinear;

        channelGainTensor(currentUser,currentSat,timeIdxList) = ...
            reshape(totalGainLinear, 1, 1, []);

        channelStateTensor(currentUser,currentSat,timeIdxList) = ...
            reshape(stateSequence, 1, 1, []);

        distanceTensor(currentUser,currentSat,timeIdxList) = ...
            reshape(distanceSeqM, 1, 1, []);

        elevationTensor(currentUser,currentSat,timeIdxList) = ...
            reshape(elevationSeqDeg, 1, 1, []);

        validLinkMask(currentUser,currentSat,timeIdxList) = true;

    end
end

end