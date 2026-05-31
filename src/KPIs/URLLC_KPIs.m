%% URLLC Temporal Compliance Ratio
% This KPI measures, at each simulation time step, the fraction of users
% whose assigned service satisfies URLLC-like requirements.
% Since every user is always served by at least one satellite, this is NOT a
% connectivity outage metric. It is a QoS-compliance metric.
%
% For each user u and time step t, define:
%   C_URLLC(u,t) = 1  if user u is URLLC-compliant at time t, 0 otherwise
%
% In this sense, a user is considered URLLC-compliant if: 
%           (i) latency(u,t) <= latencyMax_URLLC
%           (ii) SNR(u,t)     >= SNRmin_URLLC
%           (iii) handoverCount_M(u,t) <= handoverMax_URLLC
% where handoverCount_M(u,t) is the number of handovers experienced by user u
% in the last M time steps, hence in a given time window of relevance.
%
% Therefore, the C_URLLC is defined as the train of deltas obtained by the 
% logical and of the three afore cited rules:
%
%   C_URLLC(u,t) = 1[ latency(u,t) <= latencyMax_URLLC  &&
%                     SNR(u,t)     >= SNRmin_URLLC      &&
%                     handoverCount_M(u,t) <= handoverMax_URLLC ]
%
% The URLLC Temporal Compliance Ratio is therefore obtained as the 
% average over the amount of users of C_URLLC(u,t):
%
%   TCR_URLLC(t) = (1/numUsers) * sum_u C_URLLC(u,t)
%
% A parametric interpretation follows for clarity.
% If TCR_URLLC(t) = 1 then all users are URLLC-compliant at time t;
% if instead TCR_URLLC(t) = 0.5 then 50% of the users are URLLC-compliant
% at time t;
% and, if TCR_URLLC(t) = 0 then no user satisfies URLLC requirements at
% time t, although users are still connected.
%
% This KPI answers the question: does the association strategy
% maintain URLLC-compliant performance over time while satellites enter/leave
% visibility and the quality of the channels fluctuate?

%% URLLC 90th-percentile latency KPI
%
% In addition to the URLLC Temporal Compliance Ratio, we use
% the 90th-percentile latency as a tail-latency KPI.
% Average latency alone is not sufficient for URLLC-like services, because
% the mean can hide high-latency events experienced by a subset of users or
% during specific satellite-visibility transitions.
%
% The 90th-percentile latency is thus computed over all latency samples:
%   latency90_URLLC = Q_0.90({latency(u,t)})
%
% A parametric interpretation follows:
% if latency90_URLLC = x then it means that 90% of all served user-time samples have latency below x, while the worst 10% exceed x.
% That is, we are measuring the upper-tail behavior of the
% achieved propagation latency after a certain user-sat link has been selected.

%% %%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. USER_SAT_association : Data Structure containing metadata and
%           tensor quantities required by the KPI module:
%                   (i)     assignedSatIdx : matrix [U x T] containing the
%                           index of the satellite assigned to each user at
%                           every time instant
%                   (ii)    SNR_lin : matrix [U x T] containing the linear
%                           SNR for every user-satellite association
%                   (iii)   rate_bps : matrix [U x T] containing the
%                           achievable rate [bit/s] for every association
%                   (iv)    distance_m : matrix [U x T] containing the
%                   (v)     latency_s : matrix [U x T] containing the
%                           one-way propagation latency [s] for every
%                           association, computed as distance_m / c
%                   (vi)    handoverEvent : matrix [U x T] logical, TRUE
%                           if a handover occurred at that (user, time) pair
%                   (vii)   servedMask : matrix [U x T] logical, TRUE if
%                           the user has a valid association at that time step
%                   (viii)  timeVec : [1 x T datetime] vector of simulation
%                           time instants
%                   (ix)    totalHandoversPerUser : [U x 1] total number of
%                           handover events per user across all time steps
%                   (x)     servedRatioPerUser : [U x 1] 
%                   (xi)    totalHandoversSystem : scalar, total handover
%                           events across all users and time steps
%                   (xii)   servedRatioSystem : 
%                   (xiii)  association_algorithm : string identifier of
%                           the algorithm used for user-satellite assignment
%                   (xiv)   numUsers, numSats, numTimeSteps : scalars
%                           defining the simulation scenario dimensions

%       2. configKPI.URLLC : Data Structure containing the parameters needed by
%       the URLLC KPI module
%                   (i)   latency_max_URLLC : maximum latency for the
%                         compliance ratio;
%                   (ii)  SNRmin_URLLC: minimum SNR for the compliance
%                         ratio;
%                   (iii) handoverMax_URLLC : maximum number of handovers
%                         in a given time window (for the compliance
%                         ratio)
%                   (iv)  time_window : lenght of the time window in which
%                         we count the number of handovers


%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       2. specificURLLC : Data Structure containing the calculated KPIs
%       for the URLLC based association algorithm
%                   (i)   TCR_URLLC:row vector [1 x T], compliance ratio for each time step
%                   (ii)  PL_URLLC_temporal:row vector [1 x T], 90th-percentile latency for each time step;
%                   (iii) PL_URLLC_global : 90th-percentile latency for the
%                   whole simulation
function []=URLLC_KPIs()

end