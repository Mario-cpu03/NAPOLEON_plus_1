function Plot_link_chart(USER_SAT_evolution, snapshotTime, visibilityData, sampleTime, groundEnv)

% Plot_link_chart
% Snapshot-level link analysis.
%
% Produces:
%   1) SNR vs slant range, colored by environment
%   2) Rate vs slant range, colored by environment
%   3) CDF of SNR
%   4) CDF of achievable rate

%% TIME INDEX

timeIdx = round(snapshotTime*60 / sampleTime) + 1;

if timeIdx < 1 || timeIdx > visibilityData.numTimeSteps
    error('Requested snapshotTime is outside the available visibilityData time window.');
end

%% EXTRACT SNAPSHOT TENSORS

mask_t      = USER_SAT_evolution.validLinkMask(:,:,timeIdx);
snrLin_t    = USER_SAT_evolution.SNRtensor(:,:,timeIdx);
rate_t      = USER_SAT_evolution.rateTensor(:,:,timeIdx);
dist_t      = USER_SAT_evolution.distanceTensor(:,:,timeIdx);

% Find valid user-satellite pairs
[userIdx_valid, ~] = find(mask_t);

% Extract only valid links
snrLin_valid = snrLin_t(mask_t);
rate_valid   = rate_t(mask_t);
dist_valid_m = dist_t(mask_t);

% Convert units
snrDb_valid    = 10*log10(snrLin_valid);
rateMbps_valid = rate_valid / 1e6;
distKm_valid   = dist_valid_m / 1e3;

% Environment of each valid link.
% The environment is associated with the user, so each link inherits the
% environment of its user.
env_valid = groundEnv(userIdx_valid);

% Unique environments
envList = unique(env_valid);

%% SNR VS SLANT RANGE, COLORED BY ENVIRONMENT

figure("Color",'w');
hold on;

for iEnv = 1:numel(envList)

    currentEnv = envList(iEnv);
    idxEnv = env_valid == currentEnv;

    scatter( ...
        distKm_valid(idxEnv), ...
        snrDb_valid(idxEnv), ...
        45, ...
        'filled', ...
        'DisplayName', char(currentEnv));

end

xlabel('Slant range [km]');
ylabel('SNR [dB]');
title(sprintf('SNR vs slant range at t = %.1f min', snapshotTime));

legend('Location','bestoutside');
grid on;
hold off;

%% RATE VS SLANT RANGE, COLORED BY ENVIRONMENT

figure("Color",'w');
hold on;

for iEnv = 1:numel(envList)

    currentEnv = envList(iEnv);
    idxEnv = env_valid == currentEnv;

    scatter( ...
        distKm_valid(idxEnv), ...
        rateMbps_valid(idxEnv), ...
        45, ...
        'filled', ...
        'DisplayName', char(currentEnv));

end

xlabel('Slant range [km]');
ylabel('Achievable rate [Mbit/s]');
title(sprintf('Achievable rate vs slant range at t = %.1f min', snapshotTime));

legend('Location','bestoutside');
grid on;
hold off;

%% BEST SNR AND RATE PER USER

numUsers = size(mask_t,1);

bestSnrDbPerUser    = nan(1,numUsers);
bestRateMbpsPerUser = nan(1,numUsers);
bestSatPerUser      = nan(1,numUsers);

for u = 1:numUsers

    validSatIdx = find(mask_t(u,:));

    if ~isempty(validSatIdx)

        snrDb_u    = 10*log10(snrLin_t(u,validSatIdx));
        rateMbps_u = rate_t(u,validSatIdx) / 1e6;

        [bestSnrDbPerUser(u), idxBest] = max(snrDb_u);

        bestRateMbpsPerUser(u) = rateMbps_u(idxBest);
        bestSatPerUser(u)      = validSatIdx(idxBest);

    end
end

%% CDF OF SNR

figure("Color",'w');
cdfplot(snrDb_valid);

xlabel('SNR [dB]');
ylabel('Empirical CDF');
title(sprintf('CDF of SNR at t = %.1f min', snapshotTime));
grid on;

%% CDF OF ACHIEVABLE RATE

figure("Color",'w');
cdfplot(rateMbps_valid);

xlabel('Achievable rate [Mbit/s]');
ylabel('Empirical CDF');
title(sprintf('CDF of achievable rate at t = %.1f min', snapshotTime));
grid on;

end