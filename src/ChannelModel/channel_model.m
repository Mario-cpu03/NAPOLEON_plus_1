%% channel_model function
% This function computes the time evolution of the user-satellite channel
% quantities over the dynamically visible links.
%
% Internally, the model is a simplified trace-based statistical emulator.
% A bank of LMS fading traces is generated a priori, with one trace for each
% pair: user propagation environment x quantized elevation class
% In this first approximation, each trace is interpreted as a fixed
% class-conditioned fading ensemble. No sliding window, no deterministic
% per-link offset and no circular time indexing are used. Consequently, all
% visible links belonging to the same environment/elevation class are
% evaluated over the same representative fading ensemble.
%
% For each visible user-satellite-time link, the function:
%       (i)   reads distance and elevation from visibilityData;
%       (ii)  quantizes the elevation into one of the representative classes;
%       (iii) selects the corresponding environment/elevation fading trace;
%       (iv)  combines the fading statistics with the instantaneous FSPL
%             determined by the slant distance;
%       (v)   computes path gain, SNR and achievable rate;
%       (vi)  fills tensor outputs compatible with the association module.
%
% Two CSI modes are supported:
%       "ideal"    : distribution-aware class evaluation. The whole fading
%                    trace is used to compute average SNR and average
%                    instantaneous rate.
%       "forecast" : mean-profile class evaluation. Only the average fading
%                    power of the selected trace is used.
%
% In this simplified fixed-trace implementation, ideal and forecast modes
% are expected to produce essentially the same average SNR, while the rate
% may differ because:
%       mean(log2(1 + SNR)) ~= log2(1 + mean(SNR))
% A stronger ideal/forecast distinction can be introduced later by adding
% time-indexed trace windows or per-link trace offsets.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. configChannel : Data Structure containing the parameters needed
%       to configure the trace-based channel model:
%                   (i)   P_sat_lin : satellite transmit power [W]
%                   (ii)  G_sat_lin : satellite antenna gain [linear]
%                   (iii) G_u_lin : user antenna gain [linear]
%                   (iv)  N_0 : receiver noise power [W]
%                   (v)   channel_bandwidth : channel bandwidth [Hz]
%                   (vi)  carrierFrequency : carrier frequency [Hz]
%                   (vii) mobileSpeed : effective local fading speed [m/s]
%                   (viii) sampleRate : internal LMS sampling rate [Hz]
%                   (ix)  traceLengthSamples : number of LMS samples used
%                         to build each class-conditioned fading trace
%                   (x)   CSImode : either "ideal" or "forecast"
%
%       2. visibilityData : Data Structure containing the dynamic visibility
%       information returned by the satellite filtering stage:
%                   (i)   timeVec : row vector of simulation times
%                   (ii)  visibleSatIdx : cell array [T,U], where each cell
%                         contains the indices of the satellites visible to
%                         user u at time step t
%                   (iii) elevationDeg : cell array [T,U], where each cell
%                         contains the elevations associated with the
%                         visible satellites in visibleSatIdx{t,u}
%                   (iv)  distanceKm : cell array [T,U], where each cell
%                         contains the slant distances associated with the
%                         visible satellites in visibleSatIdx{t,u}
%                   (v)   numUsers : number of ground users/stations
%                   (vi)  numSats : number of satellites
%                   (vii) numTimeSteps : number of simulation time samples
%
%       3. groundEnv : column vector/string array of size numUsers
%       containing each ground user's propagation environment.

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
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

function [USER_SAT_evolution] = channel_model(configChannel, visibilityData, groundEnv)

% Dimensions
numUsers = visibilityData.numUsers;
numSats= visibilityData.numSats;
numTimeSteps = visibilityData.numTimeSteps;
timeVec = visibilityData.timeVec;

% Constants of the model
% needed only for FreeSacePathLoss computation
c = 3e8; lambda = c/configChannel.carrierFrequency;

% Retrieve input cells
visibleSatIdx=visibilityData.visibleSatIdx;
elevationDeg=visibilityData.elevationDeg;
distanceKm=visibilityData.distanceKm;

% Init otput tensors
validLinkMask=false(numUsers, numSats, numTimeSteps);

distanceTensor=NaN(numUsers, numSats, numTimeSteps);
elevationClassTensor=NaN(numUsers, numSats, numTimeSteps);

pathGainTensor=zeros(numUsers, numSats, numTimeSteps);
SNRtensor=NaN(numUsers, numSats, numTimeSteps);
rateTensor=NaN(numUsers, numSats, numTimeSteps);

%% A priori generation of the 16 LMS traces
% We have a static-like channel in which the coefficients are computed once
% and do not vary across different simulation intervals (samples of time window)
% The time - dependant behavior of the system is modeled only through the
% changing elevation angle of every user
traceBank = generate_trace_bank(configChannel);

% Mapping user to environment via an univocal index
userEnvIdx = zeros(numUsers,1); 
for u = 1:numUsers 
    userEnvIdx(u) = env_to_idx(groundEnv(u)); 
end

%% Main loop over visible links
for t = 1:numTimeSteps %time

    for u = 1:numUsers %fixing the user

        sats_t = visibleSatIdx{t,u}; %retreiving its set of visible satellytes

        if isempty(sats_t)
            continue; % This user at this time instant does not see any satellite
        end

        %retrieve users environment index, set of elevations to the visible satellites and set of distances
        elev=elevationDeg{t,u}; dist=distanceKm{t,u}; envIdx=userEnvIdx(u);

        for k = 1:numel(sats_t) 

            %retrieve the k-th satellite at time t, elevation index and distance
            %in meters
            s = sats_t(k);thetaDeg = elev(k);elevIdx=elevation_to_idx(thetaDeg);distM= dist(k)*1e3;

            if isnan(elevIdx)
                continue; %most probably will never be, but better safe than sorry
            end

            % Eventually, retrieve the trace bank 
            h2Trace = traceBank.h2{envIdx,elevIdx};
            h2Mean = traceBank.h2Mean(envIdx,elevIdx);

            fsplGainLinear = (lambda/(4*pi*distM))^2;%%Free-space path gain

            % We compute the fading virtually in two different ways, at
            % least logically. Thus, this "coefficient" is for fixed distance
            % a "constant" value under our model, that is, it does not
            % depend on the channel statistical mode.
            rhoNoFading=(configChannel.P_sat_lin*configChannel.G_sat_lin*configChannel.G_u_lin*fsplGainLinear) / configChannel.N_0;%%Deterministic SNR scaling without fading

            %% Channel mode switching technique
            switch string(configChannel.CSImode)

                case "ideal"
                    % Ideal mode: Use the whole class-conditioned fading ensemble.
                    snrBlock=rhoNoFading .* h2Trace; snrValue=mean(snrBlock);

                    pathGainValue = fsplGainLinear * mean(h2Trace);
                    
                    rateValue=configChannel.channel_bandwidth*mean(log2(1 + snrBlock));

                case "forecast"

                    % Forecast mode: Use only the average fading power of the class.
                    pathGainValue=fsplGainLinear * h2Mean;
                    snrValue=rhoNoFading * h2Mean;
                    rateValue=configChannel.channel_bandwidth*log2(1 + snrValue);

                otherwise

                    error('Unknown CSImode :((: Use "ideal" or "forecast".');

            end
            % note, all those access to configChannel may be avoided in
            % future, if the comp complex will become unbearable. At the
            % moment it is not a good practice, but still affordable

            %% Data persistency: 
            % we save the data by filling the tensors
            validLinkMask(u,s,t)=true;
            distanceTensor(u,s,t)= distM;

            % here, we basically use the channel bank to perform inverse mapping:
            % from index of elevation back to actual elevation.
            elevClass = traceBank.elevationClasses(elevIdx); elevationClassTensor(u,s,t) = elevClass; 
            
            pathGainTensor(u,s,t) = pathGainValue; SNRtensor(u,s,t)= snrValue;rateTensor(u,s,t)= rateValue;

        end
    end
end

%% Output structure FINALIZATION
USER_SAT_evolution.timeVec =timeVec;
USER_SAT_evolution.numUsers=numUsers;
USER_SAT_evolution.numSats= numSats;
USER_SAT_evolution.numTimeSteps = numTimeSteps;

USER_SAT_evolution.validLinkMask = validLinkMask;

USER_SAT_evolution.distanceTensor = distanceTensor;
USER_SAT_evolution.elevationClassTensor = elevationClassTensor;

USER_SAT_evolution.pathGainTensor=pathGainTensor;
USER_SAT_evolution.SNRtensor=SNRtensor;
USER_SAT_evolution.rateTensor=rateTensor;

end