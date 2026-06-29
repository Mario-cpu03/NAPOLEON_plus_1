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
%           tensor quantities required by the KPI module.
%
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
%                   (ii)  aggregateSpecEff  : row vector [1 x T], System Spectral Efficiency [bit/s/Hz] at each time step

function [specificeMBB] = eMBB_KPIs(USER_SAT_association, configKPI)

    rate_bps  = USER_SAT_association.rate_bps;           
    handoverEvent = USER_SAT_association.handoverEvent;      
    servedMask = USER_SAT_association.servedMask;         
    numUsers = USER_SAT_association.numUsers;           
    numTimeSteps = USER_SAT_association.numTimeSteps;       
    
    rateMin_eMBB     = configKPI.eMBB.rateMin_eMBB;         
    handoverMax_eMBB = configKPI.eMBB.handoverMax_eMBB;     
    time_window      = configKPI.eMBB.time_window;          
    bandwidth_Hz     = configKPI.eMBB.bandwidth_Hz;        

    % NaN management for rate-based aggregate KPIs.
    % Unserved or numerically invalid users contribute zero delivered rate.
    rate_eff_bps = rate_bps;
    rate_eff_bps(~servedMask) = 0;
    rate_eff_bps(~isfinite(rate_eff_bps)) = 0;    


%% eMBB Temporal Compliance Ratio

    %here we count the number of handovers for every user in the tme_window
    handoverCount_timeWind = zeros(numUsers, numTimeSteps);   
    
    for t = 1:numTimeSteps
        %this is a check to see if t-M+1 is <1 (that means that we are at
        %the "beginning" of the timesteps).
        t_start = max(1, t - time_window + 1);        
        % Sum handover events in the window 
        handoverCount_timeWind(:, t) = sum(handoverEvent(:, t_start:t), 2);   
    end

    %now we find the logical values that represent the two conditions: 1 if
    %that condition is satisfied, 0 otherwise.
    cond_rate     = isfinite(rate_bps) & (rate_bps >= rateMin_eMBB);         
    cond_handover = handoverCount_timeWind <= handoverMax_eMBB; 

    
    %now we check if the associations (for each time step) respect the conditions. We use
    %servdeMask to check is that user is actually served (this is just a
    %check).    
    C_eMBB = cond_rate & cond_handover & servedMask;                       %This matrix [U x T] contains logical values. 1 if the conditions are simultaneously satisfied, 0 otherwis
 
    %now we sum all the values for each time step, then average over all
    %the users.
    specificeMBB.TCR_eMBB = sum(C_eMBB, 1) / numUsers;                     %This is a row vector [1 x T] that contains, for each time step, the percentage of users that 
                                                                           %satisfy the conditions

    %% System Spectral Efficiency

    %first we sum, for aech time step, the rates of all the users
    sum_rate_t = sum(rate_eff_bps, 1);       

    %then we calculate the spectral efficiency
    specificeMBB.aggregateSpecEff = sum_rate_t/ bandwidth_Hz;   

end