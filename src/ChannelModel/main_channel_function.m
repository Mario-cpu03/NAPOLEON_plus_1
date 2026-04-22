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
%       2.  USERS_Set: Data Structure containing the set of users with (i) 
%       their position (coordinates), (ii) the kind of environment they are
%       in
% 
%       3.  USER_SAT_evolution: Array of Data Structures containing the time
%       evolution of the channel's parameters of each user-satellite link.

function [SATELLITE_Set, USERS_Set, USER_SAT_evolution]=main_channel_function(numUsers, startTime, stopTime, sampleTime)

% Init output structures
filteredSatellite_Set = struct();
SATELLITE_Set = struct();
USERS_Set = struct();
USER_SAT_evolution = struct();

% Constellation fixed parameters. We model a Starlink constellation, namely
% the first shell constellation according to the FCC 21-48 documentation.
% We note that

% Init user parameters.  We assume a small italy-centric portion of europe,
% in which a multi distributed user behavior is assumed. The
% users are static (mobile speed = 0) for simplicity. The user may as well
% be though of as base stations, hence antennas.

% CALL SATELLITE FUNCTION - defines the Starlink shell 1 constallation
SATELLITE_Set = Satellite_constellation(); 

% CALL USER FUNCTION
USERS_Set = User_behavior(); 

% REDUCING SATELLITAR OBJECTS TO USER-ONLY RELEVANT SATELLITES
filteredSatellite_Set = Filter_constellation(SATELLITE_Set, USERS_Set); %

% CALL DISPLAY FUNCTION
Display_globe(filteredSatellite_Set, USERS_Set); 

% COMPUTATION OF THE SATELLITAR LINK STATISTICS AND CHANNEL SIMULATION
USER_SAT_evolution = channel_model();

end