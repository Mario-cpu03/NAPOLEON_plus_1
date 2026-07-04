%% General KPI Computation Function
% The scope of this function is to compute the general KPIs of the
% simulator, independently of the selected association algorithm.
%
% The function evaluates:
%       (i)   average user throughput over the simulation time,
%       (ii)  average user SNR over the simulation time,
%       (iii) distributional fairness through the CDFs of per-user average
%             throughput and per-user average SNR.
%
% The function follows the same operational logic used in the reference
% thesis: average performance is evaluated at user level, while fairness is
% assessed by looking at the distribution of average user rate and average
% user SNR across the user population.
%
% IMPORTANT:
% Throughput and SNR are treated differently. If a user is not served, its
% delivered rate is zero. Instead, SNR is physically meaningful only when a
% selected link exists, therefore SNR averages are computed only over served
% samples.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. USER_SAT_association : Data Structure containing the compact
%       output of the UserSatAssoc module.
%
%       2. configKPI : Data Structure containing KPI configuration
%       parameters. In particular:
%
%                   (i) configKPI.eMBB.bandwidth_Hz : system bandwidth [Hz]
%
%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. generalKPIs : Data Structure containing:
%
%                   (i)   throughput : average user throughput quantities
%                   (ii)  SNR : average user SNR quantities
%                   (iii) fairness : CDFs of per-user average throughput
%                         and per-user average SNR

function [generalKPIs] = general_KPIS(USER_SAT_association, configKPI)

    %%%%%% ----- INPUT EXTRACTION ----- %%%%%%

    rate_bps = USER_SAT_association.rate_bps;
    SNR_lin  = USER_SAT_association.SNR_lin;

    % Reconstruct service state if servedMask is not available.
    servedMask = USER_SAT_association.servedMask;

    % Bandwidth is needed only to express throughput also in bit/s/Hz.
    bandwidth_Hz = configKPI.eMBB.bandwidth_Hz;

    numUsers = USER_SAT_association.numUsers;
    numTimeSteps = USER_SAT_association.numTimeSteps;

    % AVERAGE USER THROUGHPUT

    % Throughput is a delivered-service quantity. Unserved users contribute
    % zero delivered rate.
    rate_eff_bps = rate_bps;
    rate_eff_bps(~servedMask) = 0;
    rate_eff_bps(~isfinite(rate_eff_bps)) = 0;

    % Average rate received by each user over the whole simulation.
    avgRatePerUser_bps = mean(rate_eff_bps, 2);

    % Same quantity in Mbit/s.
    avgRatePerUser_Mbps = avgRatePerUser_bps / 1e6;

    % Thesis-style bandwidth-normalized average rate [bit/s/Hz].
    avgRatePerUser_bpsHz = avgRatePerUser_bps / bandwidth_Hz;

    % Global average user rate.
    globalAvgUserRate_bps = mean(avgRatePerUser_bps);
    globalAvgUserRate_Mbps = globalAvgUserRate_bps / 1e6;
    globalAvgUserRate_bpsHz = globalAvgUserRate_bps / bandwidth_Hz;

    % Average user rate at each time step.
    avgUserRateTime_bps = mean(rate_eff_bps, 1);
    avgUserRateTime_Mbps = avgUserRateTime_bps / 1e6;
    avgUserRateTime_bpsHz = avgUserRateTime_bps / bandwidth_Hz;


    %AVERAGE USER SNR 
    % Convert selected-link SNR to dB.
    % SNR is only defined for served, finite, strictly positive links.
    SNR_eff_lin = SNR_lin;
    SNR_eff_lin(~servedMask) = NaN;
    SNR_eff_lin(~isfinite(SNR_eff_lin)) = NaN;
    SNR_eff_lin(SNR_eff_lin <= 0) = NaN;

    SNR_dB = 10 * log10(SNR_eff_lin);

    % SNR is only defined for served links.
    SNR_dB(~isfinite(SNR_dB)) = NaN;

    % Average SNR received by each user over served samples.
    avgSNRPerUser_dB = mean(SNR_dB, 2, 'omitnan');

    % Global average user SNR.
    globalAvgUserSNR_dB = mean(avgSNRPerUser_dB, 'omitnan');

    % Average user SNR at each time step.
    avgUserSNRTime_dB = mean(SNR_dB, 1, 'omitnan');


    %%DISTRIBUTIONAL FAIRNESS

    % Fairness is evaluated through the empirical CDF of average user rate
    % and average user SNR, following the thesis-style analysis.

    [rateCDF_x_Mbps, rateCDF_y] = empirical_cdf(avgRatePerUser_Mbps);
    [rateCDF_x_bpsHz, ~] = empirical_cdf(avgRatePerUser_bpsHz);

    % SNR CDF is computed only over users with at least one valid served SNR.
    validSNRUsers = isfinite(avgSNRPerUser_dB);

    if any(validSNRUsers)
        [SNRCDF_x_dB, SNRCDF_y] = empirical_cdf(avgSNRPerUser_dB(validSNRUsers));
    else
        SNRCDF_x_dB = [];
        SNRCDF_y = [];
    end

    
    %USER-LEVEL SERVICE CONTINUITY

    % Service continuity is interpreted as QoS continuity at user level.
    % Therefore, for each user, we store the time evolution of:
    %       (i)   delivered rate,
    %       (ii)  selected-link SNR,
    %       (iii) binary service state,
    %       (iv)  handover events, if available.
    %
    % This allows the analysis of a selected representative user by checking
    % whether the service is continuous not only in terms of connectivity,
    % but also in terms of rate and signal quality.

    % Delivered rate evolution.
    % If a user is not served, the delivered rate is zero.
    userRateTime_bps = rate_eff_bps;
    userRateTime_Mbps = userRateTime_bps / 1e6;
    userRateTime_bpsHz = userRateTime_bps / bandwidth_Hz;

    % Selected-link SNR evolution.
    % If a user is not served, SNR is physically undefined and is kept as NaN.
    userSNRTime_dB = SNR_dB;

    % Binary service state.
    % servedTime(u,t)=1 means that user u is served at time step t.
    userServedTime = servedMask;

    % Service ratio support quantities.
    % These are not the full definition of service continuity, but they are
    % useful compact indicators of how often each user is actually served.
    servedRatioPerUser = mean(servedMask, 2);
    servedRatioSystem = mean(servedMask(:));
    servedRatioTime = mean(servedMask, 1);

    % Handover events, useful to interpret rate/SNR discontinuities.
    userHandoverTime = USER_SAT_association.handoverEvent;

    % Assigned satellite index, useful to identify which satellite changes
    % caused the QoS discontinuities.
    userAssignedSatIdxTime = USER_SAT_association.assignedSatIdx;

    %OUTPUT STRUCTURE

    generalKPIs = struct();
    generalKPIs.throughput.avgRatePerUser_bps = avgRatePerUser_bps;
    generalKPIs.throughput.avgRatePerUser_Mbps = avgRatePerUser_Mbps;
    generalKPIs.throughput.avgRatePerUser_bpsHz = avgRatePerUser_bpsHz;

    generalKPIs.throughput.globalAvgUserRate_bps = globalAvgUserRate_bps;
    generalKPIs.throughput.globalAvgUserRate_Mbps = globalAvgUserRate_Mbps;
    generalKPIs.throughput.globalAvgUserRate_bpsHz = globalAvgUserRate_bpsHz;

    generalKPIs.throughput.avgUserRateTime_bps = avgUserRateTime_bps;
    generalKPIs.throughput.avgUserRateTime_Mbps = avgUserRateTime_Mbps;
    generalKPIs.throughput.avgUserRateTime_bpsHz = avgUserRateTime_bpsHz;

    % SNR KPIs.
    generalKPIs.SNR.avgSNRPerUser_dB = avgSNRPerUser_dB;
    generalKPIs.SNR.globalAvgUserSNR_dB = globalAvgUserSNR_dB;
    generalKPIs.SNR.avgUserSNRTime_dB = avgUserSNRTime_dB;

    % Fairness KPIs.
    generalKPIs.fairness.rateCDF_x_Mbps = rateCDF_x_Mbps;
    generalKPIs.fairness.rateCDF_x_bpsHz = rateCDF_x_bpsHz;
    generalKPIs.fairness.rateCDF_y = rateCDF_y;

    generalKPIs.fairness.SNRCDF_x_dB = SNRCDF_x_dB;
    generalKPIs.fairness.SNRCDF_y = SNRCDF_y;

    % Service continuity KPIs.
    generalKPIs.serviceContinuity.userRateTime_bps = userRateTime_bps;
    generalKPIs.serviceContinuity.userRateTime_Mbps = userRateTime_Mbps;
    generalKPIs.serviceContinuity.userRateTime_bpsHz = userRateTime_bpsHz;

    generalKPIs.serviceContinuity.userSNRTime_dB = userSNRTime_dB;

    generalKPIs.serviceContinuity.userServedTime = userServedTime;
    generalKPIs.serviceContinuity.userHandoverTime = userHandoverTime;
    generalKPIs.serviceContinuity.userAssignedSatIdxTime = userAssignedSatIdxTime;

    generalKPIs.serviceContinuity.servedRatioPerUser = servedRatioPerUser;
    generalKPIs.serviceContinuity.servedRatioSystem = servedRatioSystem;
    generalKPIs.serviceContinuity.servedRatioTime = servedRatioTime;

end
