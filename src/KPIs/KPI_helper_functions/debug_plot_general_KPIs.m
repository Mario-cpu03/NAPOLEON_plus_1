%% Debugging General + Specific KPI Plotting Function
% DEBUGGING PURPOSES STRUCTURE
%
% This function gives a complete debugging overview of the algorithm:
%
% GENERAL KPIs:
%       (i)   cross-user mean rate evolution;
%       (ii)  cross-user mean SNR evolution;
%       (iii) time-averaged rate per user;
%       (iv)  time-averaged SNR per user;
%       (v)   distributional fairness CDFs;
%       (vi)  service ratio diagnostics;
%       (vii) representative-user selected-link QoS evolution.
%
% SPECIFIC KPIs:
%       If association_algorithm == "URLLC":
%           (i)  URLLC Temporal Compliance Ratio;
%           (ii) URLLC percentile latency evolution.
%
%       If association_algorithm == "eMBB":
%           (i)  eMBB Temporal Compliance Ratio;
%           (ii) eMBB system spectral efficiency evolution.
%
% IMPORTANT:
% In the representative-user section, the plotted rate and SNR are NOT
% averages. They are the sampled time evolution of the selected link of the
% chosen user. Since we work at single-connectivity, at each time step the
% selected user has at most one assigned satellite and therefore one
% realized rate and one realized SNR.

function debug_plot_general_KPIs(generalKPIs, specificKPIs, USER_SAT_association, configKPI, userIdx)
    %% INPUT CHECKS

    if nargin < 5 || isempty(userIdx)
        userIdx = 1;
    end

    numUsers = USER_SAT_association.numUsers;
    numTimeSteps = USER_SAT_association.numTimeSteps;

    if userIdx < 1 || userIdx > numUsers || userIdx ~= floor(userIdx)
        error('userIdx must be an integer between 1 and numUsers.');
    end

    if isfield(USER_SAT_association, 'timeVec')
        timeAxis = USER_SAT_association.timeVec;
        xLabelTime = 'Simulation time';
    else
        timeAxis = 1:numTimeSteps;
        xLabelTime = 'Time step';
    end

    userAxis = 1:numUsers;

    if isfield(USER_SAT_association, 'association_algorithm')
        association_algorithm = string(USER_SAT_association.association_algorithm);
    else
        association_algorithm = "UNKNOWN";
    end


    %% COMMAND WINDOW DEBUG SUMMARY

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('DEBUGGING PURPOSES STRUCTURE: GENERAL + SPECIFIC KPI SUMMARY\n');
    fprintf('============================================================\n');

    fprintf('\nSimulation size:\n');
    fprintf('  Number of users      : %d\n', numUsers);
    fprintf('  Number of time steps : %d\n', numTimeSteps);
    fprintf('  Association algorithm: %s\n', association_algorithm);

    fprintf('\nGeneral throughput KPIs:\n');
    fprintf('  Global mean of time-averaged user rate [Mbit/s] : %.6f\n', ...
        generalKPIs.throughput.globalAvgUserRate_Mbps);

    fprintf('\nGeneral SNR KPIs:\n');
    fprintf('  Global mean of time-averaged user SNR [dB] : %.6f\n', ...
        generalKPIs.SNR.globalAvgUserSNR_dB);

    fprintf('\nRepresentative-user QoS evolution:\n');
    fprintf('  Selected user       : %d\n', userIdx);
    fprintf('  User served ratio   : %.6f\n', ...
        generalKPIs.serviceContinuity.servedRatioPerUser(userIdx));

    if isfield(generalKPIs.serviceContinuity, 'userHandoverTime')
        fprintf('  User total handovers: %d\n', ...
            sum(generalKPIs.serviceContinuity.userHandoverTime(userIdx, :)));
    end

    fprintf('\nSystem service diagnostics:\n');
    fprintf('  System served ratio : %.6f\n', ...
        generalKPIs.serviceContinuity.servedRatioSystem);

    fprintf('\nSpecific KPI diagnostics:\n');

    switch association_algorithm

        case "URLLC"

            if isfield(specificKPIs, 'TCR_URLLC')
                fprintf('  Mean URLLC TCR : %.6f\n', ...
                    mean(specificKPIs.TCR_URLLC, 'omitnan'));
            end

            if isfield(specificKPIs, 'PL_URLLC_global')
                fprintf('  Global URLLC latency percentile [ms] : %.6f\n', ...
                    specificKPIs.PL_URLLC_global * 1e3);
            end

        case "eMBB"

            if isfield(specificKPIs, 'TCR_eMBB')
                fprintf('  Mean eMBB TCR : %.6f\n', ...
                    mean(specificKPIs.TCR_eMBB, 'omitnan'));
            end

            if isfield(specificKPIs, 'aggregateSpecEff')
                fprintf('  Mean eMBB system spectral efficiency [bit/s/Hz] : %.6f\n', ...
                    mean(specificKPIs.aggregateSpecEff, 'omitnan'));
            end

        otherwise

            fprintf('  No recognized specific KPI family.\n');

    end

    fprintf('============================================================\n\n');


    %% FIGURE 1: SYSTEM-LEVEL TIME EVOLUTION

    figure('Name', 'DEBUG - General KPIs - System-Level Time Evolution');

    subplot(2,1,1);
    stairs(timeAxis, generalKPIs.throughput.avgUserRateTime_Mbps, ...
           'LineWidth', 1.5);
    grid on;
    xlabel(xLabelTime);
    ylabel('Mean rate across users [Mbit/s]');
    title('Cross-user mean rate evolution');

    subplot(2,1,2);
    stairs(timeAxis, generalKPIs.SNR.avgUserSNRTime_dB, ...
           'LineWidth', 1.5);
    grid on;
    xlabel(xLabelTime);
    ylabel('Mean SNR across users [dB]');
    title('Cross-user mean SNR evolution');


    %% FIGURE 2: TIME-AVERAGED PERFORMANCE ACROSS USERS

    figure('Name', 'DEBUG - General KPIs - Time-Averaged Per-User Performance');

    subplot(2,1,1);
    plot(userAxis, generalKPIs.throughput.avgRatePerUser_Mbps, ...
         'o-', 'LineWidth', 1.2);
    grid on;
    xlabel('User index');
    ylabel('Time-averaged rate [Mbit/s]');
    title('Time-averaged rate per user');

    subplot(2,1,2);
    plot(userAxis, generalKPIs.SNR.avgSNRPerUser_dB, ...
         'o-', 'LineWidth', 1.2);
    grid on;
    xlabel('User index');
    ylabel('Time-averaged SNR [dB]');
    title('Time-averaged SNR per user');


    %% FIGURE 3: DISTRIBUTIONAL FAIRNESS

    figure('Name', 'DEBUG - General KPIs - Distributional Fairness');

    subplot(2,1,1);
    plot(generalKPIs.fairness.rateCDF_x_Mbps, ...
         generalKPIs.fairness.rateCDF_y, ...
         'LineWidth', 1.5);
    grid on;
    xlabel('Time-averaged user rate [Mbit/s]');
    ylabel('Empirical CDF');
    title('CDF of time-averaged user rate');

    subplot(2,1,2);
    plot(generalKPIs.fairness.SNRCDF_x_dB, ...
         generalKPIs.fairness.SNRCDF_y, ...
         'LineWidth', 1.5);
    grid on;
    xlabel('Time-averaged user SNR [dB]');
    ylabel('Empirical CDF');
    title('CDF of time-averaged user SNR');


    %% FIGURE 4: SERVICE RATIO DIAGNOSTICS

    figure('Name', 'DEBUG - General KPIs - Service Ratio Diagnostics');

    subplot(2,1,1);
    stairs(timeAxis, generalKPIs.serviceContinuity.servedRatioTime, ...
           'LineWidth', 1.5);
    grid on;
    xlabel(xLabelTime);
    ylabel('Served-user fraction');
    ylim([-0.05, 1.05]);
    title('Served-user fraction evolution');

    subplot(2,1,2);
    plot(userAxis, generalKPIs.serviceContinuity.servedRatioPerUser, ...
         'o-', 'LineWidth', 1.2);
    grid on;
    xlabel('User index');
    ylabel('Served-time fraction');
    ylim([-0.05, 1.05]);
    title('Served-time fraction per user');


    %% FIGURE 5: REPRESENTATIVE-USER SELECTED-LINK QOS EVOLUTION

    rate_u_Mbps = generalKPIs.serviceContinuity.userRateTime_Mbps(userIdx, :);
    SNR_u_dB = generalKPIs.serviceContinuity.userSNRTime_dB(userIdx, :);
    served_u = generalKPIs.serviceContinuity.userServedTime(userIdx, :);
    HO_u = generalKPIs.serviceContinuity.userHandoverTime(userIdx, :);
    sat_u = generalKPIs.serviceContinuity.userAssignedSatIdxTime(userIdx, :);

    handoverIdx = find(HO_u);

    figure('Name', sprintf('DEBUG - General KPIs - Representative User %d QoS Evolution', userIdx));

    subplot(5,1,1);
    stairs(timeAxis, rate_u_Mbps, 'LineWidth', 1.5);
    grid on;
    ylabel('Rate [Mbit/s]');
    title(sprintf('Representative-user selected-link rate evolution, user %d', userIdx));
    hold on;
    for k = 1:numel(handoverIdx)
        xline(timeAxis(handoverIdx(k)), '--');
    end
    hold off;

    subplot(5,1,2);
    stairs(timeAxis, SNR_u_dB, 'LineWidth', 1.5);
    grid on;
    ylabel('SNR [dB]');
    title(sprintf('Representative-user selected-link SNR evolution, user %d', userIdx));
    hold on;
    for k = 1:numel(handoverIdx)
        xline(timeAxis(handoverIdx(k)), '--');
    end
    hold off;

    subplot(5,1,3);
    stairs(timeAxis, double(served_u), 'LineWidth', 1.5);
    grid on;
    ylim([-0.1, 1.1]);
    yticks([0 1]);
    yticklabels({'Not served', 'Served'});
    ylabel('Service');
    title('Representative-user service state');

    subplot(5,1,4);
    stairs(timeAxis, double(HO_u), 'LineWidth', 1.5);
    grid on;
    ylim([-0.1, 1.1]);
    yticks([0 1]);
    yticklabels({'No HO', 'HO'});
    ylabel('HO');
    title('Representative-user handover events');

    subplot(5,1,5);
    stairs(timeAxis, sat_u, 'LineWidth', 1.2);
    grid on;
    xlabel(xLabelTime);
    ylabel('Satellite index');
    title('Representative-user assigned satellite evolution');


    %% FIGURE 6: ALGORITHM-SPECIFIC KPI DEBUG PLOTS

    switch association_algorithm

        case "URLLC"

            TCR_URLLC = specificKPIs.TCR_URLLC;

            PL_URLLC_temporal_ms = specificKPIs.PL_URLLC_temporal * 1e3;
            PL_URLLC_global_ms = specificKPIs.PL_URLLC_global * 1e3;

            latencyThreshold_ms = configKPI.URLLC.latency_max_URLLC * 1e3;
            percentile_URLLC = configKPI.URLLC.percentile_URLLC;

            figure('Name', 'DEBUG - Specific KPIs - URLLC');

            subplot(2,1,1);
            stairs(timeAxis, TCR_URLLC, 'LineWidth', 1.5);
            grid on;
            ylim([-0.05, 1.05]);
            xlabel(xLabelTime);
            ylabel('Compliant-user fraction');
            title('URLLC Temporal Compliance Ratio');

            hold on;
            yline(mean(TCR_URLLC, 'omitnan'), ':', 'Mean TCR');
            hold off;

            subplot(2,1,2);
            stairs(timeAxis, PL_URLLC_temporal_ms, 'LineWidth', 1.5);
            grid on;
            xlabel(xLabelTime);
            ylabel(sprintf('%.0fth-percentile latency [ms]', ...
                percentile_URLLC * 100));
            title(sprintf('URLLC %.0fth-percentile latency evolution', ...
                percentile_URLLC * 100));

            hold on;
            yline(PL_URLLC_global_ms, '--', ...
                sprintf('Global %.0fth percentile', percentile_URLLC * 100));
            yline(latencyThreshold_ms, ':', 'Latency threshold');
            hold off;


        case "eMBB"

            TCR_eMBB = specificKPIs.TCR_eMBB;
            etaSys = specificKPIs.aggregateSpecEff;

            figure('Name', 'DEBUG - Specific KPIs - eMBB');

            subplot(2,1,1);
            stairs(timeAxis, TCR_eMBB, 'LineWidth', 1.5);
            grid on;
            ylim([-0.05, 1.05]);
            xlabel(xLabelTime);
            ylabel('Compliant-user fraction');
            title('eMBB Temporal Compliance Ratio');

            hold on;
            yline(mean(TCR_eMBB, 'omitnan'), ':', 'Mean TCR');
            hold off;

            subplot(2,1,2);
            stairs(timeAxis, etaSys, 'LineWidth', 1.5);
            grid on;
            xlabel(xLabelTime);
            ylabel('System spectral efficiency [bit/s/Hz]');
            title('eMBB system spectral efficiency evolution');


        otherwise

            warning('Unknown association algorithm. No specific KPI plots generated.');

    end

end