%This function computes the channel gain tensor [numUsers x NumSatellites x NumTimeSteps].
%This tensor contains, for every possible link at every time istant, the
%product between the Free Space Path Loss (FSPL) and the stochestic Land
%Mobile Satellite (LMS) fading based on the ITU-R P.&81 standard.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. configChannel : Data Strcuture containing the parameters needed
%       to configurate the channel:
%                   (i) the carrier frequency
%                   (ii) the mobile speed
%                   (iii) the sample rate of the channel
%
%       2. visibilityData: Data structure containing the dynamic
%       visibility information, of which we will only exploit:
%                   (i)distanceKm : cell array of size [T,U], where each
%                         cell contains the slant distances of the visible
%                         satellites
%                   (ii) visibilityMask : logical array of size [U,S,T]
%                   (iii) elevationMatrix : array of size [U,S,T]
%                   (iv) distanceMatrix : array of size [U,S,T]
%                   (v) numUsers : number of ground stations
%                   (vi)numSats : number of satellites
%                   (vii) numTimeSteps : number of time samples
%       3. groundEnv : column vector of size numUsers containing each
%       ground station's environment. 

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%           1. channelGainTensor: A numeric array of size [numUsers x numSats x
%       numTimeSteps]. Every element (u,s,t) contains the coefficient
%       representing the phisical attenuation. The attenuatio is modelled
%       by the composition of the FSPL and fading.
%           2. channelStateTensor: A numeric array of size [numUsers x numSats x
%       numTimeSteps]. Every element (u,s,t) contains the state of the link
%       between user u and satellite s, at the time instant t.




%%IMPORTANT
%L is defined as the inverse of the FSPT, it is the channel gain.


function [channelGainTensor,channelStateTensor] = compute_channel_coefficient(configChannel, visibilityData,groundEnv)

%constants
c=3e8;
lamda=c/configChannel.carrierFrequency;


[numUsers, numSats,numTimeSteps]=size(visibilityData.visibilityMask);

%preallocation for efficiency
channelGainTensor=zeros(numUsers, numSats, numTimeSteps);
channelStateTensor = NaN(numUsers, numSats, numTimeSteps);
    

%%computation of the FSPL
dist_m = visibilityData.distanceMatrix .* 1000;    %becaouse the distace in the matrix are given in kilometers
L_linear = ( lamda ./(4 * pi .* dist_m)).^2;    %like in the thesis (inverse of FSPL)


%fading computation
for u=1:numUsers
    currentEnv=groundEnv(u);   %take the environment of that users
    
    for s=1:numSats
        linkMask=squeeze(visibilityData.visibilityMask(u,s,:));

        if ~any(linkMask), continue;  end   %to skip the computation if the satellite s is never visible to the user u

        elevAngles=squeeze(visibilityData.elevationMatrix(u,s,linkMask));  %the sequence of elevation angles between user u and satellite s
       
        numVisible = length(elevAngles);
        meanElev = mean(elevAngles);
        
        lmsChannel = p681LMSChannel( ...
            'CarrierFrequency', configChannel.carrierFrequency, ...
            'Environment',      currentEnv, ...
            'MobileSpeed',      configChannel.mobileSpeed, ...
            'SampleRate',       configChannel.sampleRate, ...
            'ElevationAngle',   meanElev);

            txSignal = ones(numVisible, 1);
            [~, pathgains_complex, ~, stateSequence] = lmsChannel(txSignal);
            
            fading_linear_all = abs(pathgains_complex).^2;
            release(lmsChannel); 
            
            L_valid = squeeze(L_linear(u, s, linkMask));
            combined_gain = fading_linear_all .* L_valid;
            
            % Reshape
            channelGainTensor(u, s, linkMask)  = reshape(combined_gain, 1, 1, []);
            channelStateTensor(u, s, linkMask) = reshape(stateSequence, 1, 1, []);


                 
    end

end


end