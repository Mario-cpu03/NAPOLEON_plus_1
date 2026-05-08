function plot_theoretical_user_density(UserGrid, configAoI)

    % Fine grid for visualization
    lonFine = linspace(configAoI.lonMin, configAoI.lonMax, 250);
    latFine = linspace(configAoI.latMin, configAoI.latMax, 250);

    [LonFine, LatFine] = meshgrid(lonFine, latFine);

    density = zeros(size(LonFine));

    % Cell probabilities
    flatWeights = UserGrid.cellWeight(:);
    cellProb = flatWeights / sum(flatWeights);
    cellProbGrid = reshape(cellProb, UserGrid.nLat, UserGrid.nLon);

    for iLat = 1:UserGrid.nLat
        for iLon = 1:UserGrid.nLon

            thisLatMin = UserGrid.edgesLat(iLat);
            thisLatMax = UserGrid.edgesLat(iLat + 1);
            thisLonMin = UserGrid.edgesLon(iLon);
            thisLonMax = UserGrid.edgesLon(iLon + 1);

            latCenter = 0.5 * (thisLatMin + thisLatMax);
            lonCenter = 0.5 * (thisLonMin + thisLonMax);

            sigmaLat = (thisLatMax - thisLatMin) / 4;
            sigmaLon = (thisLonMax - thisLonMin) / 4;

            pCell = cellProbGrid(iLat, iLon);

            % Gaussian density centered in the selected cell
            G = exp( ...
                -0.5 * ((LatFine - latCenter) / sigmaLat).^2 ...
                -0.5 * ((LonFine - lonCenter) / sigmaLon).^2 );

            % Normalize the 2D Gaussian approximately
            G = G / (2*pi*sigmaLat*sigmaLon);

            density = density + pCell * G;

        end
    end

    % Normalize numerically for visualization consistency
    density = density / sum(density(:));

    figure;
    surf(LonFine, LatFine, density, 'EdgeColor', 'none');
    xlabel('Longitude [deg]');
    ylabel('Latitude [deg]');
    zlabel('Probability density');
    title('Theoretical spatial distribution of the user-generation process');
    colorbar;
    grid on;
    view(45,30);

end