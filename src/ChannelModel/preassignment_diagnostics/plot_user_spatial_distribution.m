function plot_user_spatial_distribution(simulationScenario, configAoI)

% plot_user_spatial_distribution
% 3D visualization of the already sampled user distribution.
%
% The plot counts how many ground stations/users fall inside each
% 2 deg x 2 deg cell of the Area of Interest.
%
% This is NOT the theoretical probability distribution.
% This is one sampled realization of the stochastic user-generation process.

    %% Extract sampled user positions from the scenario

    gss = simulationScenario.GroundStations;
    numUsers = numel(gss);

    latUsers = zeros(numUsers,1);
    lonUsers = zeros(numUsers,1);

    for u = 1:numUsers
        latUsers(u) = gss(u).Latitude;
        lonUsers(u) = gss(u).Longitude;
    end

    %% Reconstruct the original 2 x 2 degree grid

    edgesLat = configAoI.latMin : configAoI.deltaLat : configAoI.latMax;
    edgesLon = configAoI.lonMin : configAoI.deltaLon : configAoI.lonMax;

    nLat = numel(edgesLat) - 1;
    nLon = numel(edgesLon) - 1;

    centerLat = edgesLat(1:end-1) + configAoI.deltaLat/2;
    centerLon = edgesLon(1:end-1) + configAoI.deltaLon/2;

    %% Count users in each 2 x 2 cell

    % counts(iLat,iLon) = number of users inside that lat/lon cell
    counts = histcounts2(latUsers, lonUsers, edgesLat, edgesLon);

    maxCount = max(counts(:));

    if maxCount == 0
        warning('No users found inside the configured Area of Interest.');
        maxCount = 1;
    end

    %% Figure setup
figure('Color', 'w');
ax = axes;
hold(ax, 'on');

ax.Color = 'w';
ax.XColor = 'k';
ax.YColor = 'k';
ax.ZColor = 'k';
ax.GridColor = [0.65 0.65 0.65];
ax.FontSize = 12;
ax.LineWidth = 1.2;

    colormap(turbo);
    clim([0 maxCount]);

    %% Draw 3D blocks cell by cell

    for iLat = 1:nLat
        for iLon = 1:nLon

            x1 = edgesLon(iLon);
            x2 = edgesLon(iLon+1);

            y1 = edgesLat(iLat);
            y2 = edgesLat(iLat+1);

            h = counts(iLat, iLon);

            draw_cell_block(x1, x2, y1, y2, h);

        end
    end

    %% Add sampled users as black dots on top, optional but useful

    % Comment this block if you only want the 3D bars
    %scatter3(lonUsers, latUsers, maxCount*1.03*ones(size(lonUsers)), ...
    %    12, 'k', 'filled');

    %% City labels

    metroNames = {
        'London',    51.5074,  -0.1278;
        'Paris',     48.8566,   2.3522;
        'Madrid',    40.4168,  -3.7038;
        'Lisbon',    38.7223,  -9.1393;
        'Rome',      41.9028,  12.4964;
        'Milan',     45.4642,   9.1900;
        'Berlin',    52.5200,  13.4050;
        'Hamburg',   53.5511,   9.9937;
        'Munich',    48.1351,  11.5820;
        'Brussels',  50.8503,   4.3517;
        'Amsterdam', 52.3676,   4.9041;
        'Vienna',    48.2082,  16.3738;
        'Prague',    50.0755,  14.4378;
        'Warsaw',    52.2297,  21.0122;
        'Budapest',  47.4979,  19.0402;
        'Bucharest', 44.4268,  26.1025;
        'Athens',    37.9838,  23.7275;
    };

    for k = 1:size(metroNames,1)

        name = metroNames{k,1};
        latC = metroNames{k,2};
        lonC = metroNames{k,3};

        if latC < configAoI.latMin || latC > configAoI.latMax || ...
           lonC < configAoI.lonMin || lonC > configAoI.lonMax
            continue;
        end

        % Find cell containing the city
        iLat = find(latC >= edgesLat(1:end-1) & latC < edgesLat(2:end), 1, 'first');
        iLon = find(lonC >= edgesLon(1:end-1) & lonC < edgesLon(2:end), 1, 'first');

        if isempty(iLat) || isempty(iLon)
            continue;
        end

        hCity = counts(iLat, iLon);

        % Put label slightly above the corresponding bar
        zLabel = max(hCity + 0.8, 1.0);

        text(lonC, latC, zLabel, name, ...
            'Color', 'k', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');

    end

    %% Axes, labels, title

    xlabel('Longitude [deg]', 'Color', 'k', 'FontWeight', 'bold');
ylabel('Latitude [deg]', 'Color', 'k', 'FontWeight', 'bold');
zlabel('Number of users', 'Color', 'k', 'FontWeight', 'bold');

    title(sprintf('Outcome of the sampling process: %d Users', numUsers), ...
        'Color', 'k', ...
        'FontSize', 18, ...
        'FontWeight', 'bold');



    xlim([configAoI.lonMin configAoI.lonMax]);
    ylim([configAoI.latMin configAoI.latMax]);
    zlim([0 maxCount*1.15]);

    xticks(configAoI.lonMin:5:configAoI.lonMax);
    yticks(configAoI.latMin:5:configAoI.latMax);

    grid on;
    box on;

    view(45, 28);

    cb = colorbar;
cb.Color = 'k';
cb.Label.String = 'Number of users per cell';
cb.Label.Color = 'k';
cb.Label.FontWeight = 'bold';

    hold off;

end


function draw_cell_block(x1, x2, y1, y2, h)

% Draw a 3D rectangular block over one geographic cell.
% x = longitude, y = latitude, z = user count.

    if h == 0
        hPlot = 0.03;   % thin visible tile for empty cells
    else
        hPlot = h;
    end

    vertices = [
        x1 y1 0;
        x2 y1 0;
        x2 y2 0;
        x1 y2 0;
        x1 y1 hPlot;
        x2 y1 hPlot;
        x2 y2 hPlot;
        x1 y2 hPlot;
    ];

    faces = [
        1 2 3 4;   % bottom
        5 6 7 8;   % top
        1 2 6 5;   % side
        2 3 7 6;   % side
        3 4 8 7;   % side
        4 1 5 8;   % side
    ];

    patch( ...
        'Vertices', vertices, ...
        'Faces', faces, ...
        'FaceVertexCData', h * ones(8,1), ...
        'FaceColor', 'flat', ...
        'EdgeColor', [0.18 0.18 0.18], ...
        'LineWidth', 0.4);

end