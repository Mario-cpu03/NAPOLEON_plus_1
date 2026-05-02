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
    [channel_gain_tensor, channel_state_tensor] = compute_channel_coefficient(configChannel,visibilityData, groundEnv);      % this function computers the product L(.) |h(.)^2|. this product will be used to calculate the snr
    latency_tensor=compute_latency(dist_m_tensor,c);

    %to delete once the functions will be developed. Just to debugging
    snr_tensor       = zeros(numUsers, numSats, numTimeSteps);
    rate_tensor      = zeros(numUsers, numSats, numTimeSteps);


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
    


 %%The code below is the one that iterate for every time istant. 
 %Thai is much slower than working with tensors, but i kept it there to
 %remember the reasoning. After testing, this code will be deleted.

%     for t = 1:numTimeSteps
% 
%         %data for every time step
%         dist_km    = visibilityData.distanceMatrix(:,:,t);  %this is in km 
%         dist_m = dist_km .* 1000;
%         elev_deg   = visibilityData.elevationMatrix(:,:,t);
%         valid_mask = visibilityData.visibilityMask(:,:,t);    

 % % Array of Structs Initialization   
 %    empty_matrix = NaN(numUsers, numSats);
 %    template_struct = struct( ...
 %        'distance',  empty_matrix, ...
 %        'elevation', empty_matrix, ...
 %        'latency',   empty_matrix, ...
 %        'pathGain',  empty_matrix, ...
 %        'state',     empty_matrix, ...
 %        'SNR',       empty_matrix, ...
 %        'bitrate',   empty_matrix);
 % 
 %     USER_SAT_evolution = repmat(template_struct, numTimeSteps, 1);
% 
% 
%         pathGain_matrix  =  channelGainTensor(:,:,t);        
%         state_matrix  =  channelStateTensor(:,:,t);
% 
%         % Compute quantities
%         latency_matrix  = compute_latency(dist_m, c);
%         %snr_matrix      = compute_snr(pathGain_matrix, configChannel);      
%         %bitrate_matrix  = compute_bitrate(snr_matrix, B);
% 
%         %when those two functions will be developed, the two sequent lines
%         %of code must be deleted. Just for debugging, otherwise mathlab
%         %will arises an error
%         snr_matrix      = zeros(numUsers, numSats);
%         bitrate_matrix  = zeros(numUsers, numSats);
% 
% 
%         % Links that are not geometrically visible are set to 0 or NaN 
%         dist_m(~valid_mask)         = NaN;
%         elev_deg(~valid_mask)       = NaN;
%         latency_matrix(~valid_mask) = NaN;
%         pathGain_matrix(~valid_mask)= 0;
%         state_matrix(~valid_mask)   = NaN;
%         snr_matrix(~valid_mask)     = 0;
%         bitrate_matrix(~valid_mask) = 0;
% 
%        %sava data in the array of struct
%         USER_SAT_evolution(t).distance  = dist_m;
%         USER_SAT_evolution(t).elevation = elev_deg;
%         USER_SAT_evolution(t).latency   = latency_matrix;
%         USER_SAT_evolution(t).pathGain  = pathGain_matrix;
%         USER_SAT_evolution(t).state     = state_matrix;
%         USER_SAT_evolution(t).SNR       = snr_matrix;
%         USER_SAT_evolution(t).bitrate   = bitrate_matrix;
% 
%     end
% end

%%% NEED TO DEFINE THE FUNCTIONS THAT CALCULATES THE SNR AND BITRATE