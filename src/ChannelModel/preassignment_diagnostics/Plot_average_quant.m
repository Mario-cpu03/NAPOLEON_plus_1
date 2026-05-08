function Plot_average_quant(snapshotTime, visibilityData, sampleTime)

% Computing sample time index from snapshot
timeIdx = round(snapshotTime*60 / sampleTime) + 1;

% Safety check
if timeIdx < 1 || timeIdx > visibilityData.numTimeSteps
    error('Requested snapshotTime is outside the available visibilityData time window.');
end

% Plot number of visible satellites per user
numVisiblePerUser = zeros(1, visibilityData.numUsers);

for u = 1:visibilityData.numUsers
    numVisiblePerUser(u) = numel(visibilityData.visibleSatIdx{timeIdx, u});
end

figure;
bar(1:visibilityData.numUsers, numVisiblePerUser);

xlabel('User / Ground Station index');
ylabel('Number of visible satellites');
title(sprintf('Visible satellites per user at t = %.1f min', snapshotTime));

grid on;


% Number of users visible to each satellite at the selected time
numUsersPerSat = zeros(1, visibilityData.numSats);

for u = 1:visibilityData.numUsers
    userVisibleSatIdx = visibilityData.visibleSatIdx{timeIdx, u};

    for k = 1:numel(userVisibleSatIdx)
        satIdx = userVisibleSatIdx(k);
        numUsersPerSat(satIdx) = numUsersPerSat(satIdx) + 1;
    end
end

% Plot number of users per satellite
figure;
bar(1:visibilityData.numSats, numUsersPerSat);

xlabel('Satellite index');
ylabel('Number of visible users');
title(sprintf('Visible users per satellite at t = %.1f min', snapshotTime));
grid on;

%for each visible user-satellite pair, collect elevation:
allElevations = [];

for u = 1:visibilityData.numUsers
    elevU = visibilityData.elevationDeg{timeIdx, u};
    allElevations = [allElevations, elevU];
end

figure;
histogram(allElevations);
xlabel('Elevation angle [deg]');
ylabel('Number of visible links');
title('Elevation angle distribution');
grid on;


%slant range is a direct proxy for path loss and propagation delay 
%allDistances = [];

%for u = 1:visibilityData.numUsers
%    distU = visibilityData.distanceKm{timeIdx, u};
%    allDistances = [allDistances, distU];
%end

%figure;
%histogram(allDistances);
%xlabel('Slant range [km]');
%ylabel('Number of visible links');
%title(sprintf('Slant range distribution at t = %.1f min', snapshotTime));
%grid on;



%% ELEV VS SLANT VS LATENCY
% Elevation vs slant range
allElevations = [];
allDistances = [];

for u = 1:visibilityData.numUsers
    allElevations = [allElevations, visibilityData.elevationDeg{timeIdx, u}];
    allDistances  = [allDistances,  visibilityData.distanceKm{timeIdx, u}];
end

% One-way propagation latency [ms]
latencyMs = allDistances / 300;

% Sort for smooth latency curve
[sortedDistances, sortIdx] = sort(allDistances);
sortedLatencyMs = latencyMs(sortIdx);

figure;

yyaxis left
scatter(allDistances, allElevations, 'filled');
ylabel('Elevation angle [deg]');

yyaxis right
plot(sortedDistances, sortedLatencyMs, 'LineWidth', 1.5);
ylabel('One-way propagation latency [ms]');

xlabel('Slant range [km]');
title(sprintf('Elevation and propagation latency vs slant range at t = %.1f min', snapshotTime));
grid on;
end