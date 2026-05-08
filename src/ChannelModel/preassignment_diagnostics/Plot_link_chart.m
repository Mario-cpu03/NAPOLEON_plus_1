%% Plot_link_availability_chart function
% This function plots the link availability chart in the same style as the
% reference figure shared in the discussion.
% A user is marked as available at time t if at least one valid link exists.

function Plot_link_chart(USER_SAT_evolution)

timeVec       = USER_SAT_evolution.timeVec;
validLinkMask = USER_SAT_evolution.validLinkMask;
numUsers      = USER_SAT_evolution.numUsers;

% User-time availability: at least one valid satellite link
userHasValidLink = squeeze(sum(validLinkMask,2)) > 0;   % [U x T]

figure('Name','Link Availability Chart');

availabilityChart = double(userHasValidLink);
availabilityChart(availabilityChart == 0) = nan;

userIndex = (1:numUsers)';
plot(timeVec, availabilityChart .* userIndex, 'LineWidth', 1);

xlim([timeVec(1) timeVec(end)]);
ylim([0 numUsers+1]);
xlabel('Time');
ylabel('UE Index');
title('Link Availability Chart');
grid on;
box on;

end