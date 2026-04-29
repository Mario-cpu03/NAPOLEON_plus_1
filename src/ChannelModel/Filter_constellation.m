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

%%Object recollection. 
% Satellites and ground stations directly from the scenario object
S= simulationScenario.Satellites;
Gs= simulationScenario.GroundStations;

%%Time axis reconstruction
% The static filtering is performed over the whole simulation window, with
% the same temporal resolution of the original scenario
timeVec = simulationScenario.StartTime : seconds(simulationScenario.SampleTime) : simulationScenario.StopTime;


%%Logical vector for the retained satellites
% filtSat(currentSat)=true means that the satellite is visible to at least
% one ground station, at least once, above the prescribed threshold
filtSat = false(1, numel(S));

%%Main loop for the static filtering
% For each satellite, we scan all the ground stations. As soon as one
% ground station sees that satellite above threshold at least once in the
% simulation window, the satellite is marked as relevant and we stop
% checking the remaining ground stations for that satellite

for currentSat = 1:numel(S)
    for currentGs = 1:numel(Gs)
        for currentTime = 1:numel(timeVec)
            [~, elevationDeg, ~] = aer(Gs(currentGs), S(currentSat), timeVec(currentTime));
            if elevationDeg >= minimumElev
                filtSat(currentSat) = true;
                break;
            end
        end
    end
end

%% Vector of retained satellite indices

filtSatIdx = find(filtSat);

%% Creation of the filtered scenario
% The filtered scenario preserves the same simulation window and sample
% time of the original one

filteredSimScen = satelliteScenario( ...
    simulationScenario.StartTime, ...
    simulationScenario.StopTime, ...
    simulationScenario.SampleTime);

% Copy of the ground stations into the filtered scenario
for currentGs = 1:numel(Gs)
    groundStation(filteredSimScen, ...
        Gs(currentGs).Latitude, ...
        Gs(currentGs).Longitude, ...
        Name=string(Gs(currentGs).Name));
end

%%Reconstruction of the retained satellites
% The retained satellites are reconstructed through the same vectorized
% strategy adopted in Satellite_constellation, in order to reduce the
% overhead due to repeated access to the satelliteScenario object.

beta = configConst.phasingParam*(360)/(configConst.planes*configConst.satPlanes);

numfiltSats = numel(filtSatIdx);

% Preallocation of the orbital parameters arrays
semiMajorAxis_array = zeros(numfiltSats,1);
eccentricity_array = zeros(numfiltSats,1);
inclination_array = zeros(numfiltSats,1);
raan_array = zeros(numfiltSats,1);
argumentPeriapsis_array = zeros(numfiltSats,1);
trueAnomaly_array = zeros(numfiltSats,1);
satelliteName_array = strings(numfiltSats,1);

for filtSatLocalIdx = 1:numfiltSats

    currentSatGlobalIdx = keptSatIdx(filtSatLocalIdx);

    % Mapping from global satellite index to:
    %   (i) orbital plane index
    %   (ii) satellite index inside that plane
    currentPlane = ceil(currentSatGlobalIdx/configConst.satPlanes);
    currentSatInPlane = currentSatGlobalIdx - (currentPlane-1)*configConst.satPlanes;

    % Orbital parameters computation
    raan = (currentPlane-1)*360/configConst.planes;

    nu = (currentSatInPlane - 1)*360/configConst.satPlanes;
    nu = mod(nu + (currentPlane-1)*beta,360);

    % Orbital parameters storage
    semiMajorAxis_array(filtSatLocalIdx) = (6371 + configConst.altitude)*1e3;
    eccentricity_array(filtSatLocalIdx) = 0;
    inclination_array(filtSatLocalIdx) = configConst.inclination;
    raan_array(filtSatLocalIdx) = raan;
    argumentPeriapsis_array(filtSatLocalIdx) = 0;
    trueAnomaly_array(filtSatLocalIdx) = nu;

    % Satellite name storage
    satelliteName_array(filtSatLocalIdx) = sprintf("SAT_%d_%d", currentPlane, currentSatInPlane);

end

% Vectorized creation of the retained satellites
satellite(filteredSimScen, ...
    semiMajorAxis_array, ...
    eccentricity_array, ...
    inclination_array, ...
    raan_array, ...
    argumentPeriapsis_array, ...
    trueAnomaly_array, ...
    Name=satelliteName_array);

end