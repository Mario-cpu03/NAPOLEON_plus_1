function Plot_average_quant(snapshotTime, visibilityData, USER_SAT_evolution, sampleTime, userIdx)

% Computing sample time index from snapshot
timeIdx = round(snapshotTime*60 / sampleTime) + 1;

% Safety check
if timeIdx < 1 || timeIdx > visibilityData.numTimeSteps
    error('Requested snapshotTime is outside the available visibilityData time window.');
end

%% NUMBER OF VISIBLE SATELLITES PER USER

numVisiblePerUser = zeros(1, visibilityData.numUsers);

for u = 1:visibilityData.numUsers
    numVisiblePerUser(u) = numel(visibilityData.visibleSatIdx{timeIdx, u});
end

figure("Color",'w');
bar(1:visibilityData.numUsers, numVisiblePerUser);
yline(mean(numVisiblePerUser), ...
    '--r', ...
    sprintf('Average visible satellites = %.2f', mean(numVisiblePerUser)), ...
    'LineWidth', 3.5, ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom', ...
    'FontSize', 10, ...
    'FontWeight', 'bold');
xlabel('User / Ground Station index');
ylabel('Number of visible satellites');
title(sprintf('Visible satellites per user at t = %.1f min', snapshotTime));
grid on;


%% NUMBER OF VISIBLE USERS PER SATELLITE

numUsersPerSat = zeros(1, visibilityData.numSats);

for u = 1:visibilityData.numUsers
    userVisibleSatIdx = visibilityData.visibleSatIdx{timeIdx, u};

    for k = 1:numel(userVisibleSatIdx)
        satIdx = userVisibleSatIdx(k);
        numUsersPerSat(satIdx) = numUsersPerSat(satIdx) + 1;
    end
end

figure("Color",'w');
bar(1:visibilityData.numSats, numUsersPerSat);
yline(mean(numUsersPerSat), ...
    '--r', ...
    sprintf('Average visible satellites = %.2f', mean(numUsersPerSat)), ...
    'LineWidth', 3.5, ...
    'LabelHorizontalAlignment', 'left', ...
    'LabelVerticalAlignment', 'bottom', ...
    'FontSize', 8, ...
    'FontWeight', 'bold');
xlabel('Satellite index');
ylabel('Number of visible users');
title(sprintf('Visible users per satellite at t = %.1f min', snapshotTime));
grid on;


%% ELEVATION VS SLANT RANGE VS LATENCY

allElevations = [];
allDistances = [];

for u = 1:visibilityData.numUsers
    allElevations = [allElevations, visibilityData.elevationDeg{timeIdx, u}];
    allDistances  = [allDistances,  visibilityData.distanceKm{timeIdx, u}];
end

% One-way propagation latency [ms]
% distance is in km, c ~= 300000 km/s
% latency [ms] = distance[km] / 300
latencyMs = allDistances / 300;

% Sort for smooth latency curve
[sortedDistances, sortIdx] = sort(allDistances);
sortedLatencyMs = latencyMs(sortIdx);

figure("Color",'w');

yyaxis left
scatter(allDistances, allElevations, 'filled');
ylabel('Elevation angle [deg]');

yyaxis right
plot(sortedDistances, sortedLatencyMs, 'LineWidth', 1.5);
ylabel('One-way propagation latency [ms]');

xlabel('Slant range [km]');
title(sprintf('Elevation and propagation latency vs slant range at t = %.1f min', snapshotTime));
grid on;


%% BEST SNR AND ACHIEVABLE RATE OVER TIME FOR SELECTED USER

timeVec = USER_SAT_evolution.timeVec;

if isdatetime(timeVec)
    tSeconds = seconds(timeVec - timeVec(1));
elseif isduration(timeVec)
    tSeconds = seconds(timeVec - timeVec(1));
else
    tSeconds = timeVec - timeVec(1);
end

% Extract tensors for selected user
% Dimensions after squeeze: [numSats x numTimeSteps]
snrUser  = squeeze(USER_SAT_evolution.SNRtensor(userIdx,:,:));
rateUser = squeeze(USER_SAT_evolution.rateTensor(userIdx,:,:));
maskUser = squeeze(USER_SAT_evolution.validLinkMask(userIdx,:,:));

% Remove invalid links
snrUser(~maskUser)  = NaN;
rateUser(~maskUser) = NaN;

% Best SNR among all visible satellites at each time instant
bestSnrLin = max(snrUser, [], 1, 'omitnan');

% Best achievable rate among all visible satellites at each time instant
bestRate = max(rateUser, [], 1, 'omitnan');

% Unit conversions
bestSnrDb    = 10*log10(bestSnrLin);
bestRateMbps = bestRate / 1e6;

% Combined dual-axis plot
figure("Color",'w');

yyaxis left
plot(tSeconds, bestRateMbps, 'LineWidth', 1.5);
ylabel('Best achievable rate [Mbit/s]');

yyaxis right
plot(tSeconds, bestSnrDb, 'LineWidth', 1.5);
ylabel('Best SNR [dB]');

xlabel('Time [s]');
title(sprintf('Best achievable rate and SNR over time for User %d', userIdx));
grid on;

end