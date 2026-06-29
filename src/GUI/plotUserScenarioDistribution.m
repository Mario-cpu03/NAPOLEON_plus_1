function [fig, ax] = plotUserScenarioDistribution(simulationScenario, configAoI, varargin)

%% Input parsing

p = inputParser;
p.addParameter("Axes", [], @(x) isempty(x) || isgraphics(x, "axes"));
p.addParameter("ShowCityLabels", true, @(x) islogical(x) && isscalar(x));
p.addParameter("ShowUsers", false, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});

axInput = p.Results.Axes;
showCityLabels = p.Results.ShowCityLabels;
showUsers = p.Results.ShowUsers;

%% Create or reuse axes

if isempty(axInput)
    fig = figure("Color", "w");
    ax = axes(fig);
else
    ax = axInput;
    fig = ancestor(ax, "figure");
end

cla(ax);
hold(ax, "on");

%% Extract sampled user positions from the scenario

gss = simulationScenario.GroundStations;
numUsers = numel(gss);

latUsers = zeros(numUsers, 1);
lonUsers = zeros(numUsers, 1);

for u = 1:numUsers
    latUsers(u) = gss(u).Latitude;
    lonUsers(u) = gss(u).Longitude;
end

%% Reconstruct the original AoI grid

edgesLat = configAoI.latMin : configAoI.deltaLat : configAoI.latMax;
edgesLon = configAoI.lonMin : configAoI.deltaLon : configAoI.lonMax;

nLat = numel(edgesLat) - 1;
nLon = numel(edgesLon) - 1;

%% Count users in each cell

% counts(iLat, iLon) = number of users inside that lat/lon cell
counts = histcounts2(latUsers, lonUsers, edgesLat, edgesLon);

maxCount = max(counts(:));

if maxCount == 0
    warning("plotUserScenarioDistribution:NoUsersInsideAoI", ...
        "No users found inside the configured Area of Interest.");
    maxCount = 1;
end

%% Axes setup

ax.Color = "w";
ax.XColor = "k";
ax.YColor = "k";
ax.ZColor = "k";
ax.GridColor = [0.65 0.65 0.65];
ax.FontSize = 12;
ax.LineWidth = 1.2;

grid(ax, "on");
box(ax, "on");

colormap(ax, turbo);
clim(ax, [0 maxCount]);

%% Draw 3D blocks cell by cell

for iLat = 1:nLat
    for iLon = 1:nLon

        x1 = edgesLon(iLon);
        x2 = edgesLon(iLon + 1);

        y1 = edgesLat(iLat);
        y2 = edgesLat(iLat + 1);

        h = counts(iLat, iLon);

        draw_cell_block(ax, x1, x2, y1, y2, h);

    end
end

%% Optional sampled user dots

if showUsers
    scatter3(ax, ...
        lonUsers, ...
        latUsers, ...
        maxCount * 1.03 * ones(size(lonUsers)), ...
        12, ...
        "k", ...
        "filled");
end

%% Optional city labels

if showCityLabels

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

    for k = 1:size(metroNames, 1)

        name = metroNames{k, 1};
        latC = metroNames{k, 2};
        lonC = metroNames{k, 3};

        if latC < configAoI.latMin || latC > configAoI.latMax || ...
           lonC < configAoI.lonMin || lonC > configAoI.lonMax
            continue;
        end

        iLat = find(latC >= edgesLat(1:end-1) & latC < edgesLat(2:end), 1, "first");
        iLon = find(lonC >= edgesLon(1:end-1) & lonC < edgesLon(2:end), 1, "first");

        if isempty(iLat) || isempty(iLon)
            continue;
        end

        hCity = counts(iLat, iLon);
        zLabel = max(hCity + 0.8, 1.0);

        text(ax, lonC, latC, zLabel, name, ...
            "Color", "k", ...
            "FontSize", 10, ...
            "FontWeight", "bold", ...
            "HorizontalAlignment", "center", ...
            "VerticalAlignment", "bottom");

    end
end

%% Labels and view

xlabel(ax, "Longitude [deg]", ...
    "Color", "k", ...
    "FontWeight", "bold");

ylabel(ax, "Latitude [deg]", ...
    "Color", "k", ...
    "FontWeight", "bold");

zlabel(ax, "Number of users", ...
    "Color", "k", ...
    "FontWeight", "bold");

title(ax, sprintf("Outcome of the sampling process: %d users", numUsers), ...
    "Color", "k", ...
    "FontSize", 18, ...
    "FontWeight", "bold");

xlim(ax, [configAoI.lonMin configAoI.lonMax]);
ylim(ax, [configAoI.latMin configAoI.latMax]);
zlim(ax, [0 maxCount * 1.15]);

xticks(ax, configAoI.lonMin : 5 : configAoI.lonMax);
yticks(ax, configAoI.latMin : 5 : configAoI.latMax);

view(ax, 45, 28);

cb = colorbar(ax);
cb.Color = "k";
cb.Label.String = "Number of users per cell";
cb.Label.Color = "k";
cb.Label.FontWeight = "bold";

hold(ax, "off");

end

%% ========================================================================
% Local helper function
% ========================================================================

function draw_cell_block(ax, x1, x2, y1, y2, h)
%DRAW_CELL_BLOCK Draw one 3D rectangular cell.

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
    1 2 3 4;
    5 6 7 8;
    1 2 6 5;
    2 3 7 6;
    3 4 8 7;
    4 1 5 8;
];

patch(ax, ...
    "Vertices", vertices, ...
    "Faces", faces, ...
    "FaceVertexCData", h * ones(8, 1), ...
    "FaceColor", "flat", ...
    "EdgeColor", [0.18 0.18 0.18], ...
    "LineWidth", 0.4);

end