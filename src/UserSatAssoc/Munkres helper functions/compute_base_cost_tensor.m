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
%                   1) configCost : This function uses configCost.altitude (see below why). 
%                                   This structure is defined inside the main_channel_function, but hardcoded here. 
%                                   To maintain a good code design, should be passed here as an input (all the structure or just the value).
%                   2) minimumElev : This function uses minimumElev (see below why).
%                                    This structure is defined inside the main_channel_function, but hardcoded here. 
%                                    To maintain a good code design, should be passed here as an input (all the structure or just the value).
%                   3) configChannel : This function uses configChannel.carrierFrequency, configChannel.P_sat_lin, configChannel.G_sat_lin, configChannel.G_u_lin, configChannel.N_0, configChannel.channel_bandwidth
%                                      This structure is already passed here as input parameter, but need design fix before the calling of this function. 
%                   
%                   4) TUNING OF THE SCALAR WEIGHTS BASED ON THE RESULTS EVALUATED WITH THE KPIs   
%                   5) Defining the possibility, for the final user, to choose the scalar weights  
%   
%%




function [base_const_tensor, weight_handover]=compute_base_cost_tensor(USER_SAT_evolution, association_algorithm, configChannel)


distanceTensor = USER_SAT_evolution.distanceTensor;    %If we take into account the distance or the latency nothing changes. Latency is linear proportional to the distance. 
rateTensor = USER_SAT_evolution.rateTensor;
validLinkMask = USER_SAT_evolution.validLinkMask;


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


    %Theoretical System Constant
    altitude_satellites = 540e3;     % HARD CODED HERE. MUST BE TAKEN FRON THE STRUCT configConst
    altitude_groundStation = 0;      % Here we are using the Mean Sea Level (MSL) assumption. This is the same reasoning applied in the thesis. 
                                     % To be more accurate, we could define the altitude_groundStation as the mean altitude of the continental Europe.
                                     % However, the difference in the results is negligible, since the gs altitude is order of magnitude lower than the
                                     % satellites altitude.
    
    minimumElev = 25;                       %HARD CODED HERE. MUST BE PASSED AS AN INPUT SOMEHOW
        
    distance_min = altitude_satellites;     % Minimum possible distance (satellite at zenit)
    %The maximum possible distance is the one of a satellite that has an elevation of 25 degree . 
    %In orther to calculate this quantity, we use the function of the SatelliteToolbox
    distance_max =  slantRangeCircularOrbit(minimumElev, altitude_satellites, altitude_groundStation);
        
    rate_min = 0;            % Minimum possible rate (link lost)
    %The maximum possible rate is the one of the closest possible satellite (540e3m at 90 degree) with no fading effects. 
    %To calculate the maximum SNR possible WE NEED the configChannel structure
    c = 3e8; lambda = c/configChannel.carrierFrequency;
    
    fsplGainLinear_max = (lambda / (4*pi*distance_min))^2;
    snr_max=(configChannel.P_sat_lin * configChannel.G_sat_lin * configChannel.G_u_lin * fsplGainLinear_max) / configChannel.N_0;
    
    rate_max = configChannel.channel_bandwidth * log2(1 + snr_max);
    
    %For the distance: the higher is the distance, the higher is the cost. 
    cost_distance = (distanceTensor - distance_min) ./ (distance_max - distance_min);
    
    %For the rate: the higher is the rate, the lower must be the cost.
    cost_rate = 1 - ((rateTensor - rate_min)) ./ ((rate_max - rate_min)); 
    
    
    %Weight definition. All this weight must be tuned by trial and error.
    switch string (association_algorithm)
        case "URLLC"
            weight_distance = 0.8;      %To give priority to the minimum latency
            weight_handover = 0.2;      %To consider handover frequency
            weight_rate = 0.0;          %Not taking into account rate
    
        case "eMBB"
            weight_distance = 0.0;      %Not taking into account latency
            weight_handover = 0.4;      %High penalty to handover frequency
            weight_rate = 0.6;          %Maximum priority to the rate
    
       %Is it possible to define other vaues for the weights that are given by the final user. That values must be given as an input for this function.
    end
    
    %Definition of the base_const_tensor. The weight related to the handover penalty will be taken into account later.
    base_const_tensor = weight_distance * cost_distance + weight_rate * cost_rate;
    
    %To all the non valind links, we assign a infinite cost. In this way we are
    %sure that the Munkres algorithm will not select that links.
    base_const_tensor(~validLinkMask)=Inf;
end