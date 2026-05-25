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

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%           Data structure containing the association between the users with a satellite along time istants. 
%           Furthermore, the output data structure should contains all the datas required for the KPI module. 
%           For example: 
%           1. USER_SAT_association : Data Structure containing metadata and
%           tensor quantities required by the KPI module:
%                   (i)     associationTensor:tensor [U x S x T] containing the
%                           association between a user and a satellite for every time istant (boolean) 
%                   (ii)    SNRtensor : tensor [U x S x T] containing the
%                           linear SNR for every association
%                   (iii)   rateTensor : tensor [U x S x T] containing the
%                           achievable rate [bit/s] for every association
%                   (iv)    distanceTensor : tensor [U x S x T] containing
%                           slant distance [m] for every association. Propagation latency can be
%                           computed later from this quantity as d/c
%                   (v) OTHERS TO BE DEFINED. THAT WILL BE DEFINED BASED ON
%                       THE KPI FUNCTION THAT WILL BE IMPLEMENTED


%%   THINGS TO FIX:
%                   1) Input arguments for the compute_base_cost_tensor function (see comments inside the function)
%                   1) configChannel Should not be defined here, but should
%                   be given as input parameter of the main_association_function (then tocompute_base_cost_tensor function)
%   
%%



function [USER_SAT_association]=main_association_function(USER_SAT_evolution, numUsers, association_algorithm)

    addpath('UserSatAssoc/Munkres helper functions'); %helper functions for the construction of the weights matrix    
    
    %%              --- SHOULD NOT BE THERE, JUST FOR DEBUGGING---
    
    %We need this since the compute_base_cost_tensor functions normalizes the
    %values with theoretical quantities that depends on how we defined the
    %simulation scenario (see comments inside the function).
    k_B = 1.380649e-23; %Boltzmann konstant
    T_sys = 290; %std teemparature for noise computation
    B = 5e6; % bandwidth 5MHz 
    
    configChannel = struct( ...
        'P_sat_lin', 1, ... % power of the signal, one watt as a starting base, may be varied if needed 
        'G_sat_lin', 10^(50/10), ... %gain of the satellite antenna
        'G_u_lin', 10^(0/10), ... %0dBi of gain for the user assuming isotropic antenas
        'N_0', k_B*T_sys*B, ... %noise power
        'channel_bandwidth', B, ... %bandwidth of the system on each channel
        'carrierFrequency', 2e9, ... %itu-r aligned carrier
        'mobileSpeed', 5000/3600, ... % assuming a 5km/h speed to obtain doppler shift: v=1.389m/s --> f_Dmobile = v*f_c/c = 9.2593 Hz approx 10Hz
        'sampleRate', 100, ... %see note below
        'traceLengthSamples', 2000, ... %number of samples obtained as the channel sample rate times the sample time of the simulator: 200[1/s]*20[s] = 4000
        'CSImode', mode); %mode of the channel. See channel_model for more information
    
    %%


    %Here we construct the weight matrix. Since it will be computational costly to buit it time step per time step, here we build a cost tensor without taking into account the handover penalty.  
    %The parameter that models the handover penalty will be give as output of the function. That will be consider when we call the Munkres time instant per time instant. 
    %In this way we optimize as much as possible the computational cost. 
    %As it is defined, the base_cost_tensor has values in range [0,2) (limit case that actually will never happend), not taking into account the handover penalization.
    %Actual values will be in range [0,1.#]
    
    [base_cost_tensor,handover_weight]=compute_base_cost_tensor(USER_SAT_evolution,association_algorithm, configChannel);    
        
    [U, S, T] = size(base_cost_tensor);
    
    G=2;                         % max number of possible connections per satellite. HARD CODED HERE. SHOULD BE PASSED AS AN INPUT FOR THE FUNCTION
        
    USER_SAT_association.associationTensor = false(U, S, T);    %Initialization of the output structure
    prev_association = false(U, S);                             %Inizialization of the matrix that we use to consider the handover penalization strategy
    
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
    
    
        %Munkres works with square matrix, so we have to insert "dummy" rows in
        %the expanded_cost_matrix. 
        num_dummies = num_virtual_sats - U;    
    
        if num_dummies > 0

            %if there are more visible slots than users, we add num_dummies rows
            %to the expanded_cost_matrix. Every row has cost 0
            dummy_matrix = zeros(num_dummies, num_virtual_sats);
            square_cost_matrix = [expanded_cost_matrix; dummy_matrix];

        elseif num_dummies < 0

            %if there are more users that visible slots.
            %almost impossible case, only to be sure that the munkress will always work. 
            dummy_cols = Inf(U, abs(num_dummies));
            square_cost_matrix = [expanded_cost_matrix, dummy_cols];

        else
            square_cost_matrix = expanded_cost_matrix;   
        end
    
    
        %now we havo to perform the munkres
        assignment = munkres(square_cost_matrix);     %munkres function will return a row vector with dimensions [1 x U]. 
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
            % Troviamo le coordinate (Riga, Colonna) solo per gli utenti attualmente 'true'
            idx_cost = sub2ind(size(square_cost_matrix), find(valid_users), virt_sat_idx(valid_users));
            
            % Troviamo quali di queste connessioni sono fisicamente impossibili (Inf)
            is_inf = square_cost_matrix(idx_cost) == Inf;
            
            % Selezioniamo gli indici degli utenti validi e li forziamo a 'false' se il costo è Inf
            valid_users_indices = find(valid_users);
            valid_users(valid_users_indices(is_inf)) = false; 
        end

        if any(valid_users)
            % Map virtual satellite index -> visible satellite index
            slot_idx = ceil(virt_sat_idx(valid_users) / G);       %Ex: ceil(15/2)=8;  

            % Map visible satellite index -> real satellite index
            real_sat_idx(valid_users) = visible_sats_indices(slot_idx);

            % Build boolean association matrix
            lin_idx = sub2ind([U, S], find(valid_users), real_sat_idx(valid_users));
            current_association(lin_idx) = true;
        end    
        
    
        USER_SAT_association.associationTensor(:,:,t) = current_association;
        prev_association = current_association;
    end
end