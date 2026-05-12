%This function has to comupute the history of the salacted links between
%user-sat pairs.
%The selection of each link is performed by means of Munkres-based
%algorithm variances, each representing a use-case of the IMT-2020 standard.
%Since the Munkres algorithm is a cost/reward optimizer, the different
%kinds of association methos are implemented changing, for each method, the
%weights associated to each parameter (like SNR, rate, latency, handover
%frequency).
%   Namley:
%           1)URLLC inspired association:
%                                 With this algorithm, the aim is to
%                                 minimize the latency and handovers between a user and
%                                 satellites, without optyimizing SNR and
%                                 rate. 
%           2)Enhanced Mobile Broadband inspired association:
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
%           Furthermore, the output data structure should contains all the
%           datas required for the KPI module. 
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

function [USER_SAT_association]=main_association_function(USER_SAT_evolution)

%From here the function could be divided into two logical flow:

%   Using Munkres-algorithm based reasoning: 
%                               1)Build the weight matrices for every time
%                               step;
%                               2)Calling the function munkres_algorithm()
%                               to obtain the best possible association
%                               between user and satellites.
%                               3) Store the data inside the
%                               USER_SAT_association output structure

%           What is important to say is that, with this workflow, it is
%           possible to implement different types of algorithms. 
%           In particular, since the weight matrix will be calculated from a
%           function, tuning the parameters of that function we are able to
%           optimize "something" and penalize "something else". (something could be the rate, latency, # of andowers,... whatevery we want) 
%           Example of function:    weight[i,j] = alfa * parameter_to_optimize[i,j] +/- beta * parameter_to_penalize[i,j] 
%           Once the weight matrix is built, the munkres_algorithm()
%           function will be called to obtain the perfect association that
%           ensure the minimum weight.

%%%   -----  THIS IS JUST AN IMPLEMENTING EXAMPLE, NOT THE FINAL CODE!!!  ---

%switch case for the 2 different approach: 1-Munkres-based
%                                          2-Simpler

%For the sake of simplicity, from now on only the Munkres-based approach is
%taken into account
% Initialize the weight matrix for each time step
numTimeSteps = size(USER_SAT_evolution, 3);
weightMatrix = zeros(numUsers, numSats, numTimeSteps);

for t = 1:numTimeSteps
    % Extract parameters for the current time step
    parameterToOptimize = USER_SAT_evolution.something(:, :, t); % Example parameter
    parameterToPenalize = USER_SAT_evolution.something_else(:, :, t); % Example penalty

    % Build the weight matrix based on the optimization and penalty
    % parameters.
    % alfa and beta will change following the logic we want to implement, they could also be submitted by the final
    % user.
    %Maybe we could define 3 or more different approach, the only things
    %that we have to change for each one are the parameters alfa and beta.
    weightMatrix(:, :, t) = alfa * parameterToOptimize - beta * parameterToPenalize;
end

% Call the Munkres algorithm to find the optimal association
USER_SAT_association.associationTensor = munkres_algorithm(weightMatrix);











end