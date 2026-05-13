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
%       3.  USER_SAT_evolution: Data Structure of tensors containing the time
%       evolution of the channel's parameters of each user-satellite link.

function [USER_SAT_evolution]=main_channel_function(numUsers, startTime, stopTime, sampleTime, mode)

tic
%%Adding general path for all helper functions
addpath('ChannelModel/user behavior functions'); %helper functions for user behavior modeling
addpath('ChannelModel/satellite_helper_functions'); %helper functions for satellite filtering
addpath('ChannelModel/channel_helper_functions'); %helper functions for channel modeling
addpath('ChannelModel/preassignment_diagnostics/'); %Presentation plots

rng(13); %%Seed for reproducibility

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

%%Init channel parameters
% Those parameters are selected in compliance with the ITU-R P.681-10, but
% not in full consistency with the Starlink shells, whose operation bands
% are the Ku and Ka band.
k_B = 1.380649e-23; %Boltzmann konstant
T_sys = 290; %std teemparature for noise computation
B = 5e6; % bandwidth 5MHz 

configChannel = struct( ...
    'P_sat_lin', 1, ... % power of the signal, one watt as a starting base, may be varied if needed 
    'G_sat_lin', 10^(50/10), ... %gain of the satellite antenna
    'G_u_lin', 10^(0/10), ... %0dBi of gain for the user assuming isotropic antenas
    'N_0', k_B*T_sys*B, ... %noise power
    'channel_bandwidth', B, ... %bandwidth of the system on each channel
    'carrierFrequency', 2e9, ... %itu-r aligned carrier
    'mobileSpeed', 5000/3600, ... % assuming a 5km/h speed to obtain doppler shift: v=1.389m/s --> f_Dmobile = v*f_c/c = 9.2593 Hz approx 10Hz
    'sampleRate', 100, ... %see note below
    'traceLengthSamples', 2000, ... %number of samples obtained as the channel sample rate times the sample time of the simulator: 200[1/s]*20[s] = 4000
    'CSImode', mode); %mode of the channel. See channel_model for more information
%%NOTE on the sample rate:
% p681LMSChannel requires fD_mobile + |fD_sat| < f_sampling/10.
% Here fD_sat = 0 by default, thus for fD_mobile = 9.26567 Hz,
% we have that f_samling must be > 92.6567 Hz.


% CALL SATELLITE FUNCTION - defines the Starlink shell 1 constallation
simulationScenario=Satellite_constellation(configConst, simulationScenario);%"ends timer"

% CALL USER FUNCTION to generate the non uniform users' distribution
[simulationScenario, groundEnv]=User_behavior(configAoI, numUsers, simulationScenario); 

% REDUCING SATELLITAR OBJECTS TO USER-ONLY RELEVANT SATELLITES
visibilityData = Filter_constellation(simulationScenario, minimumElev);

% COMPUTATION OF THE SATELLITAR LINK STATISTICS AND CHANNEL SIMULATION
USER_SAT_evolution = channel_model(configChannel, visibilityData, groundEnv);
fprintf('Channel Sim time: %.3f s\n', toc);

snapshotTime=20;userIdx=1;

%plot_user_spatial_distribution(simulationScenario, configAoI)
Plot_link_chart(USER_SAT_evolution, snapshotTime, visibilityData, sampleTime, groundEnv)
%Plot_average_quant(snapshotTime, visibilityData, USER_SAT_evolution, sampleTime, userIdx)
%Display_system_snapshot(simulationScenario, snapshotTime, visibilityData, sampleTime)
%Display_globe(simulationScenario);
end