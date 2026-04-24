%% channel_model function
% This function defines the (random) information signal sent from each user
% and filters them simulating the LMS channel in compliance with the ITU-R 
% P.681 family. The goal is to obtain a representation of the
% overtime evolution of the user-satellite links by means of path gains,
% states, range and elevation.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. configChannel : Data Strcuture containing the parameters needed
%       to configurate the channel:
%                   (i) the carrier frequency
%                   (ii) the mobile speed
%                   (iii) the sample rate
%
%       2. groundEnv: column vector of size numUsers containing each
%       ground station's environment.
%
%       3. filteredSimScen : satelliteScenario object of the toolbox updated
%       with the filtered Satellite objects

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. USER_SAT_evolution: 


function [USER_SAT_evolution]=channel_model(configChannel, filteredSimScen, groundEnv)


end