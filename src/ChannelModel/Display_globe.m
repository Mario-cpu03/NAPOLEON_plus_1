%% Display_globe function
% This function displays the 3D view of the globe, highligthing the users
% and the satellites.
% In particular, the function:
%       (i) opens the 3D globe viewer,
%       (ii) displays the orbital traces of the satellites,
%       (iii) enables labels for both satellites and ground stations,
%       (iv) plays the scenario evolution over time.
%

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. simulationScenario: filtered satelliteScenario object of the toolbox

function []=Display_globe(simulationScenario)

% satellites and ground stations directly from the scenario
% object so that their graphical properties can be modified before playing
% the simulation
S= simulationScenario.Satellites;
Gs= simulationScenario.GroundStations;

% The viewer is the object responsible for the visualization of the
% satelliteScenario on the 3D globe
viewer = satelliteScenarioViewer(simulationScenario);

% Display the actual satellites (and check if there are any, hence if the 
% structure has been correctly instantiated)
if ~isempty(S)
    show(orbit(S));

    for currentSat = 1:numel(S)
        S(currentSat).ShowLabel = true;
        S(currentSat).LabelFontSize = 6;
    end
end

% Display the ground stations (and check if there are any, hence if the 
% structure has been correctly instantiated)
if ~isempty(Gs)
    for currentGs = 1:numel(Gs)
        Gs(currentGs).ShowLabel = true;
        Gs(currentGs).LabelFontSize = 6;
    end
end

% Show orbit traces
orb = orbit(simulationScenario.Satellites);
show(orb);

% Once all graphical settings have been configured, the scenario is played
% over the considered simulation time window
play(simulationScenario);

end