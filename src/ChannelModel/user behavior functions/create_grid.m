function UserGrid=create_grid(configAoI)  


    UserGrid.edgesLat=configAoI.latMin : configAoI.deltaLat : configAoI.latMax;
    UserGrid.edgesLon=configAoI.lonMin : configAoI.deltaLon : configAoI.lonMax;

    UserGrid.nLat = size(UserGrid.edgesLat,2)-1;
    UserGrid.nLon = size(UserGrid.edgesLon,2)-1;

    UserGrid.centerP_lat=UserGrid.edgesLat(1:end-1) + configAoI.deltaLat/2;
    UserGrid.centerP_lon=UserGrid.edgesLon(1:end-1) + configAoI.deltaLon/2;

    UserGrid.cellCategory = zeros(UserGrid.nLat, UserGrid.nLon); % INITIALIZATION

    %list of the cities that could be inside the simulation box. The reasoning is the
    %sequent: we assign the higher category to the boxes that contains
    %cities. Then, all the boxes around these ones, will be marked with a
    %lower category. All the other will have category zero. 
    %The categories represent the ITU-R environments, obtaining "urband"
    %environment in the boxes containing cities, "surroundings" in the one
    %all around. For all the other boxes, we will chose randomly between
    %"Village" or "RuralWooded" environments.
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


    %the two anonymous functions below, given the coordinates, returns the
    %indexes of that point in the Grid. These indexes will be used to
    %assign the categories to each box.
    latToIdx = @(lat) min(max(floor((lat - configAoI.latMin) / configAoI.deltaLat) + 1, 1), UserGrid.nLat);
    lonToIdx = @(lon) min(max(floor((lon - configAoI.lonMin) / configAoI.deltaLon) + 1, 1), UserGrid.nLon);


    %this block assign the category 2(urban in the ITU-R standard) to the boxes in the Grid that
    %contains the cities. We only assign the category 2 to the boxes that
    %contains cities. Since the list of cities is hard-coded, all the
    %cities that are not inside the borders of the Grid will be jumped.
    for k = 1:size(metroNames, 1)
        latC = metroNames{k, 2};
        lonC = metroNames{k, 3};

        if latC < configAoI.latMin || latC > configAoI.latMax || lonC < configAoI.lonMin || lonC > configAoI.lonMax    %if that cities execeds the borders of the Grid
            continue;
        end

        iLat = latToIdx(latC);
        iLon = lonToIdx(lonC);
        UserGrid.cellCategory(iLat, iLon) = 2;
    end


    %this block marks the 8 boxes around the ones with category 2 with
    %category 1 (surrounding in the ITU-R standard).
    [metroI, metroJ] = find(UserGrid.cellCategory == 2);
    for k = 1:numel(metroI)
        i0 = metroI(k);
        j0 = metroJ(k);

        for di = -1:1
            for dj = -1:1
                ii = i0 + di;
                jj = j0 + dj;

                if ii >= 1 && ii <= UserGrid.nLat && jj >= 1 && jj <= UserGrid.nLon
                    if UserGrid.cellCategory(ii,jj) ~= 2       %in the case there are 2 cities in adiacen blocks
                        UserGrid.cellCategory(ii,jj) = max(UserGrid.cellCategory(ii,jj), 1);
                    end
                end
            end
        end
    end

    %the block below, given the category that we already assigned to
    %each box in the Grid, assign the ITU-R environment to each box. The
    %boxes with category 1 will be assigned randomly to "Village" or
    %"RuralWooded" environments.
    UserGrid.cellWeight = ones(UserGrid.nLat, UserGrid.nLon);
    UserGrid.env        = strings(UserGrid.nLat, UserGrid.nLon);

    for i = 1:UserGrid.nLat
        for j = 1:UserGrid.nLon
            switch UserGrid.cellCategory(i,j)
                case 2
                    UserGrid.cellWeight(i,j) = 9;
                    UserGrid.env(i,j)        = "Urban";

                case 1
                    UserGrid.cellWeight(i,j) = 3;
                    UserGrid.env(i,j)        = "Suburban";

                otherwise
                    UserGrid.cellWeight(i,j) = 1;
                    if rand < 0.5
                        UserGrid.env(i,j) = "Village";
                    else
                        UserGrid.env(i,j) = "RuralWooded";
                    end
            end
        end
    end


    %these lines of code prepare the distribution of users for the weighted sampling. Having a Cumulative Distribution
    %Function (CDF) we can easily distribute the users in the Grid
    %following the weight. In this way, the boxes with the higher weights
    %will have an higer interval in the CDF, so the probability to be
    %chosen for the users will be higher
    flatWeights   = UserGrid.cellWeight(:);
    UserGrid.prob     = flatWeights / sum(flatWeights);
    UserGrid.cdf      = cumsum(UserGrid.prob);
    UserGrid.cdf(end) = 1.0;

end