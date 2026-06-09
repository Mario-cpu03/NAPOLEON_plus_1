function debug_plot_general_KPIs(generalKPIs, USER_SAT_association, userIdx)

%% Debugging General KPI Plotting Function
% DEBUGGING PURPOSES STRUCTURE
%
% The scope of this helper function is to display the quantities computed
% by the general_KPIS function using one clear representation per physical
% quantity.
%
% This function is intended only for debugging and validation purposes.
% It is not meant to generate final report-quality figures.
%
% Plotting convention:
%       (i)   rates are displayed in Mbit/s;
%       (ii)  bandwidth-normalized rates are interpreted as Mbit/s/MHz;
%       (iii) SNR is displayed in dB;
%       (iv)  service state and handover events are displayed as binary
%             time series;
%       (v)   assigned satellite index is displayed as a raw index.
%
% The function displays:
%       (i)   average user rate over time,
%       (ii)  average user SNR over time,
%       (iii) per-user average rate,
%       (iv)  per-user average SNR,
%       (v)   distributional fairness CDFs,
%       (vi)  service ratio diagnostics,
%       (vii) QoS service continuity of one selected user.

    %% INPUT CHECKS

    if nargin < 3
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


    %% COMMAND WINDOW DEBUG SUMMARY

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('DEBUGGING PURPOSES STRUCTURE: GENERAL KPI SUMMARY\n');
    fprintf('============================================================\n');

    fprintf('\nSimulation size:\n');
    fprintf('  Number of users      : %d\n', numUsers);
    fprintf('  Number of time steps : %d\n', numTimeSteps);

    fprintf('\nThroughput KPIs:\n');
    fprintf('  Global average user rate [Mbit/s]     : %.6f\n', ...
        generalKPIs.throughput.globalAvgUserRate_Mbps);

    fprintf('  Global normalized user rate [Mbit/s/MHz] : %.6f\n', ...
        generalKPIs.throughput.globalAvgUserRate_bpsHz);

    fprintf('\nSNR KPIs:\n');
    fprintf('  Global average user SNR [dB] : %.6f\n', ...
        generalKPIs.SNR.globalAvgUserSNR_dB);

    fprintf('\nService-continuity KPIs:\n');
    fprintf('  System served ratio : %.6f\n', ...
        generalKPIs.serviceContinuity.servedRatioSystem);
    fprintf('  Selected user       : %d\n', userIdx);
    fprintf('  User served ratio   : %.6f\n', ...
        generalKPIs.serviceContinuity.servedRatioPerUser(userIdx));

    if isfield(generalKPIs.serviceContinuity, 'userHandoverTime')
        fprintf('  User total handovers: %d\n', ...
            sum(generalKPIs.serviceContinuity.userHandoverTime(userIdx, :)));
    end

    fprintf('============================================================\n\n');


    %% FIGURE 1: GLOBAL TIME EVOLUTION

    figure('Name', 'DEBUG - General KPIs - Time Evolution');

    subplot(2,1,1);
    plot(timeAxis, generalKPIs.throughput.avgUserRateTime_Mbps, ...
         'LineWidth', 1.5);
    grid on;
    xlabel(xLabelTime);
    ylabel('Average user rate [Mbit/s]');
    title('Average user rate over time');

    subplot(2,1,2);
    plot(timeAxis, generalKPIs.SNR.avgUserSNRTime_dB, ...
         'LineWidth', 1.5);
    grid on;
    xlabel(xLabelTime);
    ylabel('Average user SNR [dB]');
    title('Average user SNR over time');


    %% FIGURE 2: PER-USER AVERAGE PERFORMANCE

    figure('Name', 'DEBUG - General KPIs - Per-User Average Performance');

    subplot(2,1,1);
    plot(userAxis, generalKPIs.throughput.avgRatePerUser_Mbps, ...
         'o-', 'LineWidth', 1.2);
    grid on;
    xlabel('User index');
    ylabel('Average rate [Mbit/s]');
    title('Average rate per user');

    subplot(2,1,2);
    plot(userAxis, generalKPIs.SNR.avgSNRPerUser_dB, ...
         'o-', 'LineWidth', 1.2);
    grid on;
    xlabel('User index');
    ylabel('Average SNR [dB]');
    title('Average SNR per user');


    %% FIGURE 3: DISTRIBUTIONAL FAIRNESS

    figure('Name', 'DEBUG - General KPIs - Distributional Fairness');

    subplot(2,1,1);
    plot(generalKPIs.fairness.rateCDF_x_Mbps, ...
         generalKPIs.fairness.rateCDF_y, ...
         'LineWidth', 1.5);
    grid on;
    xlabel('Average user rate [Mbit/s]');
    ylabel('Empirical CDF');
    title('CDF of average user rate');

    subplot(2,1,2);
    plot(generalKPIs.fairness.SNRCDF_x_dB, ...
         generalKPIs.fairness.SNRCDF_y, ...
         'LineWidth', 1.5);
    grid on;
    xlabel('Average user SNR [dB]');
    ylabel('Empirical CDF');
    title('CDF of average user SNR');


    %% FIGURE 4: SERVICE RATIO DIAGNOSTICS

    figure('Name', 'DEBUG - General KPIs - Service Ratio');

    subplot(2,1,1);
    plot(timeAxis, generalKPIs.serviceContinuity.servedRatioTime, ...
         'LineWidth', 1.5);
    grid on;
    xlabel(xLabelTime);
    ylabel('Served ratio');
    ylim([-0.05, 1.05]);
    title('System served ratio over time');

    subplot(2,1,2);
    plot(userAxis, generalKPIs.serviceContinuity.servedRatioPerUser, ...
         'o-', 'LineWidth', 1.2);
    grid on;
    xlabel('User index');
    ylabel('Served ratio');
    ylim([-0.05, 1.05]);
    title('Served ratio per user');


    %% FIGURE 5: SELECTED USER QOS SERVICE CONTINUITY

    rate_u_Mbps = generalKPIs.serviceContinuity.userRateTime_Mbps(userIdx, :);
    SNR_u_dB = generalKPIs.serviceContinuity.userSNRTime_dB(userIdx, :);
    served_u = generalKPIs.serviceContinuity.userServedTime(userIdx, :);
    HO_u = generalKPIs.serviceContinuity.userHandoverTime(userIdx, :);
    sat_u = generalKPIs.serviceContinuity.userAssignedSatIdxTime(userIdx, :);

    handoverIdx = find(HO_u);

    figure('Name', sprintf('DEBUG - General KPIs - User %d QoS Continuity', userIdx));

    subplot(5,1,1);
    plot(timeAxis, rate_u_Mbps, 'LineWidth', 1.5);
    grid on;
    ylabel('Rate [Mbit/s]');
    title(sprintf('QoS service continuity of user %d', userIdx));
    hold on;
    for k = 1:numel(handoverIdx)
        xline(timeAxis(handoverIdx(k)), '--');
    end
    hold off;

    subplot(5,1,2);
    plot(timeAxis, SNR_u_dB, 'LineWidth', 1.5);
    grid on;
    ylabel('SNR [dB]');
    title('Selected-link SNR over time');
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
    title('Binary service state');

    subplot(5,1,4);
    stairs(timeAxis, double(HO_u), 'LineWidth', 1.5);
    grid on;
    ylim([-0.1, 1.1]);
    yticks([0 1]);
    yticklabels({'No HO', 'HO'});
    ylabel('HO');
    title('Handover events');

    subplot(5,1,5);
    plot(timeAxis, sat_u, '.', 'MarkerSize', 8);
    grid on;
    xlabel(xLabelTime);
    ylabel('Satellite index');
    title('Assigned satellite index over time');

end