%% Main Function NAPOLEON+ SIMULATOR
% A simulator for the User - Satellite Association and Handover 
% algorithms Evaluation. 
% TEAM 1:   
%           Ambrosone Mario Pellegrino
%           La Spina Santi
%           Gohite Aditya
%
% Main Script responsible for the execution and call of all the other
% modules main functions. 

close all; clc; clear

rng(13); %%Seed for reproducibility

%%%%%%% ------- MODULES VISIBILITY SETTINGS ------ %%%%%%%
% We make the path of each module, hence each directory, visible from the
% main function
addpath('ChannelModel'); addpath('UserSatAssoc');addpath('KPIs');addpath('GUI'); 

%%%%%%% ------- SCENARIO SETTINGS ------ %%%%%%%
% We fix the simulation time to the orbital period od a single satellite.
% Regarless of its position with respect to a given user, to avoid
% one-day-long simulation with 15 satellitar orbits

startTime  = datetime('today');
stopTime   = startTime + hours(1) + minutes(36);

% At h = 540 km and elevation >= 35 deg, a favorable pass lasts
% about tVis = 190 s. To fix the sample time at 10 seconds means to have a
% total number of samples in the visibility window of about
% sampleTime = tVis / N => N ~ 190 / 10 = 19 samples

% A lighter version to fix approximately 8 samples per visibility time,
% similarly, yields sampleTime = 24s, with some margin for shorter passage
% we may fix sampleTime = 20. That is, a total of 289 samples in the 1h35m
% simulation time window.
sampleTime = 20; % seconds


%%%%%% ------ GUI DEPENDANT QUANTITIES ----- %%%%%%
% From the GUI the end-user is able to fix the number of simulated users/gb
% as an input parameter, either from a pool of available values or freely, in the
% order of ten, maximum a hundred for the sake of computational
% complexity at run time and correct functioning of the simulator

numUsers = 100; % Example number of users, TODO GUI. Momentarily hard-coded
% When the GUI will be implemented, an exception management shall be
% developed: either the end-user can choose numUsers from a pool of
% available values or, if numUsers is over a certain range, it will be
% asked to set a new value

% From the GUI the end-user is able to select wheter the simulation mode is
% ideal or forecast, in order to be able to test both an ideal and a 
% plausible version of the same policies-dependant hunagiran implementation.
mode = "forecast"; %mode = "ideal";

% From the GUI the end-user is able to select the nature of the association
% alroithm from a pool of two pre-defined IMT-2020 inspired policies:
%   (i) URLLC-based algorithm, for a low latency (minimum distance)
%   Hand-over aware algorithm.
%
%   (ii) eMBB-based algorithm, for a maximum throughput, minimum HO
%   algorithm.
association_algorithm = "URLLC"; % association_algorithm = "eMBB"


%%%%%% ------ CONFIGURATION DATA STRUCTURES ----- %%%%%%

% CONFIG structure for the constellation deployment. The parameters
% chosen are to be found on paragraph 4 chapter 2 of the FCC 21-48.
configConst = struct( ...
              'planes', 72, ... % Total number of orbital planes, integer variable, must be reduced in Filter_constellation 
              'satPlanes', 22, ... % Total number of satellites per plane, integer variable, most probably will not be reduced in Filter_constellation 
              'inclination', 53.2, ... % Equatorial inclination of the orbit, float variable, .2 degrees more inclinated than 2020 constellation
              'phasingParam', 17, ... % Phasing param multiplying phasing offset obtained in Phasing Parameter Analysis for Satellite Collision Avoidance in Starlink and Kuiper Constellations
              'altitude', 540); % Altitude of the (second) shell

% CONFIG structure for the AoI and BS deployment.
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

% CONFIG minimum elevation threshold for satellite filtering and 
% weight normalization according to FCC 21-48 documentation.
minimumElev = 25;

% CONFIG channel parameters for both ChannelModel and UserSatAssoc modules
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
    'traceLengthSamples', 2000, ... %number of samples obtained as the channel sample rate times the sample time of the simulator: 100[1/s]*20[s] = 2000
    'CSImode', mode); %mode of the channel. See channel_model for more information
%%NOTE on the sample rate:
% p681LMSChannel requires fD_mobile + |fD_sat| < f_sampling/10.
% Here fD_sat = 0 by default, thus for fD_mobile = 9.26567 Hz,
% we have that f_samling must be > 92.6567 Hz.


%%%%%% ------ CHANNEL MODEL MODULE EXECUTION ----- %%%%%%
% We call the main_channel_function to obtain the temporal evolution of the
% satellite - user links. The USER_SAT_evolution datastructure is the
% object of relevance. It is organized as a structure of:
%           (i) tensors, one per needed quantity,
%           (SNR, rate, distance, average path gain, class of the elevation,
%           and valid links);
%           (ii) control informations to enable the analysis of said
%           quantities by the UserSatAssoc module (time vector, number of users,
%           number of satellites and number of time samples)

[USER_SAT_evolution]=main_channel_function(numUsers, startTime, stopTime, sampleTime, configConst, configAoI, configChannel, minimumElev);


%%%%%% ------ USER SATELLITE ASSOCIATION MODULE EXECUTION ----- %%%%%%
% We call the main_association_function to obtain the history of association
% outcomes, dictated by each algorithm, between user and
% satellites.
% 
% The USER_SAT_association datastracture is the object of
% relevance and it is organized as:
%           (i) TO DEFINE ....

%[USER_SAT_association]=main_association_function(USER_SAT_evolution, association_algorithm);


%%%%%% ------ KPI MODULE EXECUTION ----- %%%%%%
% We call the main_KPI_function to obtain the evaluation by means of
% KeyPerformanceIndicators of the association algorithm that the end-user
% has selected when interacting with the simulator

%KPI_results = main_KPI_function(USER_SAT_association, USER_SAT_evolution, mode, );