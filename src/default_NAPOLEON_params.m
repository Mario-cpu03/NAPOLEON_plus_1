function params = default_NAPOLEON_params()
%DEFAULT_NAPOLEON_PARAMS Default parameters for NAPOLEON+.
%
% These parameters are used by:
%   - the legacy script NAPOLEON_plus_1.m
%   - the future GUI
%   - the backend wrapper run_NAPOLEON_plus.m

    %% Reproducibility
    params.seed = 13;

    %% User-facing inputs
    params.numUsers = 100;
    params.CSImode = "forecast";              % "forecast" or "ideal"
    params.associationAlgorithm = "eMBB";    % "URLLC" or "eMBB"

    %% Time settings
    params.startTime = datetime('today');
    params.simulationDuration_min = 192;      % 3 h 12 min
    params.sampleTime_s = 20;

    %% Fixed constellation profile
    params.constellation.planes = 72;
    params.constellation.satellitesPerPlane = 22;
    params.constellation.inclination_deg = 53.2;
    params.constellation.phasingParam = 17;
    params.constellation.altitude_km = 540;

    %% Fixed Area of Interest profile
    params.AoI.latMin = 35;
    params.AoI.latMax = 60;
    params.AoI.lonMin = -10;
    params.AoI.lonMax = 30;
    params.AoI.deltaLat = 2;
    params.AoI.deltaLon = 2;

    %% Fixed elevation threshold
    params.minimumElevation_deg = 25;

    %% Fixed radio/channel profile
    params.channel.satellitePower_W = 1;
    params.channel.satelliteGain_dBi = 50;
    params.channel.userGain_dBi = 0;
    params.channel.systemTemperature_K = 290;
    params.channel.bandwidth_Hz = 5e6;
    params.channel.carrierFrequency_Hz = 2e9;
    params.channel.mobileSpeed_kmh = 5;
    params.channel.sampleRate_Hz = 100;

    %% Association/load profile
    params.association.satelliteCapacity = 2;

    %% URLLC tunable policy parameters
    params.policy.URLLC.URLLC_DeltaTau_switch_s = 1.00e-3;
    params.policy.URLLC.latency_max_URLLC = 3e-3;
    params.policy.URLLC.SNRmin_URLLC_lin = 10;
    params.policy.URLLC.time_window = 6;
    params.policy.URLLC.handoverMax_URLLC = 1;
    params.policy.URLLC.percentile_URLLC = 0.90;

    %% eMBB tunable policy parameters
    params.policy.eMBB.eMBB_DeltaR_switch_bps = 2e6;
    params.policy.eMBB.rateMin_eMBB_bps = 50e6;
    params.policy.eMBB.time_window = 13;
    params.policy.eMBB.handoverMax_eMBB = 4;
end