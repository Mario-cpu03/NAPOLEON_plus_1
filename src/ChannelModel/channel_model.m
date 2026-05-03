%% Channel_model function
% This function defines the (random) information signal sent from each user
% and filters them simulating the LMS channel in compliance with the ITU-R 
% P.681 family. The goal is to obtain a representation of the
% overtime evolution of the user-satellite links by means of path gains,
% states, range and elevation.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. configChannel : Data Strcuture containing the parameters needed
%       to configurate the channel:
%                   (i) the carrier frequency
%                   (ii) the mobile speed
%
%       2. visibilityData: Data structure containing the dynamic
%       visibility information, of which we will only exploit:
%                   (i) timeVec : row vector of simulation times
%                   (ii) visibleSatIdx : cell array of size [T,U], where
%                         each cell contains the indices of the satellites
%                         visible to user u at time step t
%                   (iii) elevationDeg : cell array of size [T,U], where
%                         each cell contains the elevations of the visible
%                         satellites
%                   (iv) distanceKm : cell array of size [T,U], where each
%                         cell contains the slant distances of the visible
%                         satellites
%                   (v) numUsers : number of ground stations
%                   (vi) numSats : number of satellites
%                   (vii) numTimeSteps : number of time samples
%
%       3. groundEnv: column vector of size numUsers containing each
%       ground station's environment.

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%           1. USER_SAT_evolution: Data structure containing usersatassoc critical 
%           quantities, "metadata" linked to simulation consistency, and
%           "advanced quantities". Those 
%                       (i) timeVec: metadata-like quantity, to obtain the
%                       time indexing
%                       (ii) validLinkMask: critical quantity to derive the
%                       axctual "active" links
%                       (iii)SNRtensor: critical quantity to evaluate the 
%                       quality of the link                            
%                       (iv) ratetensor: critical quantity to evaluate the 
%                       the throughput of each link
%                       (v) pathGaintensor: critical diagnostic quantity                        
%                       (vi) distanceMatrix: not cruial but core quantity                   
%                       (vii) elevationMatrix: not cruial but core quantity                        
%                       (viii) numUsers: metadata-like quantity, to run through the users                 
%                       (ix) numSats : metadata-like quantity, to run through the satellites       
%                       (x) numTimeSteps: metadata-like quantity, to run
%                       through time indeces

%% %% %% AN IMPORTANT NOTE %% %% %% 
%%USER_SAT_evolution.validLinkMask, USER_SAT_evolution.SNR_matrix, 
%%USER_SAT_evolution.rateMatrix, and USER_SAT_evolution.pathGainMatrix 
%%can either be tensor or cell array. However, treating them as cell
%%arrays, even if more computationally effective, could require a rescale
%%of the weight matrix in the Association process, which yields a very
%%let's say uneffective way of dealing with it. On the contrary, tensors
%%with fixed dimensions will simply have numbers like 0 or -inf for
%%unavailable links, by means of actual availability or snr or rate or
%%gain, and meaningful values elsewhere. 


function [USER_SAT_evolution] = channel_model(configChannel, visibilityData, groundEnv)
    
    numUsers     = visibilityData.numUsers;
    numSats      = visibilityData.numSats;
    numTimeSteps = visibilityData.numTimeSteps;   
    timeVec      = visibilityData.timeVec;
    c  = 3e8; 

    dist_m_tensor          = visibilityData.distanceMatrix .*1000;
    elev_deg_tensor        = visibilityData.elevationMatrix;
    valid_link_mask_tensor = visibilityData.visibilityMask;
    
   

    %here the values are calculater vectorized. So simultaneously for every
    %time istant.
    [channel_gain_tensor,channel_state_tensor] = compute_channel_coefficient(configChannel,visibilityData, groundEnv);      % this function computers the product L(.) |h(.)^2|. this product will be used to calculate the snr
    latency_tensor=compute_latency(dist_m_tensor,c);

    %to delete once the functions will be developed. Just to debugging
    snr_tensor       = compute_snr(channel_gain_tensor,configChannel);
    rate_tensor      = compute_bitrate(snr_tensor, configChannel);


    %in this way the visibilityMask is applied simultaneously for all time
    %istants
    dist_m_tensor(~valid_link_mask_tensor)        = NaN;
    elev_deg_tensor(~valid_link_mask_tensor)      = NaN;
    latency_tensor(~valid_link_mask_tensor)       = NaN;
    channel_gain_tensor(~valid_link_mask_tensor)  = 0;
    channel_state_tensor(~valid_link_mask_tensor) = NaN;
    snr_tensor(~valid_link_mask_tensor)           = 0;
    rate_tensor(~valid_link_mask_tensor)          = 0;


    USER_SAT_evolution.timeVec         = timeVec;
    USER_SAT_evolution.numUsers        = numUsers;
    USER_SAT_evolution.numSats         = numSats;
    USER_SAT_evolution.numTimeSteps    = numTimeSteps;
    
    USER_SAT_evolution.validLinkMask   = valid_link_mask_tensor;
    USER_SAT_evolution.distanceMatrix  = dist_m_tensor;
    USER_SAT_evolution.elevationMatrix = elev_deg_tensor;
    USER_SAT_evolution.latencyTensor   = latency_tensor;
    USER_SAT_evolution.pathGainTensor  = channel_gain_tensor;
    USER_SAT_evolution.stateTensor     = channel_state_tensor;
    USER_SAT_evolution.SNRtensor       = snr_tensor;
    USER_SAT_evolution.rateTensor      = rate_tensor;
    