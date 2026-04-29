%% Main Function Channel Model Module
% The scope of this function is to call and execute all the channel model 
% module functions that implement: (i) user behavior, (ii) satellite
% constellation, (iii) display the globe with users and satellites, (iv) user-satellite
% links overtime.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
% The main function obtains from the NAPOLEON_plus_1() function, therefore,
% potentially, from the GUI as the end-user choose different values, the 
% following data
%       1.  numUsers: number of users in a selected range
%       2.  startTime: initial time of simulation
%       3.  stopTime: finish time of simulation
%       4.  sampleTime: T_sampling for the computation of the satellite's
%       position and link state parameters

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
% The main function outputs:
%       1.  filteredSatellite_Set : Data Structure containing the satellite objects
%       relevant for the AoI simulated
% 
%       3.  USER_SAT_evolution: Array of Data Structures containing the time
%       evolution of the channel's parameters of each user-satellite link.

function [USER_SAT_evolution]=main_channel_function(numUsers, startTime, stopTime, sampleTime)

%%Adding general path for all helper functions
addpath('ChannelModel/user behavior functions'); %helper functions for user behavior modeling
addpath('ChannelModel/satellite_helper_functions'); %helper functions for satellite filtering

%%Init starting satellite scenario object with time intervals of reference
simulationScenario = satelliteScenario(startTime, stopTime, sampleTime);

% Constellation fixed parameters, to be found on paragraph 4 chapter 2 of
% the FCC 21-48.
configConst = struct( ...
              'planes', 72, ... % Total number of orbital planes, integer variable, must be reduced in Filter_constellation 
              'satPlanes', 22, ... % Total number of satellites per plane, integer variable, most probably will not be reduced in Filter_constellation 
              'inclination', 53.2, ... % Equatorial inclination of the orbit, float variable, .2 degrees more inclinated than 2020 constellation
              'phasingParam', 17, ... % Phasing param multiplying phasing offset obtained in Phasing Parameter Analysis for Satellite Collision Avoidance in Starlink and Kuiper Constellations
              'altitude', 540); % Altitude of the (second) shell

%%Init user distribution parameters. 
% We assume a small portion of earth focused on the continental europe 
% in which a multi distributed user behavior is assumed. 
% The users are static (mobile speed = 0) for simplicity. 
% The user may as well be though of as base stations, hence antennas.
configAoI = struct( ...
            'latMin', 35, ...
            'latMax', 60, ...
            'lonMin', -10, ...
            'lonMax', 30, ...
            'deltaLat', 2, ...
            'deltaLon', 2);

%%Init minimum elevation threshold for satellite filtering according
% to FCC 21-48 documentation.
minimumElev = 25;


%%Init channel parameters. 
% We assume

configChannel = struct();

% CALL SATELLITE FUNCTION - defines the Starlink shell 1 constallation
simulationScenario=Satellite_constellation(configConst, simulationScenario);%"ends timer"

% CALL USER FUNCTION to generate the non uniform users' distribution
[simulationScenario, groundEnv]=User_behavior(configAoI, numUsers, simulationScenario);

% CALL DISPLAY FUNCTION
Display_globe(simulationScenario); 

% REDUCING SATELLITAR OBJECTS TO USER-ONLY RELEVANT SATELLITES
visibilityData = Filter_constellation(simulationScenario, minimumElev);

% COMPUTATION OF THE SATELLITAR LINK STATISTICS AND CHANNEL SIMULATION
USER_SAT_evolution = channel_model(configChannel, visibilityData, groundEnv);

end