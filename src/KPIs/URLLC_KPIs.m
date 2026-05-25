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

function []=URLLC_KPIs()

end