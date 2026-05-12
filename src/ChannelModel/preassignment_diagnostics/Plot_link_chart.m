%% Plot_link_availability_chart function
% This function plots the link availability chart in the same style as the
% reference figure shared in the discussion.
% A user is marked as available at time t if at least one valid link exists.

function Plot_link_chart(USER_SAT_evolution, snapshotTime, visibilityData, sampleTime)

% Computing sample time index from snapshot
timeIdx = round(snapshotTime*60 / sampleTime) + 1;

% Safety check
if timeIdx < 1 || timeIdx > visibilityData.numTimeSteps
    error('Requested snapshotTime is outside the available visibilityData time window.');
end

% Plot number of visible satellites per user
numVisiblePerUser = zeros(1, visibilityData.numUsers);

for u = 1:visibilityData.numUsers
    numVisiblePerUser(u) = numel(visibilityData.visibleSatIdx{timeIdx, u});
end

mask_t      = USER_SAT_evolution.validLinkMask(:,:,timeIdx);
snrLin_t    = USER_SAT_evolution.SNRtensor(:,:,timeIdx);
rate_t      = USER_SAT_evolution.rateTensor(:,:,timeIdx);
dist_t      = USER_SAT_evolution.distanceTensor(:,:,timeIdx);
elevClass_t = USER_SAT_evolution.elevationClassTensor(:,:,timeIdx);

% Extract only valid links
snrLin_valid    = snrLin_t(mask_t);
rate_valid      = rate_t(mask_t);
dist_valid_m    = dist_t(mask_t);
elevClass_valid = elevClass_t(mask_t);

% Useful conversions
snrDb_valid   = 10*log10(snrLin_valid);
rateMbps_valid = rate_valid / 1e6;
distKm_valid   = dist_valid_m / 1e3;
latencyMs_valid = dist_valid_m / 3e8 * 1e3;   % one-way propagation delay



figure;
scatter(distKm_valid, snrDb_valid, 40, elevClass_valid, 'filled');
xlabel('Slant range [km]');
ylabel('SNR [dB]');
title(sprintf('SNR vs slant range at t = %.1f min', snapshotTime));
cb = colorbar;
cb.Label.String = 'Elevation class';
grid on;


%for each user, choose the valid satellite with highest SNR:
snrDbMat = nan(size(snrLin_t));
snrDbMat(mask_t) = 10*log10(snrLin_t(mask_t));

numUsers = size(mask_t,1);
numSats  = size(mask_t,2);

bestSnrDbPerUser = nan(1,numUsers);
bestRateMbpsPerUser = nan(1,numUsers);
bestSatPerUser = nan(1,numUsers);

for u = 1:numUsers
    validSatIdx = find(mask_t(u,:));
    
    if ~isempty(validSatIdx)
        snrDb_u = 10*log10(snrLin_t(u,validSatIdx));
        rateMbps_u = rate_t(u,validSatIdx)/1e6;

        [bestSnrDbPerUser(u), idxBest] = max(snrDb_u);
        bestRateMbpsPerUser(u) = rateMbps_u(idxBest);
        bestSatPerUser(u) = validSatIdx(idxBest);
    end
end

%Best SNR and Rate
figure;
cdfplot(snrDb_valid); hold on;
xlabel('SNR [dB]');
ylabel('Empirical CDF');
title(sprintf('CDF of SNR at t = %.1f min', snapshotTime));
grid on;
end