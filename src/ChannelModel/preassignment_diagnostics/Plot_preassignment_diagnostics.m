%% Plot_preassignment_diagnostics function
% This function produces toolbox-consistent diagnostics inspired by the
% reference MATLAB script shared by the team member.
%
% In particular, it generates:
%   1) Average Best Available Link Quality Over Time
%   2) Link Availability Chart
%   3) Percentage of Users Above a Rate Threshold Over Time
%   4) Geographic contour map of Best Available Rate at a selected time
%   5) Geographic contour map of Best Available SNR at a selected time
%
% The geographic plots exploit toolbox-native visualization through:
%   siteviewer + propagationData + contour

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. simulationScenario : satelliteScenario object containing the
%       ground stations whose coordinates are used for the geographic plots
%
%       2. USER_SAT_evolution : data structure containing:
%                   (i)   timeVec
%                   (ii)  validLinkMask
%                   (iii) SNR_matrix
%                   (iv)  rateMatrix
%                   (v)   numUsers
%                   (vi)  numSats
%                   (vii) numTimeSteps
%
%       3. configPlot : optional data structure containing:
%                   (i) selectedTimeIdx
%                   (ii) rateThresholdMbps

function Plot_preassignment_diagnostics(simulationScenario, USER_SAT_evolution, configPlot)

%% Default parameters
if nargin < 3
    configPlot = struct();
end

if ~isfield(configPlot,'selectedTimeIdx')
    configPlot.selectedTimeIdx = USER_SAT_evolution.numTimeSteps;
end

if ~isfield(configPlot,'rateThresholdMbps')
    configPlot.rateThresholdMbps = 1;
end

%% Retrieval of the tensors
timeVec       = USER_SAT_evolution.timeVec;
validLinkMask = USER_SAT_evolution.validLinkMask;
SNR_matrix    = 10*log10(USER_SAT_evolution.SNRtensor);
rateMatrix    = USER_SAT_evolution.rateTensor;

U = USER_SAT_evolution.numUsers;
T = USER_SAT_evolution.numTimeSteps;

selectedTimeIdx = min(max(configPlot.selectedTimeIdx,1),T);
rateThreshold_bps = configPlot.rateThresholdMbps * 1e6;

%% Mask invalid links
rateMasked = rateMatrix;
rateMasked(~validLinkMask) = -inf;

snrMasked = SNR_matrix;
snrMasked(~validLinkMask) = -inf;

%% Best available link quality per user and time
bestRate_perUserTime = squeeze(max(rateMasked,[],2));   % [U x T]
bestSNR_perUserTime  = squeeze(max(snrMasked,[],2));    % [U x T]

%% Detect user-time instants with no valid link
userHasValidLink = squeeze(sum(validLinkMask,2)) > 0;   % [U x T]

bestRate_perUserTime(~userHasValidLink) = NaN;
bestSNR_perUserTime(~userHasValidLink)  = NaN;

%% Average best available link quality over users
avgBestRate_overTime = mean(bestRate_perUserTime, 1, 'omitnan');
avgBestSNR_overTime  = mean(bestSNR_perUserTime, 1, 'omitnan');

%% Percentage of users with at least one valid link
linkAvailabilityPercent = mean(userHasValidLink,1) * 100;

%% Percentage of users above a rate threshold
coverageAboveRateThreshold = mean(bestRate_perUserTime > rateThreshold_bps, 1, 'omitnan') * 100;

%% ============================================================
% Figure 1 - Average Best Available Link Quality Over Time
% ============================================================
figure('Name','Average Best Available Link Quality Over Time');

yyaxis left
plot(timeVec, avgBestRate_overTime/1e6, '-', 'LineWidth', 1.4);
ylabel('Average Best Available Rate [Mbps]');

yyaxis right
plot(timeVec, avgBestSNR_overTime, '-', 'LineWidth', 1.4);
ylabel('Average Best Available SNR [dB]');

grid on;
box on;
xlabel('Time');
title('Average Best Available Link Quality Over Time');

%% ============================================================
% Retrieval of user coordinates from the satelliteScenario object
% ============================================================
Gs = simulationScenario.GroundStations;

userLat = zeros(U,1);
userLon = zeros(U,1);

for currentUser = 1:U
    userLat(currentUser) = Gs(currentUser).Latitude;
    userLon(currentUser) = Gs(currentUser).Longitude;
end

%% Selected-time geographic quantities
bestRate_selectedTime = bestRate_perUserTime(:,selectedTimeIdx) / 1e6; % Mbps
bestSNR_selectedTime  = bestSNR_perUserTime(:,selectedTimeIdx);        % dB-like quantity

%% ============================================================
% Figure 4 - Toolbox-native geographic contour of Best Available Rate
% ============================================================
figure('Name','Best Available Rate Over Geography');
sv1 = siteviewer("Basemap","satellite");

pdRate = propagationData(userLat, userLon, "BestRateMbps", bestRate_selectedTime);
contour(pdRate, LegendTitle="Best Available Rate" + newline + "(Mbps)");

title(sprintf('Best Available Rate at Time Index %d', selectedTimeIdx));

%% ============================================================
% Figure 5 - Toolbox-native geographic contour of Best Available SNR
% ============================================================
%figure('Name','Best Available SNR Over Geography');
%sv2 = siteviewer("Basemap","satellite");

%pdSNR = propagationData(userLat, userLon, "BestSNR", bestSNR_selectedTime);
%contour(pdSNR, LegendTitle="Best Available SNR" + newline + "(dB)");

%title(sprintf('Best Available SNR at Time Index %d', selectedTimeIdx));

end