%% Filtered_satellite function
% This function computes the time-evolution filtering of the full
% constellation. The goal is determine, for each time step and
% for each ground station, the set of satellites that are visible above a
% prescribed elevation threshold, which is in compliance with the 
% FCC 21-48 directives.
% The main idea is to make the expensive visibility computation via a numerical 
% ECEF-based engine, avoiding repeated calls to aer().
%
% The output is a time-indexed data structure containing:
%       (i)   the simulation time vector,
%       (ii)  the visible satellites for each user at each time step,
%       (iii) the corresponding elevation angles,
%       (iv)  the corresponding slant distances.
%
% IMPORTANT:
% The function assumes that the input satelliteScenario object already
% contains both Satellite objects and GroundStation objects.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. simulationScenario : satelliteScenario object of the toolbox
%       containing the full constellation and the ground stations
%
%       2. minimumElev : minimum elevation threshold [deg] used to decide
%       whether a satellite is visible or not at a given time step

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. visibilityData : Data Structure containing the dynamic
%       visibility information:
%                   (i)   timeVec : row vector of simulation times
%                   (ii)  visibleSatIdx : cell array of size [T,U], where
%                         each cell contains the indices of the satellites
%                         visible to user u at time step t
%                   (iii) elevationDeg : cell array of size [T,U], where
%                         each cell contains the elevations of the visible
%                         satellites
%                   (iv)  distanceKm : cell array of size [T,U], where each
%                         cell contains the slant distances of the visible
%                         satellites
%                   (v)   visibilityMask : logical array of size [U,S,T]
%                   (vi)  elevationMatrix : array of size [U,S,T]
%                   (vii) distanceMatrix : array of size [U,S,T]
%                   (viii) numUsers : number of ground stations
%                   (ix)  numSats : number of satellites
%                   (x)   numTimeSteps : number of time samples

function [visibilityData] = Filter_constellation(simulationScenario, minimumElev)


end