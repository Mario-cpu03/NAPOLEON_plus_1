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
%       1.  USER_SAT_evolution: Data Structure of tensors containing the time
%       evolution of the channel's parameters of each user-satellite link.

function [USER_SAT_evolution]=main_channel_function(numUsers, startTime, stopTime, sampleTime, configConst, configAoI, configChannel, minimumElev)

%%Adding general path for all helper functions
addpath('ChannelModel/user behavior functions/'); %helper functions for user behavior modeling
addpath('ChannelModel/satellite_helper_functions/'); %helper functions for satellite filtering
addpath('ChannelModel/channel_helper_functions/'); %helper functions for channel modeling
addpath('ChannelModel/preassignment_diagnostics/'); %Presentation plots

%%Init starting satellite scenario object with time intervals of reference
simulationScenario = satelliteScenario(startTime, stopTime, sampleTime);

% CALL SATELLITE FUNCTION - defines the Starlink shell 2 constallation
simulationScenario=Satellite_constellation(configConst, simulationScenario);%"ends timer"

% CALL USER FUNCTION to generate the non uniform users' distribution
[simulationScenario, groundEnv]=User_behavior(configAoI, numUsers, simulationScenario); 

% REDUCING SATELLITAR OBJECTS TO USER-ONLY RELEVANT SATELLITES
visibilityData = Filter_constellation(simulationScenario, minimumElev);

% COMPUTATION OF THE SATELLITAR LINK STATISTICS AND CHANNEL SIMULATION
USER_SAT_evolution = channel_model(configChannel, visibilityData, groundEnv);
end