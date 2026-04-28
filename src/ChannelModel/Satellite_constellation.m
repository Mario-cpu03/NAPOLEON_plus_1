%% Satellite_constellation function
% This function computes the whole second Shell Starlink Constellation in
% compliance with the FCC 21-48 authorization. That is, the 540km altitude, 
% 72 orbital planes, 22 satellites per orbital plane, constellation. 
%
% In order to improve the computational efficiency of the simulator, the
% satellite objects are not instantiated one-by-one inside the nested loop.
% Instead, the nested loop is used to compute the orbital elements of each
% satellite, which are then passed to the satelliteScenario object through a
% single vectorized satellite() call.

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

% Define phase offset parametrized via F
beta = configConst.phasingParam*(360)/(configConst.planes*configConst.satPlanes);

% Define the total number of satellites in the constellation
numSatellites = configConst.planes*configConst.satPlanes;

% Preallocation of the orbital parameters arrays. The scope of these arrays
% is to store the orbital elements of each satellite before the actual
% creation of the Satellite objects in the scenario.
semiMajorAxis_array = zeros(numSatellites,1);
eccentricity_array = zeros(numSatellites,1);
inclination_array = zeros(numSatellites,1);
raan_array = zeros(numSatellites,1);
argumentPeriapsis_array = zeros(numSatellites,1);
trueAnomaly_array = zeros(numSatellites,1);
satelliteName_array = strings(numSatellites,1);

% Satellite index used to fill the orbital parameters arrays progressively
satelliteIndex = 0;

%% Main loop for the construction of the orbital parameters arrays
for currentPlane = 1:configConst.planes

    % Right Ascension of the Ascending Node computation. We need to space
    % planes of a deltaquantity (the raan) so that they are equispaced.
    raan = (currentPlane-1)*360/configConst.planes;

    %% Loop for the satellite allocation 
    % For each currentSat, we compute the orbital elements corresponding to
    % the satellite that will be instantiated in each plane.
    for currentSat = 1:configConst.satPlanes

        satelliteIndex = satelliteIndex + 1;

        nu = (currentSat - 1)*360/configConst.satPlanes; % true anomaly, or nu, representing the satellite position across its plane
        nu = mod(nu + (currentPlane-1)*beta,360); % plane dependant phase shift compliant with Optimization of User–LEO Satellite Assignments

        % Orbital parameters storage
        semiMajorAxis_array(satelliteIndex) = (6371 + configConst.altitude)*1e3; % 6371 is the Earth radius, whilst the whole computation is the semi major axis of rotation of the satellites
        eccentricity_array(satelliteIndex) = 0;
        inclination_array(satelliteIndex) = configConst.inclination;
        raan_array(satelliteIndex) = raan;
        argumentPeriapsis_array(satelliteIndex) = 0;
        trueAnomaly_array(satelliteIndex) = nu;

        % Satellite name storage
        satelliteName_array(satelliteIndex) = sprintf("SAT_%d_%d", currentPlane, currentSat); % name of each satellite of the format: SAT_#plane_#satellite

    end
end

% Satellite objects creation. This is intentionally performed only once,
% instead of calling satellite() inside the nested loop. This should reduce
% the overhead due to repeated access to the satelliteScenario object.
satellite(simulationScenario, ...
    semiMajorAxis_array, ...
    eccentricity_array, ...
    inclination_array, ...
    raan_array, ...
    argumentPeriapsis_array, ...
    trueAnomaly_array, ...
    Name=satelliteName_array);

end