%The aim of this function is to distribute str.N_usr number of users in the
%AreaOfInterest in a non-uniform way. The urban areas should have more
%users with respect to the rural area.
%Here we use the weighted grid in utput from create_grid(), where every box
%has a weight. The grid.cdf probability distribution will be used to saple 
%the userd in the area of interest based on the weight of every cell.





function [simulationScenario,groundEnv]=distribute_users(simulationScenario,numUsers,UserGrid)

    users.lat= zeros(numUsers, 1);
    users.lon = zeros(numUsers, 1);
    users.env = strings(numUsers, 1);
    users.cellIdx = zeros(numUsers, 2);
    groundEnv  = strings(numUsers,1);


    %this is the main loop, that generates str.N_usr users
    for u=1:numUsers

        % Sample a cell index based on the weighted grid. The idea is that
        % the urban cells shold be chosen more frequently than the
        % others. grid.cdf is a vector from 0 to 1, where every cell has an
        % interval proportional to its weight. 
        %The idea is to exract a random numer in [0,1] and search the first
        %higher value in the CDF. The index of that value will be the index
        %of the cell where the user will be located.
        r=rand;
        idx=find(r<=UserGrid.cdf,1,'first');


        %This block converts the linear index idx in the couple [iLat,
        %iLon] of the grid
        [iLat, iLon] = ind2sub([UserGrid.nLat, UserGrid.nLon], idx);


        %We have defined the cell where the user will be located. This
        %block assign tonthe user the position inside the cell. That
        %position will be chosen with a normal distribution.
        thisLatMin = UserGrid.edgesLat(iLat);
        thisLatMax = UserGrid.edgesLat(iLat + 1);
        thisLonMin = UserGrid.edgesLon(iLon);
        thisLonMax = UserGrid.edgesLon(iLon + 1);
        latCenter = 0.5 * (thisLatMin + thisLatMax);
        lonCenter = 0.5 * (thisLonMin + thisLonMax);

        sigmaLat = (thisLatMax - thisLatMin) / 6;
        sigmaLon = (thisLonMax - thisLonMin) / 6;

        latSample = latCenter + sigmaLat * randn;
        lonSample = lonCenter + sigmaLon * randn;

        % Keep the user inside the selected cell
        users.lat(u) = min(max(latSample, thisLatMin), thisLatMax);
        users.lon(u) = min(max(lonSample, thisLonMin), thisLonMax);


        %The user have the same environment of the cell where it is
        %located. 
        
        users.cellIdx(u,:) = [iLat, iLon];
        groundEnv(u)=UserGrid.env(iLat, iLon);


        %This block creates the object "groundStation" in the scenario sc.
        %We crete a groundStation object for each user, with progressive
        %names (USR_01, USR_02,...)
        groundStation(simulationScenario,users.lat(u), users.lon(u), Name=sprintf("USR_%02d",u));  
    end

end