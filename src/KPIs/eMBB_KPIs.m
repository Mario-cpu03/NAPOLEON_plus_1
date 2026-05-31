%% eMBB Temporal Compliance Ratio
% This KPI measures, at each simulation time step, the fraction of users
% whose assigned service satisfies eMBB-like requirements.
% Since every user is always served by at least one satellite, this is NOT a
% connectivity outage metric. It is a QoS-compliance metric.
%
% For each user u and time step t, define:
%   C_eMBB(u,t) = 1  if user u is eMBB-compliant at time t, 0 otherwise
%
% In this sense, a user is considered eMBB-compliant if:
%           (i)  rate(u,t)             >= rateMin_eMBB
%           (ii) handoverCount_M(u,t)  <= handoverMax_eMBB
% where handoverCount_M(u,t) is the number of handovers experienced by user u
% in the last M time steps, hence in a given time window of relevance.

% Therefore, C_eMBB is defined as the logical and of the two rules:
%
%   C_eMBB(u,t) = 1[ rate(u,t)            >= rateMin_eMBB      &&
%                    handoverCount_M(u,t)  <= handoverMax_eMBB  ]
%
% The eMBB Temporal Compliance Ratio is therefore obtained as the
% average over the number of users of C_eMBB(u,t):
%
%   TCR_eMBB(t) = (1/U) * sum_U C_eMBB(u,t)
%
% A parametric interpretation follows for clarity.
% If TCR_eMBB(t) = 1 then all users are eMBB-compliant at time t;
% if instead TCR_eMBB(t) = 0.5 then 50% of the users are eMBB-compliant
% at time t;
% and, if TCR_eMBB(t) = 0 then no user satisfies eMBB requirements at
% time t, although users are still connected.
%
% This KPI answers the question: does the association strategy
% maintain eMBB-compliant throughput over time while satellites enter/leave
% visibility and the channel conditions fluctuate?
%
%% System Spectral Efficiency
% In addition to the eMBB Temporal Compliance Ratio, we use the System
% Spectral Efficiency as an aggregate throughput KPI.
% It measures the total spectral efficiency delivered to all users at each
% time step, normalised by the system bandwidth B.
%
% At each time step t, the System Spectral Efficiency is defined as:
%
%   eta_sys(t) = (1/B) * sum_u Rate(u,t)
%
% where Rate(u,t) is the achievable rate [bit/s] of user u on its
% assigned satellite at time t, and B [Hz] is the system bandwidth.
%
% A parametric interpretation follows:
% if eta_sys(t) = x [bit/s/Hz] then the constellation delivers x bits per
% second per Hz of bandwidth to the aggregate user population at time t.
% Higher values indicate better utilisation of the available spectrum.
%

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
%                           slant range [m] for every association
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
%                   (x)     servedRatioPerUser : [U x 1] fraction of time
%                           steps during which each user is served
%                   (xi)    totalHandoversSystem : scalar, total handover
%                           events across all users and time steps
%                   (xii)   servedRatioSystem : scalar, fraction of
%                           (user, time) pairs that are successfully served
%                   (xiii)  association_algorithm : string identifier of
%                           the algorithm used for user-satellite assignment
%                   (xiv)   numUsers, numSats, numTimeSteps : scalars
%                           defining the simulation scenario dimensions
%       2. configKPI.eMBB : Data Structure containing the parameters needed
%           by the eMBB KPI module:
%                   (i)   rateMin_eMBB : minimum achievable rate [bit/s]
%                         required for a user to be considered eMBB-compliant
%                   (ii)  handoverMax_eMBB : maximum number of handovers
%                         allowed within the time window for eMBB compliance
%                   (iii) time_window : length of the sliding window
%                         [time steps] over which handovers are counted
%                   (iv)  bandwidth_Hz : system bandwidth B [Hz] used to
%                         normalise the System Spectral Efficiency
%
%% %%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. specificeMBB : Data Structure containing the calculated KPIs
%          for the eMBB based association algorithm:
%                   (i)   TCR_eMBB : row vector [1 x T] compliance ratio for each time step
%                   (ii)  specEff  : row vector [1 x T], System Spectral Efficiency [bit/s/Hz] at each time step
function []=eMBB_KPIs()

end