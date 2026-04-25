%% Main Function Channel Model Module
% The scope of this function is to call and execute all the channel model 
% module functions that implement: (i) user behavior, (ii) satellite
% constellation, (iii) reduce the constellation to the relevant coordinates,
% (iv) display the globe with users and satellites, (v) user-satellite
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

% Init output structure
USER_SAT_evolution = struct();

% Constellation fixed parameters.


% Init user parameters.  We assume a small italy-centric portion of europe,
% in which a multi distributed user behavior is assumed. The
% users are static (mobile speed = 0) for simplicity. The user may as well
% be though of as base stations, hence antennas.

% CALL SATELLITE FUNCTION - defines the Starlink shell 1 constallation
simulationScenario=Satellite_constellation(configConst, simulationScenario);

% CALL USER FUNCTION to generate the non uniform users' distribution

%configAoI.latMin
%configAoI.latMax
%configAoI.lonMin
%configAoI.lonMax
%configAoI.deltaLat
%configAoI.deltaLon

[simulationScenario, groundEnv]=User_behavior(configAoI, numUsers, simulationScenario);

% REDUCING SATELLITAR OBJECTS TO USER-ONLY RELEVANT SATELLITES
filteredSimScen=Filter_constellation(simulationScenario, minimumElev);

% CALL DISPLAY FUNCTION
Display_globe(filteredSimScen); 

% COMPUTATION OF THE SATELLITAR LINK STATISTICS AND CHANNEL SIMULATION
USER_SAT_evolution = channel_model(configChannel, filteredSimScen, groundEnv);

end