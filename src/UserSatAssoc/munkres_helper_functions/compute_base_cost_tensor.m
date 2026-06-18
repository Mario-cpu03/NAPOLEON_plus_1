%This function computes the normalized base cost tensor. 
%It is implemented this way to exploit the matlab optimization for matrix calculations.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. USER_SAT_evolution : Data Structure containing metadata and
%       tensor quantities required by the UserSatAssoc module:
%
%                   (i)   timeVec : simulation time vector
%                   (ii)  validLinkMask : logical tensor [U x S x T].
%                         true where user u can see satellite s at time t
%                         and the link has been processed by the channel
%                         model
%                   (iii) SNRtensor : tensor [U x S x T] containing the
%                         linear SNR associated with each valid link
%                   (iv)  rateTensor : tensor [U x S x T] containing the
%                         achievable rate [bit/s] associated with each
%                         valid link
%                   (v)   pathGainTensor : tensor [U x S x T] containing
%                         the real nonnegative power gain obtained by
%                         combining FSPL gain and LMS fading power
%                   (vi)  distanceTensor : tensor [U x S x T] containing
%                         slant distance [m]. Propagation latency can be
%                         computed later from this quantity as d/c
%                   (vii) elevationClassTensor : tensor [U x S x T]
%                         containing the quantized elevation class assigned
%                         to each valid link
%                   (viii) numUsers : number of users
%                   (ix)  numSats : number of satellites
%                   (x)   numTimeSteps : number of simulation time samples
%
%       2. association_algorithm : String that define the type of
%       association method


%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. base_cost_tensor : tensor [U x S x T] containing the costs for
%       each time step. These costs are calculated indipendently from the
%       handover penalty.
%                   
%       2. weight_handover : scalar weight for the handover penalty to be applied later



%%   THINGS TO FIX:
%                   1) TUNING OF THE SCALAR WEIGHTS BASED ON THE RESULTS EVALUATED WITH THE KPIs   
%                   2) Defining the possibility, for the final user, to choose the scalar weights  
%   

function [base_const_tensor, weight_handover]=compute_base_cost_tensor(USER_SAT_evolution, configAssociation)


distanceTensor = USER_SAT_evolution.distanceTensor;    %If we take into account the distance or the latency nothing changes. Latency is linear proportional to the distance. 
rateTensor = USER_SAT_evolution.rateTensor;
validLinkMask = USER_SAT_evolution.validLinkMask;

minimumElev = configAssociation.minimumElev;
association_algorithm = configAssociation.association_algorithm;
%   ---NORMALIZATION STRATEGY--- 
%To have a fair comparison between the parameters to optimize, is needed a normalization in order to have all the values in the range [0,1];
%The normalization of physical quantities (distance, rate,...) is performed using theoretical, a-priori global values rather than 
%dynamically extracting the minimum and maximum values at each time step t.
%We use this approach for two reasons:
%      1)CAUSALITY: In a realistic scenario the system cannot know the absolute best or worst channel conditions 
%        of future states. This reasoning is applied for both the two simulation modes.
%      1)WEIGHT STABILITY: The building of the weight matrixs is modeled as combination of costs. 
%       If the denominator of the normalization for each quantity (max - min) changes at every time step based on local visibility, the effective weight of the metric fluctuates 
%       wildly over time steps (even if the absolute values are similar along time steps).
%       Using fixed theoretical limits is guaranteed that the weights maintain a consistent meaning all over the entire simulation time.

    % Internal convention: all distances are meters.
    altitude_satellites_m    = configAssociation.altitude_satellites_m;
    altitude_groundStation_m = configAssociation.altitude_groundStation_m;

    distance_min_m = altitude_satellites_m;

    % slantRangeCircularOrbit expects km and returns km.
    altitude_satellites_km    = altitude_satellites_m / 1e3;
    altitude_groundStation_km = altitude_groundStation_m / 1e3;

    distance_max_km = slantRangeCircularOrbit( ...
    minimumElev, ...
    altitude_satellites_km, ...
    altitude_groundStation_km);

    distance_max_m = distance_max_km * 1e3;
    rate_min = 0;            % Minimum possible rate (link lost)
    %The maximum possible rate is the one of the closest possible satellite (540e3m at 90 degree) with no fading effects. 
    %To calculate the maximum SNR possible WE NEED the cconfigAssociation
    %structure
    carrierFrequency = configAssociation.carrierFrequency;
    P_sat_lin = configAssociation.P_sat_lin;
    G_sat_lin=configAssociation.G_sat_lin;
    G_u_lin =configAssociation.G_u_lin;
    N_0 = configAssociation.N_0;
    channel_bandwidth =configAssociation.channel_bandwidth;
    
    c = 3e8; lambda = c/carrierFrequency;
    fsplGainLinear_max = (lambda / (4*pi*distance_min_m))^2;
    snr_max=(P_sat_lin * G_sat_lin * G_u_lin * fsplGainLinear_max) / N_0;
    
    rate_max = channel_bandwidth * log2(1 + snr_max);
    
    %For the distance: the higher is the distance, the higher is the cost. 
    cost_distance = (distanceTensor - distance_min_m) ./ ...
                (distance_max_m - distance_min_m);

    %For the rate: the higher is the rate, the lower must be the cost.
    cost_rate = 1 - ((rateTensor - rate_min)) ./ ((rate_max - rate_min)); 

     % Normalize the base cost to ensure values are within [0, 1]
    cost_distance = min(max(cost_distance, 0), 1);
    cost_rate = min(max(cost_rate, 0), 1);
    
    %Weight definition. All this weight must be tuned by trial and error.
    switch string (association_algorithm)
        case "URLLC"
            weight_distance = 0.8;      %To give priority to the minimum latency
            DeltaTau_switch_s= configAssociation.URLLC_DeltaTau_switch_s;
            weight_rate = 0.0;          %Not taking into account rate
            weight_handover = weight_distance * ...
                  (c * DeltaTau_switch_s) / ...
                  (distance_max_m - distance_min_m);
    
        case "eMBB"
            weight_distance = 0.0;      %Not taking into account latency
            DeltaR_switch_bps = configAssociation.eMBB_DeltaR_switch_bps;
            weight_rate = 0.8;          %Maximum priority to the rate
            weight_handover = weight_rate * DeltaR_switch_bps / rate_max;%High penalty to handover frequency 
    
       %Is it possible to define other vaues for the weights that are given by the final user. That values must be given as an input for this function.
    end
    
    %Definition of the base_const_tensor. The weight related to the handover penalty will be taken into account later.
    base_const_tensor = weight_distance * cost_distance + weight_rate * cost_rate;
    
    %To all the non valind links, we assign a infinite cost. In this way we are
    %sure that the Munkres algorithm will not select that links.
    base_const_tensor(~validLinkMask)=Inf;
end