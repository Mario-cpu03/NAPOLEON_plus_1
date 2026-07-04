%This function has to comupute the history of the selected links between user-sat pairs.
%The selection of each link is performed by means of Munkres-based algorithm variances, each representing a use-case of the IMT-2020 standard.
%Since the Munkres algorithm is a cost/reward optimizer, the different kinds of association methods are implemented changing, for each method, the
%weights associated to each parameter (like SNR, rate, latency, handover frequency).
%   Namley:
%           1)URLLC inspired association:
%                                 With this algorithm, the aim is to minimize the latency, optimizing handover frequency,
%                                 without optyimizing SNR and rate. 
%
%           2)Enhanced Mobile Broadband inspired association (eMBB):
%                                 Here the aim is to maximize the SNR, data rate, without taking into account latency, 
%                                 but strongly penalizing costly handovers.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. USER_SAT_evolution : Data Structure containing metadata and
%       tensor quantities required by the UserSatAssoc module
%
%       2. association_algorithm : string describing the algorithm chosen
%       by the end user, needed for normalization purposes (see documentation 
%       of compute_base_cost_tensor into the munkres_helper_functions folder)

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%           Data structure containing the association between the users with a satellite along time istants. 
%           Furthermore, the output data structure should contains all the data required for the KPI module. 
%           1. USER_SAT_association : Data Structure containing metadata and
%           tensor quantities required by the KPI module:
%                   (i) assignedSatIdx, matrix of association per time instant
%                   (ii) SNR_lin, matrix of linear SNR per association
%                   (iii) rate_bps, matrix of obtained rate per
%                   association in bit per second. 
%                   (iv) distance_m, matrix of distance in meters, per
%                   association
%                   (v) latency_s, matrix of latency per association
%                   (vi) handoverEvent, matrix of booleans per association
%                   describing the handover events (1 = handover, 0 = no-handover)
%                   (vii) servedMask, debugging purposes matrix mask (boolean) to evaluate
%                   actual service rates
%                   (viii) numUsers
%                   (ix) numSats
%                   (x) numTimeSteps
%                   (xi) association_algorithm, kind of assoc algo
%                   (xii) timeVec
%                   (xiii) totalHandoversPerUser, totalHandoversSystem,
%                   servedRatioPerUser, and servedRatioSystem; control
%                   informations for debugging purposes

function [USER_SAT_association]=main_association_function(USER_SAT_evolution, configAssociation)

    %addpath('UserSatAssoc/munkres_helper_functions/'); %helper functions for the construction of the weights matrix    

    %Here we construct the weight matrix. Since it will be computational costly to buit it time step per time step, here we build a cost tensor without taking into account the handover penalty.  
    %The parameter that models the handover penalty will be give as output of the function. That will be consider when we call the Munkres time instant per time instant. 
    %In this way we optimize as much as possible the computational cost. 
    %As it is defined, the base_cost_tensor has values in range [0,2) (limit case that actually will never happend), not taking into account the handover penalization.
    %Actual values will be in range [0,1.#]
    association_algorithm = configAssociation.association_algorithm;

    [base_cost_tensor,handover_weight]=compute_base_cost_tensor(USER_SAT_evolution, configAssociation);    
        
    [U, S, T] = size(base_cost_tensor);
    
    G=configAssociation.G;                   % max number of possible connections per satellite
      
    %%OUTPUT INIT VIA MATRIX APPROACH
    USER_SAT_association.assignedSatIdx = NaN(U, T);
    USER_SAT_association.rate_bps  = NaN(U, T);
    USER_SAT_association.SNR_lin = NaN(U, T);
    USER_SAT_association.distance_m = NaN(U, T);
    USER_SAT_association.latency_s = NaN(U, T);
    USER_SAT_association.handoverEvent = false(U, T);

    % DEBUGGING PURPOSES STRUCTURE
    % This logical matrix is used only to check whether each user is
    % actually served at each time step. It is independent from the simulator
    % logic: removing it does not affect the association algorithm, the
    % Munkres optimization, or the handover computation.
    USER_SAT_association.servedMask = false(U, T);
    
    prev_association = false(U, S);
    
    c = 3e8;  
    for t = 1:T
    
        real_sat_idx = zeros(U, 1);                                 %inizialization of the vector that will contains the real indices of the associations  
        current_association = false(U, S);

        cost_matrix = base_cost_tensor(:,:,t);      %exract only the costs for that time step
    
        %To optimize, next step is to remove from the cost matrix all the
        %columns that represent satellites that are unavaible for that time
        %step (that have, for each row, only values = inf). 
    
        visible_sats_mask = any(cost_matrix ~=Inf, 1);                  % 1 if the satellite could be connected, 0 otherwise
        visible_sats_indices = find(visible_sats_mask);                 %returns only the avaible satellites
        reduced_cost_matrix = cost_matrix(:, visible_sats_mask);        %this matrix contains only the costs of the possible connections that could be instantiated
    
        %now we have to apply the handover penalty
        if t>1   
            reduced_prev_assoc_mask = prev_association(: , visible_sats_mask);    %this logical matrix is 1 if at t-1 there was an association. 
                                                                                  %since visible_sats_mask "contains" only the columns of avaible satellites,  reduced_prev_assoc_mask
                                                                                  %already takes into account the reduced number of columns
            handover_penalty = handover_weight * (~reduced_prev_assoc_mask);      %if reduced_prev_assoc_mask(x,y)=0 then ~reduced_prev_assoc_mask(x,y)=1, so we add the handover penalty.
            reduced_cost_matrix = reduced_cost_matrix + handover_penalty;             
        end
    
        %now we have to take into account the fact that a satellite could be
        %connected to G users. We "clone" the columns.
        %The cost matrix will be U x (G*S_visible).
        %After the Munkres, we have to remap the "virtual indices" to the real ones
        expanded_cost_matrix = repelem(reduced_cost_matrix, 1, G);          %replace every columns G times
        num_virtual_sats = size(expanded_cost_matrix, 2);
    
        %now we havo to perform the munkres
        assignment = munkres(expanded_cost_matrix);     %munkres function will return a row vector with dimensions [1 x U]. 
                                                      %the value for every index represent the index of the assigned satellite for that user

        %Munkres will return also the assignment for the dummy users. We filter out that associations.
        virt_sat_idx = assignment(1:U);         %the first U values are the ones for the actual U users
        virt_sat_idx = virt_sat_idx(:);         %to obtain a column vector

        valid_users = (virt_sat_idx > 0) & (virt_sat_idx <= num_virtual_sats);      %we make this check to be sure that the index is >0 (satellite associated) and <= num_virtual_sats (to avoid index errors)
        
        %Munkres could returns (in limit cases) associations with infinite cost.
        %We make this check to avoid infinite costs in the
        %square_cost_matrix. This would be useless, but it is better to
        %check. 
        if any(valid_users)
            idx_cost = sub2ind(size(expanded_cost_matrix), find(valid_users), virt_sat_idx(valid_users));
            
            is_inf = expanded_cost_matrix(idx_cost) == Inf;
            
            valid_users_indices = find(valid_users);
            valid_users(valid_users_indices(is_inf)) = false; 
        end

        if any(valid_users)
        
            % Map virtual satellite index -> visible satellite index
            slot_idx = ceil(virt_sat_idx(valid_users) / G);
        
            % Map visible satellite index -> real satellite index
            real_sat_idx(valid_users) = visible_sats_indices(slot_idx);
        
            % Actual users associated at this time step
            user_idx = find(valid_users);
        
            % Build boolean association matrix.
            % This is still needed internally for the handover penalty at the next
            % time step, but it is no longer stored over all time steps.
            lin_idx = sub2ind([U, S], user_idx, real_sat_idx(valid_users));
            current_association(lin_idx) = true;
        
            % Linear indices into the original [U x S x T] channel tensors
            lin_idx_tensor = sub2ind( ...
                [U, S, T], ...
                user_idx, ...
                real_sat_idx(valid_users), ...
                t * ones(numel(user_idx), 1));
        
            % Compact output storage
            USER_SAT_association.assignedSatIdx(user_idx, t) = real_sat_idx(valid_users);

            % DEBUGGING PURPOSES STRUCTURE
            % Mark the users that received a valid selected link at this
            % time step. This is only used to distinguish "no handover
            % because the satellite did not change" from "no handover
            % because the user was not served".
            USER_SAT_association.servedMask(user_idx, t) = true;
        
            USER_SAT_association.rate_bps(user_idx, t) = ...
                USER_SAT_evolution.rateTensor(lin_idx_tensor);
        
            USER_SAT_association.SNR_lin(user_idx, t) = ...
                USER_SAT_evolution.SNRtensor(lin_idx_tensor);
        
            USER_SAT_association.distance_m(user_idx, t) = ...
                USER_SAT_evolution.distanceTensor(lin_idx_tensor);
        
            USER_SAT_association.latency_s(user_idx, t) = ...
                USER_SAT_association.distance_m(user_idx, t) / c;
        
        end
        
        if t > 1
        
            prevSat = USER_SAT_association.assignedSatIdx(:, t-1);
            currSat = USER_SAT_association.assignedSatIdx(:, t);
        
            bothServed = ~isnan(prevSat) & ~isnan(currSat);
        
            USER_SAT_association.handoverEvent(:, t) = bothServed & (currSat ~= prevSat);
        
        end
        
        prev_association = current_association;
    end

    USER_SAT_association.numUsers = U;
    USER_SAT_association.numSats = S;
    USER_SAT_association.numTimeSteps = T;
    USER_SAT_association.association_algorithm = association_algorithm;

    USER_SAT_association.timeVec = USER_SAT_evolution.timeVec;
    
    USER_SAT_association.totalHandoversPerUser =sum(USER_SAT_association.handoverEvent, 2);
    
    USER_SAT_association.totalHandoversSystem = sum(USER_SAT_association.totalHandoversPerUser);

    % DEBUGGING PURPOSES STRUCTUREs
    USER_SAT_association.servedRatioPerUser = mean(USER_SAT_association.servedMask, 2);
    USER_SAT_association.servedRatioSystem = mean(USER_SAT_association.servedMask(:));

end