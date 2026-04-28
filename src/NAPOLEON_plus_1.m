%% Main Function NAPOLEON+ SIMULATOR
% A simulator for the User - Satellite Association and Handover 
% algorithms Evaluation. 
% TEAM 1:   
%           Ambrosone Mario Pellegrino - 360616
%           La Spina Santi - 
%           Gohite Aditya - 
%           Natalizi Giovanni - 
%
% Main Script responsible for the execution and call of all the other
% modules main functions. 

clc; close all; clear

%%%%%%% ------- SCENARIO SETTINGS ------ %%%%%%%
% We fix the simulation time to the orbital period od a single satellite.
% Regarless of its position with respect to a given user, to avoid
% one-day-long simulation with 15 satellitar orbits

startTime  = datetime('today');
stopTime   = startTime + hours(1) + minutes(36);
sampleTime = 60; % seconds, maybe less in future


%%%%%% ------ GUI DEPENDANT QUANTITIES ----- %%%%%%
% From the GUI the end-user is able to fix the number of simulated users/gb
% as an input parameter, either from a pool of available values or freely, in the
% order of ten, maximum a hundred for the sake of computational
% complexity at run time and correct functioning of the simulator

numUsers = 30; % Example number of users, TODO GUI. Momentarily hard-coded
% When the GUI will be implemented, an exception management shall be
% developed: either the end-user can choose numUsers from a pool of
% available values or, if numUsers is over a certain range, it will be
% asked to set a new value

%%%%%% ------ CHANNEL MODEL MODULE EXECUTION ----- %%%%%%
% We call the main_channel_function to obtain the temporal evolution of the
% satellite to user links. The USER_SAT_evolution datastructure is the
% object of relevance, as it contains:
%                                   (i) ... TODEFINE

% Init channel module output structure
USER_SAT_evolution = struct(); %cell vector

[USER_SAT_evolution]=main_channel_function(numUsers, startTime, stopTime, sampleTime)