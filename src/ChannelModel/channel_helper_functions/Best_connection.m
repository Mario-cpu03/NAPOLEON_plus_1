%The best satellite to be used for the initial access to the large constellation is assumed to be the one that satisfies the following simultaneously:
%Has the closest range to "Target Ground Station".
%Has an elevation angle of at least 30 degrees with respect to "Source Ground Station".
% Find the indices of the elements of elSourceToSatGreaterThanOrEqual25
% whose value is true.
trueID = find(elSourceToSatGreaterThanOrEqual25 == true);

% These indices are essentially the indices of satellites in sat whose
% elevation angle with respect to "Source Ground Station" is at least 25
% degrees. Determine the range of these satellites to "Target Ground
% Station".
[~,~,r] = aer(sat(trueID), gsTarget);

% Determine the index of the element in r bearing the minimum value.
[~,minRangeID] = min(r);

% Determine the element in trueID at the index minRangeID.
id = trueID(minRangeID);

% This is the index of the best satellite for initial access to the
% constellation. This will be the first hop in the path. Initialize a
% variable 'node' that stores the first two nodes of the routing - namely,
% "Source Ground Station" and the best satellite for initial constellation
% access.
nodes = {gsSource sat(id)};