function drawScenarioDistribution(ax, D, C, mode)
%DRAWSCENARIODISTRIBUTION Draw the actual 3D user distribution in the AoI.
%
% This function replaces the old schematic/fake map. It plots the real
% GroundStations contained in SCENARIO.satelliteScenario, already extracted
% by buildScenarioPlotData.
%
% mode: 'scenario' or 'association' changes only the visual emphasis.

    if nargin < 4 || isempty(mode)
        mode = 'scenario';
    end

    if nargin < 3 || isempty(C)
        C = struct();
    end

    if isempty(D) || ~isstruct(D)
        clearScenarioAxes(ax, C);
        return;
    end

    colCard   = colorOf(C, 'card',        [1.000 1.000 1.000]);
    colCanvas = colorOf(C, 'canvas',      [0.965 0.982 1.000]);
    colBlue   = colorOf(C, 'blueSoft',    [0.885 0.935 1.000]);
    colAccent = colorOf(C, 'accent',      [0.000 0.315 0.760]);
    colReady  = colorOf(C, 'ready',       [0.060 0.580 0.320]);
    colBusy   = colorOf(C, 'busy',        [0.890 0.480 0.060]);
    colText   = colorOf(C, 'text',        [0.060 0.085 0.125]);
    colMuted  = colorOf(C, 'muted',       [0.380 0.430 0.500]);
    colGrid   = colorOf(C, 'grid',        [0.800 0.850 0.910]);
    colAxis   = colorOf(C, 'axis',        [0.500 0.560 0.640]);

    cla(ax);
    ax.Visible = 'on';
    ax.Color = colCanvas;
    ax.XColor = colAxis;
    ax.YColor = colAxis;
    ax.ZColor = colAxis;
    ax.GridColor = colGrid;
    ax.Box = 'off';
    ax.Toolbar.Visible = 'off';

    try
        disableDefaultInteractivity(ax);
    catch
    end

    hold(ax, 'on');

    %% AoI curved surface
    if isfield(D, 'aoiMeshX') && ~isempty(D.aoiMeshX)
        surf(ax, D.aoiMeshX, D.aoiMeshY, D.aoiMeshZ, ...
            'FaceColor', colBlue, ...
            'EdgeColor', 'none', ...
            'FaceAlpha', 0.95);
    end

    %% Latitude/longitude guide lines on the AoI cap
    try
        for i = 1:numel(D.latLines)
            lat = D.latLines(i) * ones(size(D.aoiLonGrid));
            lon = D.aoiLonGrid;
            [x, y, z] = localSphereXYZ(lat, lon, 1.006);
            plot3(ax, x, y, z, '-', 'Color', colGrid, 'LineWidth', 0.65);
        end

        for j = 1:numel(D.lonLines)
            lat = D.aoiLatGrid;
            lon = D.lonLines(j) * ones(size(D.aoiLatGrid));
            [x, y, z] = localSphereXYZ(lat, lon, 1.006);
            plot3(ax, x, y, z, '-', 'Color', colGrid, 'LineWidth', 0.65);
        end
    catch
        % Plot remains valid without grid lines.
    end

    %% AoI boundary
    if isfield(D, 'aoiBoundaryXYZ') && ~isempty(D.aoiBoundaryXYZ)
        B = D.aoiBoundaryXYZ;
        plot3(ax, B(:,1), B(:,2), B(:,3), '-', ...
            'Color', colAccent, ...
            'LineWidth', 2.2);
    end

    %% Users / terminals
    markerColor = colBusy;
    edgeColor = [1 1 1];
    if lower(string(mode)) == "association"
        markerColor = colReady;
    end

    if isfield(D, 'userXYZ') && ~isempty(D.userXYZ)
        U = D.userXYZ;

        % Draw tiny radial stems for readability. This makes the 3D
        % distribution feel physical without pretending users have orbital altitude.
        nStem = min(size(U,1), 300);
        for k = 1:nStem
            p = U(k,:);
            base = p ./ norm(p);
            plot3(ax, [base(1), p(1)], [base(2), p(2)], [base(3), p(3)], '-', ...
                'Color', colMuted, ...
                'LineWidth', 0.45);
        end

        scatter3(ax, U(:,1), U(:,2), U(:,3), 42, ...
            'filled', ...
            'MarkerFaceColor', markerColor, ...
            'MarkerEdgeColor', edgeColor, ...
            'LineWidth', 0.75);
    end

    %% Camera and framing
    axis(ax, 'equal');
    grid(ax, 'on');

    if isfield(D, 'xLim') && numel(D.xLim) == 2
        xlim(ax, D.xLim);
    end
    if isfield(D, 'yLim') && numel(D.yLim) == 2
        ylim(ax, D.yLim);
    end
    if isfield(D, 'zLim') && numel(D.zLim) == 2
        zlim(ax, D.zLim);
    end

    if isfield(D, 'viewAz') && isfield(D, 'viewEl')
        view(ax, D.viewAz, D.viewEl);
    else
        view(ax, 125, 35);
    end

    ax.XTickLabel = [];
    ax.YTickLabel = [];
    ax.ZTickLabel = [];
    xlabel(ax, '');
    ylabel(ax, '');
    zlabel(ax, '');

    try
        camlight(ax, 'headlight');
        lighting(ax, 'gouraud');
    catch
    end

    hold(ax, 'off');
end

%% Local helpers
function clearScenarioAxes(ax, C)
    cla(ax);
    ax.Visible = 'off';
    if nargin >= 2 && isstruct(C) && isfield(C, 'card')
        ax.Color = C.card;
    end
    ax.XTick = [];
    ax.YTick = [];
    ax.ZTick = [];
    grid(ax, 'off');
end

function c = colorOf(C, fieldName, fallback)
    if isstruct(C) && isfield(C, fieldName)
        c = C.(fieldName);
    else
        c = fallback;
    end
end

function [x, y, z] = localSphereXYZ(latDeg, lonDeg, radius)
    x = radius .* cosd(latDeg) .* cosd(lonDeg);
    y = radius .* cosd(latDeg) .* sind(lonDeg);
    z = radius .* sind(latDeg);
end
