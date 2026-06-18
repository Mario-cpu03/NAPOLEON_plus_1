function RESULTS = run_NAPOLEON_simulation(SCENARIO, params)
%RUN_NAPOLEON_SIMULATION Run association and KPI evaluation.
%
% GUI button:
%   Run Association
%
% This function assumes that run_NAPOLEON_scenario(params) has already
% generated USER_SAT_evolution.

    if nargin < 1 || isempty(SCENARIO)
        error("SCENARIO is required. Run run_NAPOLEON_scenario(params) first.");
    end

    if nargin < 2 || isempty(params)
        if isfield(SCENARIO, 'params')
            params = SCENARIO.params;
        else
            params = default_NAPOLEON_params();
        end
    end

    validate_NAPOLEON_params(params);

    %% Robust path handling
rootDir = fileparts(mfilename('fullpath'));

addpath(rootDir);
addpath(genpath(fullfile(rootDir, 'ChannelModel')));
addpath(genpath(fullfile(rootDir, 'UserSatAssoc')));
addpath(genpath(fullfile(rootDir, 'KPIs')));
addpath(genpath(fullfile(rootDir, 'GUI')));

    %% Check scenario content
    if ~isfield(SCENARIO, 'USER_SAT_evolution') || isempty(SCENARIO.USER_SAT_evolution)
        error("SCENARIO.USER_SAT_evolution is missing or empty.");
    end

    USER_SAT_evolution = SCENARIO.USER_SAT_evolution;

    %% Association configuration
    configChannel = SCENARIO.configChannel;
    configConst = SCENARIO.configConst;
    minimumElev = SCENARIO.minimumElev;

    association_algorithm = string(params.associationAlgorithm);

    configAssociation = struct( ...
        'association_algorithm', association_algorithm, ...
        'carrierFrequency', configChannel.carrierFrequency, ...
        'P_sat_lin', configChannel.P_sat_lin, ...
        'G_sat_lin', configChannel.G_sat_lin, ...
        'G_u_lin', configChannel.G_u_lin, ...
        'channel_bandwidth', configChannel.channel_bandwidth, ...
        'N_0', configChannel.N_0, ...
        'minimumElev', minimumElev, ...
        'altitude_satellites_m', configConst.altitude * 1e3, ...
        'altitude_groundStation_m', 0, ...
        'G', params.association.satelliteCapacity, ...
        'URLLC_DeltaTau_switch_s', params.policy.URLLC.URLLC_DeltaTau_switch_s, ...
        'eMBB_DeltaR_switch_bps', params.policy.eMBB.eMBB_DeltaR_switch_bps);

    %% KPI configuration
    URLLC = struct( ...
        'latency_max_URLLC', params.policy.URLLC.latency_max_URLLC, ...
        'SNRmin_URLLC', params.policy.URLLC.SNRmin_URLLC_lin, ...
        'handoverMax_URLLC', params.policy.URLLC.handoverMax_URLLC, ...
        'percentile_URLLC', params.policy.URLLC.percentile_URLLC, ...
        'time_window', params.policy.URLLC.time_window);

    eMBB = struct( ...
        'rateMin_eMBB', params.policy.eMBB.rateMin_eMBB_bps, ...
        'handoverMax_eMBB', params.policy.eMBB.handoverMax_eMBB, ...
        'time_window', params.policy.eMBB.time_window, ...
        'bandwidth_Hz', configChannel.channel_bandwidth);

    configKPI = struct();
    configKPI.URLLC = URLLC;
    configKPI.eMBB = eMBB;

    %% Execute association
    USER_SAT_association = main_association_function( ...
        USER_SAT_evolution, ...
        configAssociation);

    %% Execute KPI evaluation
    KPI_results = main_KPI_function( ...
        USER_SAT_association, ...
        configKPI);

    %% Return results object
    RESULTS = struct();

    RESULTS.params = params;

    RESULTS.configAssociation = configAssociation;
    RESULTS.configKPI = configKPI;

    RESULTS.USER_SAT_association = USER_SAT_association;
    RESULTS.KPI_results = KPI_results;

    RESULTS.associationCompleted = true;
end