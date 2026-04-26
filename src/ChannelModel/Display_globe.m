%% Display_globe function
% This function displays the 3D view of the globe, highligthing the users
% and the satellites after filtering

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. filteredSimScen: filtered satelliteScenario object of the toolbox

function []=Display_globe(filteredSimScen)

% DEBUGGING PURPOSES VISUALIZATION
viewer = satelliteScenarioViewer(filteredSimScen);

% Show orbit traces
orb = orbit(filteredSimScen.Satellites);
show(orb);

play(filteredSimScen);


end