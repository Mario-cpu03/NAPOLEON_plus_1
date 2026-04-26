%% Filter_constellation function
% This function instantiate a new SatelliteScenario object that describes
% the filtered constellation. The goal is to filter out the original
% Starlink constellation by reducing the amount of satellites to only those 
% that may be relevant to the association & handover problem. That is, the
% satellites that any ground station cannot see during the simulation
% window, given a certain elevation treshhold assumed fundamental to
% guarantee a certain QoS.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. minimumElev: treshhold elevation angle between ground stations and
%       satellites
% 
%       2. simulationScenario: satelliteScenario object of the toolbox
%       from which GroundStation objects and Satellite objects can be
%       accessed. This object will be thus deleted for Memory Occupancy
%       optimization

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. filteredSimScen: satelliteScenario object of the toolbox updated
%       with the filtered Satellite objects

function [filteredSimScen]=Filter_constellation(simulationScenario, minimumElev)


end