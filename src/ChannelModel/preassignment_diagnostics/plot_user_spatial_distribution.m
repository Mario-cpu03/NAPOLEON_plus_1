function plot_user_spatial_distribution(simulationScenario, configAoI)

    % Extract ground-station positions
    gss = simulationScenario.GroundStations;
    numUsers = numel(gss);

    latUsers = zeros(numUsers,1);
    lonUsers = zeros(numUsers,1);

    for u = 1:numUsers
        latUsers(u) = gss(u).Latitude;
        lonUsers(u) = gss(u).Longitude;
    end

    % Grid edges
    edgesLat = configAoI.latMin : configAoI.deltaLat : configAoI.latMax;
    edgesLon = configAoI.lonMin : configAoI.deltaLon : configAoI.lonMax;

    % User counts per cell
    counts = histcounts2(latUsers, lonUsers, edgesLat, edgesLon);

    % Cell centers
    centerLat = edgesLat(1:end-1) + configAoI.deltaLat/2;
    centerLon = edgesLon(1:end-1) + configAoI.deltaLon/2;

    [LonC, LatC] = meshgrid(centerLon, centerLat);
    
% empirical prob distr
probCounts = counts / sum(counts(:));

figure;
surf(LonC, LatC, probCounts, 'EdgeColor', 'none');

xlabel('Longitude [deg]');
ylabel('Latitude [deg]');
zlabel('Empirical probability (Users/TotUsers)');
title('Empirical user spatial probability distribution');

colorbar;
grid on;
view(45,30);

end