%The aim of this function is to distribute str.N_usr number of users in the
%AreaOfInterest in a non-uniform way. The urban areas should have more
%users with respect to the rural area.
%Here we use the weighted grid in utput from create_grid(), where every box
%has a weight. The grid.cdf probability distribution will be used to saple 
%the userd in the area of interest based on the weight of every cell.





function [simulationScenario,groundEnv]=distribute_users(simulationScenario,numUsers,grid)

    users.lat     = zeros(numUsers, 1);
    users.lon     = zeros(numUsers, 1);
    users.env     = strings(numUsers, 1);
    users.cellIdx = zeros(numUsers, 2);
    groundEnv     = strings(numUsers,1);


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
        idx=find(r<=grid.cdf,1,'first');


        %This block converts the linear index idx in the couple [iLat,
        %iLon] of the grid
        [iLat, iLon] = ind2sub([grid.num_box_lat, grid.num_box_lon], idx);


        %We have defined the cell where the user will be located. This
        %block assign tonthe user the position inside the cell. That
        %position will be chosen with a normal distribution. Eg.
        %position=minimum_edge+cell_amplitude*rand.
        thisLatMin = grid.edgesLat(iLat);
        thisLatMax = grid.edgesLat(iLat + 1);
        thisLonMin = grid.edgesLon(iLon);
        thisLonMax = grid.edgesLon(iLon + 1);
        users.lat(u) = thisLatMin + (thisLatMax - thisLatMin) * rand;
        users.lon(u) = thisLonMin + (thisLonMax - thisLonMin) * rand;


        %The user have the same environment of the cell where it is
        %located. 
        
        users.cellIdx(u,:) = [iLat, iLon];
        groundEnv(u)=grid.env(iLat, iLon);


        %This block creates the object "groundStation" in the scenario sc.
        %We crete a groundStation object for each user, with progressive
        %names (USR_01, USR_02,...)
        groundStation(simulationScenario,users.lat(u), users.lon(u), Name=sprintf("USR_%02d",u));  
    end

end