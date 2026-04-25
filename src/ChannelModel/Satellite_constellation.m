%% Satellite_constellation function
% This function computes the whole First Shell Starlink Constellation in
% compliance with the FCC 21-48 authorization. That is, the 540km altitude, 
% 72 orbital planes, 22 satellites per orbital plane, constellation. 

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. configConst : Data Strcuture containing the parameters needed
%       to configurate the constellation:
%                   (i) the number of orbital planes
%                   (ii) the number of satellite per planes
%                   (iii) the altitude of the constellation
%                   (iv) the inclination with respect to the equatorial 
%                       line of the planes
%                   (v) the phasing parameter to offset satellites on
%                       different planes
%
%       2. simulationScenario : satelliteScenario object of the toolbox to
%       be updated with the Satellite objects
%

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. simulationScenario : updated simulationScenario where the satellites
%       can be accessed as Satellites object

function [simulationScenario]=Satellite_constellation(configConst, simulationScenario)

end