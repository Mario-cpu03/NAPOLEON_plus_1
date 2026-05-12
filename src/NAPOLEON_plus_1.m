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

numUsers = 1000; % Example number of users, TODO GUI. Momentarily hard-coded
% When the GUI will be implemented, an exception management shall be
% developed: either the end-user can choose numUsers from a pool of
% available values or, if numUsers is over a certain range, it will be
% asked to set a new value

% From the GUI the end-user is able to select wheter the simulation mode is
% ideal or forecast, in order to be able to test both an ideal and a 
% plausible version of the same policies-dependant hunagiran implementation.
mode = "forecast"; %mode = "ideal";

% From the GUI the end-user is able to select the nature of the association
% alroithm from a pool of pre-defined policies. Another possible choice is
% to enable the user to manually select the amount of "reward" and "penalization"
% of each relevant quantity. The latter of the two options requires an
% higher end-user knowledge but offers more flexibility; on the other hand,
% the first option may be easier to develop but more expensive to compute, plus
% it requires hard-coded weights and fixed kinds of algorithms. 



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

[USER_SAT_evolution]=main_channel_function(numUsers, startTime, stopTime, sampleTime, mode);


%%%%%% ------ USER SATELLITE ASSOCIATION MODULE EXECUTION ----- %%%%%%
% We call the main_channel_function to obtain the history of association
% outcomes, dictated by each algorithm, between user and
% satellites. The USER_SAT_association datastracture is the object of
% relevance and it is organized as:
%           (i) TO DEFINE ....