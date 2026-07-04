function validate_NAPOLEON_params(params)
%VALIDATE_NAPOLEON_PARAMS Basic validation for NAPOLEON+ parameters.
%
% This function checks hard errors only.
% GUI-specific warnings, such as numUsers > 600, should be handled by the GUI.

    %% Required top-level fields
    requiredTop = { ...
        'seed', ...
        'numUsers', ...
        'CSImode', ...
        'associationAlgorithm', ...
        'startTime', ...
        'simulationDuration_min', ...
        'sampleTime_s', ...
        'constellation', ...
        'AoI', ...
        'minimumElevation_deg', ...
        'channel', ...
        'association', ...
        'policy'};

    for k = 1:numel(requiredTop)
        if ~isfield(params, requiredTop{k})
            error("Missing params.%s", requiredTop{k});
        end
    end

    %% User-facing inputs
    if ~isscalar(params.numUsers) || params.numUsers <= 0 || params.numUsers ~= round(params.numUsers)
        error("params.numUsers must be a positive integer.");
    end

    validCSIModes = ["forecast", "ideal"];
    if ~any(strcmpi(string(params.CSImode), validCSIModes))
        error("params.CSImode must be either 'forecast' or 'ideal'.");
    end

    validAlgorithms = ["URLLC", "eMBB"];
    if ~any(strcmpi(string(params.associationAlgorithm), validAlgorithms))
        error("params.associationAlgorithm must be either 'URLLC' or 'eMBB'.");
    end

    if params.simulationDuration_min <= 0
        error("params.simulationDuration_min must be positive.");
    end

    if params.sampleTime_s <= 0
        error("params.sampleTime_s must be positive.");
    end

    %% Fixed geometry sanity checks
    if params.constellation.planes <= 0 || params.constellation.planes ~= round(params.constellation.planes)
        error("params.constellation.planes must be a positive integer.");
    end

    if params.constellation.satellitesPerPlane <= 0 || params.constellation.satellitesPerPlane ~= round(params.constellation.satellitesPerPlane)
        error("params.constellation.satellitesPerPlane must be a positive integer.");
    end

    if params.constellation.altitude_km <= 0
        error("params.constellation.altitude_km must be positive.");
    end

    if params.constellation.inclination_deg < 0 || params.constellation.inclination_deg > 180
        error("params.constellation.inclination_deg must be between 0 and 180 degrees.");
    end

    if params.minimumElevation_deg < 0 || params.minimumElevation_deg >= 90
        error("params.minimumElevation_deg must be in [0, 90) degrees.");
    end

    %% AoI sanity checks
    if params.AoI.latMin >= params.AoI.latMax
        error("AoI latitude range is invalid.");
    end

    if params.AoI.lonMin >= params.AoI.lonMax
        error("AoI longitude range is invalid.");
    end

    if params.AoI.deltaLat <= 0 || params.AoI.deltaLon <= 0
        error("AoI grid spacings must be positive.");
    end

    %% Channel sanity checks
    if params.channel.satellitePower_W <= 0
        error("Satellite power must be positive.");
    end

    if params.channel.bandwidth_Hz <= 0
        error("Bandwidth must be positive.");
    end

    if params.channel.carrierFrequency_Hz <= 0
        error("Carrier frequency must be positive.");
    end

    if params.channel.systemTemperature_K <= 0
        error("System temperature must be positive.");
    end

    if params.channel.sampleRate_Hz <= 0
        error("Channel sample rate must be positive.");
    end

    %% Doppler sampling sanity check
    c = physconst("LightSpeed");
    mobileSpeed_mps = params.channel.mobileSpeed_kmh / 3.6;
    fD_mobile = mobileSpeed_mps * params.channel.carrierFrequency_Hz / c;

    if params.channel.sampleRate_Hz <= 10 * fD_mobile
        error("Channel sample rate must be greater than 10 times the mobile Doppler frequency.");
    end

    %% Policy validation
    validate_URLLC(params.policy.URLLC);
    validate_eMBB(params.policy.eMBB);
end

function validate_URLLC(URLLC)

    if URLLC.URLLC_DeltaTau_switch_s <= 0
        error("URLLC_DeltaTau_switch_s must be positive.");
    end

    if URLLC.latency_max_URLLC <= 0
        error("latency_max_URLLC must be positive.");
    end

    if URLLC.SNRmin_URLLC_lin <= 0
        error("SNRmin_URLLC_lin must be positive.");
    end

    if URLLC.time_window <= 0 || URLLC.time_window ~= round(URLLC.time_window)
        error("URLLC time_window must be a positive integer.");
    end

    if URLLC.handoverMax_URLLC < 0 || URLLC.handoverMax_URLLC ~= round(URLLC.handoverMax_URLLC)
        error("handoverMax_URLLC must be a non-negative integer.");
    end

    if URLLC.percentile_URLLC <= 0 || URLLC.percentile_URLLC > 1
        error("percentile_URLLC must be in (0, 1].");
    end
end

function validate_eMBB(eMBB)

    if eMBB.eMBB_DeltaR_switch_bps <= 0
        error("eMBB_DeltaR_switch_bps must be positive.");
    end

    if eMBB.rateMin_eMBB_bps <= 0
        error("rateMin_eMBB_bps must be positive.");
    end

    if eMBB.time_window <= 0 || eMBB.time_window ~= round(eMBB.time_window)
        error("eMBB time_window must be a positive integer.");
    end

    if eMBB.handoverMax_eMBB < 0 || eMBB.handoverMax_eMBB ~= round(eMBB.handoverMax_eMBB)
        error("handoverMax_eMBB must be a non-negative integer.");
    end
end