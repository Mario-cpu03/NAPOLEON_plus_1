function [fig, ax] = plotNAPOLEONKPI(RESULTS, SCENARIO, plotName, varargin)
%PLOTNAPOLEONKPI Standalone plotting function for NAPOLEON+ KPIs.
%
% This function is GUI-independent.
% By default, it creates a normal MATLAB figure.
%
% Usage:
%   plotNAPOLEONKPI(RESULTS, SCENARIO, "throughputEvolution")
%   plotNAPOLEONKPI(RESULTS, SCENARIO, "userRateEvolution", "UserIndex", 12)
%
% Optional GUI/AppDesigner usage:
%   plotNAPOLEONKPI(RESULTS, SCENARIO, "throughputEvolution", "Axes", app.UIAxes)
%
% Supported plotName values:
%   "scenarioDistribution"
%   "totalHandoversEvolution"
%   "handoverFrequencyPerUser"
%   "handoverFrequencyCDF"
%   "throughputEvolution"
%   "SNREvolution"
%   "rateFairnessCDF"
%   "servedUsersFractionEvolution"
%   "userRateEvolution"
%   "userServiceStateEvolution"
%   "eMBB_TCR"
%   "eMBB_spectralEfficiency"
%   "URLLC_TCR"
%   "URLLC_latency90"

%% Input parsing

p = inputParser;
p.addParameter("UserIndex", [], @(x) isempty(x) || (isscalar(x) && isnumeric(x)));
p.addParameter("Axes", [], @(x) isempty(x) || isgraphics(x, "axes"));
p.addParameter("LineWidth", 1.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.parse(varargin{:});

userIndex = p.Results.UserIndex;
axInput = p.Results.Axes;
lineWidth = p.Results.LineWidth;

plotName = string(plotName);

%% Basic checks

if ~isfield(RESULTS, "KPI_results")
    error("plotNAPOLEONKPI:MissingKPIResults", ...
        "RESULTS.KPI_results is missing.");
end

if ~isfield(RESULTS.KPI_results, "generalKPIs")
    error("plotNAPOLEONKPI:MissingGeneralKPIs", ...
        "RESULTS.KPI_results.generalKPIs is missing.");
end

K = RESULTS.KPI_results;
G = K.generalKPIs;

%% Create or reuse axis

if isempty(axInput)
    fig = figure("Name", char(plotName), "Color", "w");
    ax = axes(fig);
else
    ax = axInput;
    fig = ancestor(ax, "figure");
end

cla(ax);
hold(ax, "on");
grid(ax, "on");

%% Plot selection

switch plotName

    case "scenarioDistribution"
    
        plotUserScenarioDistribution(SCENARIO.satelliteScenario ,SCENARIO.configAoI,"Axes", ax);

    case "totalHandoversEvolution"

        userHandoverTime = G.serviceContinuity.userHandoverTime;

        y = sum(userHandoverTime, 1);
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        xlabel(ax, "Time [s]");
        ylabel(ax, "Number of handovers");
        title(ax, "Total Handovers Evolution");

    case "handoverFrequencyPerUser"

        userHandoverTime = G.serviceContinuity.userHandoverTime;

        % Number of observed handover events for each user.
        N_HO_perUser = sum(userHandoverTime, 2);

        % Observation time in seconds.
        nT = size(userHandoverTime, 2);
        t_s = getTimeSeconds(RESULTS, nT);
        T_obs_s = t_s(end) - t_s(1);

        if T_obs_s <= 0
            error("plotNAPOLEONKPI:InvalidObservationTime", ...
                "Observation time must be positive.");
        end

        % Estimated handover frequency per user [HO/s].
        estimatedHOFrequency_s = N_HO_perUser / T_obs_s;

        x = 1:numel(estimatedHOFrequency_s);
        y = estimatedHOFrequency_s;

        bar(ax, x, y);

        xlabel(ax, "User index");
        ylabel(ax, "Estimated handover frequency [HO/s]");
        title(ax, "Estimated Handover Frequency per User");

    case "handoverFrequencyCDF"

        userHandoverTime = G.serviceContinuity.userHandoverTime;

        % Number of observed handover events for each user.
        N_HO_perUser = sum(userHandoverTime, 2);

        % Observation time in seconds.
        nT = size(userHandoverTime, 2);
        t_s = getTimeSeconds(RESULTS, nT);
        T_obs_s = t_s(end) - t_s(1);

        if T_obs_s <= 0
            error("plotNAPOLEONKPI:InvalidObservationTime", ...
                "Observation time must be positive.");
        end

        % Estimated handover frequency per user [HO/s].
        lambda_HO_s = N_HO_perUser / T_obs_s;

        % Empirical CDF across users.
        lambda_sorted = sort(lambda_HO_s(:));
        F = (1:numel(lambda_sorted)).' / numel(lambda_sorted);

        plot(ax, lambda_sorted, F, "LineWidth", lineWidth);

        xlabel(ax, "Estimated handover frequency [HO/s]");
        ylabel(ax, "Empirical CDF");
        title(ax, "CDF of Estimated Handover Frequency");

    case "throughputEvolution"

        userRateTime_Mbps = G.serviceContinuity.userRateTime_Mbps;
        userRateTime_Mbps(~isfinite(userRateTime_Mbps)) = 0;

        % Sum bitrate over all users at each time step.
        y = sum(userRateTime_Mbps, 1)/RESULTS.USER_SAT_association.numUsers;
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        xlabel(ax, "Time [s]");
        ylabel(ax, "Sum bitrate [Mbit/s]");
        title(ax, "Throughput Evolution");

    case "SNREvolution"

        y = G.SNR.avgUserSNRTime_dB;
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        xlabel(ax, "Time [s]");
        ylabel(ax, "Average selected-link SNR [dB]");
        title(ax, "SNR Evolution");

    case "rateFairnessCDF"

        x = G.fairness.rateCDF_x_Mbps;
        y = G.fairness.rateCDF_y;

        plot(ax, x, y, "LineWidth", lineWidth);

        xlabel(ax, "Per-user average rate [Mbit/s]");
        ylabel(ax, "Empirical CDF");
        title(ax, "Rate Fairness CDF");

    case "servedUsersFractionEvolution"

        y = 100 * G.serviceContinuity.servedRatioTime;
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        ylim(ax, [0 100]);
        xlabel(ax, "Time [s]");
        ylabel(ax, "Served users [%]");
        title(ax, "Served Users Fraction Evolution");

    case "userRateEvolution"

        userIndex = validateUserIndex(userIndex, G.serviceContinuity.userRateTime_Mbps);

        y = G.serviceContinuity.userRateTime_Mbps(userIndex, :);
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        xlabel(ax, "Time [s]");
        ylabel(ax, "Rate [Mbit/s]");
        title(ax, "User " + string(userIndex) + " Rate Evolution");

    case "userServiceStateEvolution"

        userIndex = validateUserIndex(userIndex, G.serviceContinuity.userServedTime);

        served = G.serviceContinuity.userServedTime(userIndex, :);
        handover = G.serviceContinuity.userHandoverTime(userIndex, :);

        x = getTimeSeconds(RESULTS, numel(served));

        % Cumulative handover count for the selected user.
        cumulativeHO = cumsum(double(handover));

        % Plot cumulative handover count.
        stairs(ax, x, cumulativeHO, "LineWidth", lineWidth);

        % Shade unserved intervals, if any.
        unserved = ~served;

        if any(unserved)
            yl = ylim(ax);

            % Find contiguous unserved intervals.
            d = diff([false, unserved, false]);
            startIdx = find(d == 1);
            endIdx   = find(d == -1) - 1;

            for k = 1:numel(startIdx)
                x1 = x(startIdx(k));
                x2 = x(endIdx(k));

                patch(ax, ...
                    [x1 x2 x2 x1], ...
                    [yl(1) yl(1) yl(2) yl(2)], ...
                    [0.85 0.85 0.85], ...
                    "EdgeColor", "none", ...
                    "FaceAlpha", 0.35, ...
                    "HandleVisibility", "off");
            end

            % Put the cumulative handover curve back on top.
            stairs(ax, x, cumulativeHO, "LineWidth", lineWidth);
        end

        xlabel(ax, "Time [s]");
        ylabel(ax, "Cumulative handovers");
        title(ax, "User " + string(userIndex) + " Handover Timeline");

        % Optional compact text.
        totalHO = cumulativeHO(end);
        servedRatio = mean(served);

        subtitle(ax, ...
            "Total HO = " + string(totalHO) + ...
            ", served ratio = " + string(round(100*servedRatio, 2)) + "%");
    case "eMBB_TCR"

        if ~isfield(K, "specificeMBB")
            error("plotNAPOLEONKPI:MissingeMBB", ...
                "specificeMBB is missing. This plot requires an eMBB run.");
        end

        y = 100 * K.specificeMBB.TCR_eMBB;
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        ylim(ax, [0 100]);
        xlabel(ax, "Time [s]");
        ylabel(ax, "Compliant users [%]");
        title(ax, "eMBB Temporal Compliance Ratio");

    case "eMBB_spectralEfficiency"

        if ~isfield(K, "specificeMBB")
            error("plotNAPOLEONKPI:MissingeMBB", ...
                "specificeMBB is missing. This plot requires an eMBB run.");
        end

        y = K.specificeMBB.aggregateSpecEff;
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        xlabel(ax, "Time [s]");
        ylabel(ax, "Spectral efficiency [bit/s/Hz]");
        title(ax, "eMBB Spectral Efficiency Evolution");

    case "URLLC_TCR"

        if ~isfield(K, "specificURLLC")
            error("plotNAPOLEONKPI:MissingURLLC", ...
                "specificURLLC is missing. This plot requires a URLLC run.");
        end

        y = 100 * K.specificURLLC.TCR_URLLC;
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        ylim(ax, [0 100]);
        xlabel(ax, "Time [s]");
        ylabel(ax, "Compliant users [%]");
        title(ax, "URLLC Temporal Compliance Ratio");

    case "URLLC_latency90"

        if ~isfield(K, "specificURLLC")
            error("plotNAPOLEONKPI:MissingURLLC", ...
                "specificURLLC is missing. This plot requires a URLLC run.");
        end

        % PL_URLLC_temporal is already in seconds.
        y = K.specificURLLC.PL_URLLC_temporal;
        x = getTimeSeconds(RESULTS, numel(y));

        plot(ax, x, y, "LineWidth", lineWidth);

        if isfield(RESULTS, "configKPI") && ...
                isfield(RESULTS.configKPI, "URLLC") && ...
                isfield(RESULTS.configKPI.URLLC, "latency_max_URLLC")

            threshold_s = RESULTS.configKPI.URLLC.latency_max_URLLC;
            yline(ax, threshold_s, "--", "URLLC threshold");
        end

        xlabel(ax, "Time [s]");
        ylabel(ax, "90th percentile latency [s]");
        title(ax, "URLLC 90th Percentile Latency Evolution");

    otherwise

        error("plotNAPOLEONKPI:UnknownPlot", ...
            "Unknown plotName: %s", plotName);
end

hold(ax, "off");

end

%% ========================================================================
% Local helper functions
% ========================================================================

function t_s = getTimeSeconds(RESULTS, nT)

% Preferred source: association time vector.
if isfield(RESULTS, "USER_SAT_association") && ...
        isfield(RESULTS.USER_SAT_association, "timeVec")

    timeVec = RESULTS.USER_SAT_association.timeVec;

    if numel(timeVec) == nT

        if isdatetime(timeVec)
            t_s = seconds(timeVec - timeVec(1));
            t_s = t_s(:).';
            return;

        elseif isduration(timeVec)
            t_s = seconds(timeVec - timeVec(1));
            t_s = t_s(:).';
            return;

        elseif isnumeric(timeVec)
            timeVec = double(timeVec(:).');
            t_s = timeVec - timeVec(1);
            return;
        end
    end
end

% Fallback: use sample time if available.
sampleTime_s = 1;

if isfield(RESULTS, "params") && isfield(RESULTS.params, "sampleTime_s")
    sampleTime_s = RESULTS.params.sampleTime_s;
elseif isfield(RESULTS, "params") && isfield(RESULTS.params, "sampleTime")
    sampleTime_s = RESULTS.params.sampleTime;
elseif isfield(RESULTS, "params") && isfield(RESULTS.params, "sampleTimeSeconds")
    sampleTime_s = RESULTS.params.sampleTimeSeconds;
end

t_s = (0:(nT - 1)) * sampleTime_s;

end

function userIndex = validateUserIndex(userIndex, userMatrix)

if isempty(userIndex)
    error("plotNAPOLEONKPI:MissingUserIndex", ...
        "UserIndex is required for this plot.");
end

userIndex = double(userIndex);
numUsers = size(userMatrix, 1);

if userIndex < 1 || userIndex > numUsers || userIndex ~= round(userIndex)
    error("plotNAPOLEONKPI:InvalidUserIndex", ...
        "UserIndex must be an integer between 1 and %d.", numUsers);
end

end