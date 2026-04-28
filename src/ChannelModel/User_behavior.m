%% User_behavior function
% This function computes the non uniform distribution that models the behavior
% of the ground stations/fixed-position users. The scope of the function is
% to build a grid over a finite portion of europe; in this NxN square
% blocks, users are drawn accordingly to a weighted probability biased
% towards points of greater population density. 
% Each ground station's name is an integer number defined in the
% GroundStation object creation. 

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. configAoI : Data Strcuture containing the parameters needed
%       to configurate the Area of Interest:
%                   (i) the minimum and maximum latitudes,
%                   (ii) minimum and maximum longitudes,
%                   (iii) spatial resolution of each cell
%
%       2. numUsers : Number of ground stations
%
%       3. simulationScenario : satelliteScenario object of the toolbox to
%       be updated with the ground stations objects

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. simulationScenario : updated simulationScenario where the ground
%       stations can be accessed as GroundStation objects
%
%       2. groundEnv : column vector of size numUsers containing each
%       ground station's environment. The mapping is performed by letting
%       th index of the array match the numerical name associated to each
%       gs

function [simulationScenario, groundEnv]=User_behavior(configAoI, numUsers, simulationScenario)
    
    %this function creates the weighted grid
    grid=create_grid(configAoI);

    %thi function, give the grid, distribute the users
    [simulationScenario,groundEnv]=distribute_users(simulationScenario,numUsers,grid);

end