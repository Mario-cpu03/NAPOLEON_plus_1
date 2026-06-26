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
%           tensor quantities required by the KPI module.
%
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


function [specificURLLC]=URLLC_KPIs(USER_SAT_association, configKPI)
    latency_s     = USER_SAT_association.latency_s;
    SNR_lin       = USER_SAT_association.SNR_lin;            
    handoverEvent = USER_SAT_association.handoverEvent;      
    servedMask    = USER_SAT_association.servedMask;         
    numUsers      = USER_SAT_association.numUsers;           
    numTimeSteps  = USER_SAT_association.numTimeSteps;       
    
    latency_max_URLLC  = configKPI.URLLC.latency_max_URLLC;      
    SNRmin_URLLC       = configKPI.URLLC.SNRmin_URLLC;           
    handoverMax_URLLC  = configKPI.URLLC.handoverMax_URLLC;      
    time_window        = configKPI.URLLC.time_window;     


    %% URLLC Temporal Compliance Ratio 

    %here we count the number of handovers for every user in the tme_window
    handoverCount_timeWind = zeros(numUsers, numTimeSteps);   
    
    for t = 1:numTimeSteps
        %this is a check to see if t-M+1 is <1 (that means that we are at
        %the "beginning" of the timesteps).
        t_start = max(1, t - time_window + 1);        
        % Sum handover events in the window 
        handoverCount_timeWind(:, t) = sum(handoverEvent(:, t_start:t), 2);   
    end

    %now we find the logical values that represent the three conditions
    cond_latency  = latency_s <= latency_max_URLLC;
    cond_SNR     = SNR_lin   >= SNRmin_URLLC;
    cond_handover = handoverCount_timeWind <=handoverMax_URLLC;

    %now we check if the associations (for each time step) respect the conditions. We use
    %servdeMask to check is that user is actually served (this is just a
    %check).
    C_URLLC = cond_latency & cond_SNR & cond_handover & servedMask;         %This matrix [U x T] contains logical values. 1 if the conditions are satisfied, 0 otherwis
 

    %now we have to average these values for each time step
    specificURLLC.TCR_URLLC = sum(C_URLLC, 1) / numUsers;                          %This is a row vector [1 x T] that contains, for each time step, the percentage of users that 
                                                                     %satisfy the conditions
                                                                     

    %% URLLC 90th-percentile latency
    %We will calculate the percentile for the whole simulation, and the
    %percentile for each time step.

    p=configKPI.URLLC.percentile_URLLC;   %percentile 


    %TEMPORAL PERCENTILE
    PL_URLLC_temporal = zeros(1, numTimeSteps);    
    for t = 1:numTimeSteps
    
        % first we have to find which users are served at time step t, and take
        % its latencies
        users_served_at_t = servedMask(:, t);           
        latency_at_t = latency_s(:, t);                   
        served_latencies_t = latency_at_t(users_served_at_t);   
    
        %given the latencies, we can compute percentile   
        PL_URLLC_temporal(t) = quantile(served_latencies_t, p);
    end
    specificURLLC.PL_URLLC_temporal = PL_URLLC_temporal;


    %GLOBAL PERCENTILE 
    %first we exract all the latencies values, for the users for every
    %time step. We use servedMask to exract only the users that are served
    %for each time step)
    latency_all_samples = latency_s(:);    
    served_all_samples  = servedMask(:);   
    all_served_latencies = latency_all_samples(served_all_samples);  
    
    %we calculate the percentile
    specificURLLC.PL_URLLC_global = quantile(all_served_latencies, p);
    
end