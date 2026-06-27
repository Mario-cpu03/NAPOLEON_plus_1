function SCENARIO = run_NAPOLEON_scenario(params)
%RUN_NAPOLEON_SCENARIO Generate the NAPOLEON+ scenario.
%
% GUI button:
%   Generate Scenario
%
% This function executes only the ChannelModel module.
% It does NOT run association or KPI evaluation.

    if nargin < 1 || isempty(params)
        params = default_NAPOLEON_params();
    end

    validate_NAPOLEON_params(params);

    %% Robust path handling
rootDir = fileparts(mfilename('fullpath'));

addpath(rootDir);
addpath(genpath(fullfile(rootDir, 'ChannelModel')));
addpath(genpath(fullfile(rootDir, 'UserSatAssoc')));
addpath(genpath(fullfile(rootDir, 'KPIs')));
addpath(genpath(fullfile(rootDir, 'GUI')));
    %% Reproducibility
    rng(params.seed);

    %% Time settings
    startTime  = params.startTime;
    stopTime   = startTime + minutes(params.simulationDuration_min);
    sampleTime = params.sampleTime_s;

    %% User-facing settings
    numUsers = params.numUsers;
    mode = string(params.CSImode);

    %% Constellation configuration
    configConst = struct( ...
        'planes', params.constellation.planes, ...
        'satPlanes', params.constellation.satellitesPerPlane, ...
        'inclination', params.constellation.inclination_deg, ...
        'phasingParam', params.constellation.phasingParam, ...
        'altitude', params.constellation.altitude_km);

    %% Area of Interest configuration
    configAoI = struct( ...
        'latMin', params.AoI.latMin, ...
        'latMax', params.AoI.latMax, ...
        'lonMin', params.AoI.lonMin, ...
        'lonMax', params.AoI.lonMax, ...
        'deltaLat', params.AoI.deltaLat, ...
        'deltaLon', params.AoI.deltaLon);

    %% Minimum elevation
    minimumElev = params.minimumElevation_deg;

    %% Channel configuration
    k_B = 1.380649e-23;
    T_sys = params.channel.systemTemperature_K;
    B = params.channel.bandwidth_Hz;

    noisePower_W = k_B * T_sys * B;

    configChannel = struct( ...
        'P_sat_lin', params.channel.satellitePower_W, ...
        'G_sat_lin', 10^(params.channel.satelliteGain_dBi/10), ...
        'G_u_lin', 10^(params.channel.userGain_dBi/10), ...
        'N_0', noisePower_W, ...
        'channel_bandwidth', B, ...
        'carrierFrequency', params.channel.carrierFrequency_Hz, ...
        'mobileSpeed', params.channel.mobileSpeed_kmh / 3.6, ...
        'sampleRate', params.channel.sampleRate_Hz, ...
        'traceLengthSamples', round(params.channel.sampleRate_Hz * sampleTime), ...
        'CSImode', mode);

    %% Execute ChannelModel only
    USER_SAT_evolution = main_channel_function( ...
        numUsers, ...
        startTime, ...
        stopTime, ...
        sampleTime, ...
        configConst, ...
        configAoI, ...
        configChannel, ...
        minimumElev);

    %% Extract satelliteScenario if present
    if isfield(USER_SAT_evolution, 'satelliteScenario')
        satelliteScenarioObj = USER_SAT_evolution.satelliteScenario;
    else
        satelliteScenarioObj = [];
        warning("USER_SAT_evolution does not contain satelliteScenario.");
    end

    %% Return scenario object
    SCENARIO = struct();

    SCENARIO.params = params;

    SCENARIO.startTime = startTime;
    SCENARIO.stopTime = stopTime;
    SCENARIO.sampleTime = sampleTime;

    SCENARIO.configConst = configConst;
    SCENARIO.configAoI = configAoI;
    SCENARIO.configChannel = configChannel;
    SCENARIO.minimumElev = minimumElev;

    SCENARIO.USER_SAT_evolution = USER_SAT_evolution;
    SCENARIO.satelliteScenario = satelliteScenarioObj;

    SCENARIO.scenarioGenerated = true;
end