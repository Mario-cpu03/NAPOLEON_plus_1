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


%Here we construct the weight matrix. Since it will be computational costly to buit it time step per time step, here we build a cost tensor without taking into account the handover penalty.  
%The parameter that models the handover penalty will be give as output of the function. That will be consider when we call the Munkres time instant per time instant. 
%In this way we optimize as much as possible the computational cost. 
%As it is defined, the base_cost_tensor has values in range [0,2) (limit case that actually will never happend), not taking into account the handover penalization.
%Actual values will be in range [0,1.#]

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
[base_cost_tensor,handover_parameter]=compute_base_cost_tensor(USER_SAT_evolution,association_algorithm, configChannel);




%   NEXT STEP IS TO IMPLEMENT A LOOP THAT, FOR EACH TIME STEP, ADDS THE
%   HANDOVER PENALTY TO THE COST MATRIX. 
%   THEN, FOR EACH TIME STEP, THE MUNKRES OPTIMIZER WILL BE CALLED TO FIND
%   THE MINIMUM COST ASSOCIATIONS BETWEEN USERS AND SATELLIUTES.



end