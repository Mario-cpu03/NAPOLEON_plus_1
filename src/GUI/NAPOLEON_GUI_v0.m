%NAPOLEON_GUI_V1 Professional GUI for NAPOLEON+.
%
% Visual concept:
%   - dark vertical command rail, like professional operations software
%   - light aerospace workspace, inspired by STK / network operation consoles
%   - no repeated information blocks
%   - configuration remains table-like and compact
%   - same computational logic as the previous GUI versions
%
% Workflow:
%   1) edit mission inputs
%   2) launch scenario, viewer, association and export from the header
%   3) monitor elapsed runtime from the live header bar
%   4) inspect KPI summary, service compliance, and violations

function NAPOLEON_GUI_v0()

    close all;

    guiDir = fileparts(mfilename('fullpath'));
    srcDir = fileparts(guiDir);

    addpath(srcDir);
    addpath(genpath(fullfile(srcDir, 'ChannelModel')));
    addpath(genpath(fullfile(srcDir, 'UserSatAssoc')));
    addpath(genpath(fullfile(srcDir, 'KPIs')));
    addpath(fullfile(srcDir, 'GUI'));

    State = struct();
    State.defaultParams = default_NAPOLEON_params();
    State.params = [];
    State.SCENARIO = [];
    State.scenarioPlotData = [];
    State.RESULTS = [];
    State.viewer = [];
    State.scenarioGenerated = false;
    State.associationCompleted = false;
    State.lastRunStarted = [];
    State.lastRunFinished = [];
    State.runTimer = [];
    State.runPhase = "";
    State.kpiTabGroup = [];
    State.kpiTabs = struct();

    C = atlasTheme();
    fontName = preferredFont();

    fig = uifigure( ...
        'Name', 'NAPOLEON+ Atlas Console v1', ...
        'Color', C.bg);

    fig.CloseRequestFcn = @onClose;
    fig.WindowState = 'maximized';

    root = uigridlayout(fig, [1 2]);
    root.ColumnWidth = {350, '1x'};
    root.RowHeight = {'1x'};
    root.Padding = [0 0 0 0];
    root.ColumnSpacing = 0;
    root.BackgroundColor = C.bg;

    rail = uipanel(root, ...
        'BackgroundColor', C.rail, ...
        'BorderType', 'none');
    rail.Layout.Column = 1;
    rail.Scrollable = 'on';

    railGrid = uigridlayout(rail, [5 1]);
    railGrid.RowHeight = {120, 18, 320, 18, 340};
    railGrid.Padding = [18 22 18 18];
    railGrid.RowSpacing = 5;
    railGrid.BackgroundColor = C.rail;

    brand = uigridlayout(railGrid, [3 1]);
    brand.RowHeight = {46, 22, 20};
    brand.Padding = [0 8 0 0];
    brand.RowSpacing = 5;
    brand.BackgroundColor = C.rail;

    uilabel(brand, ...
        'Text', 'NAPOLEON+', ...
        'FontName', fontName, ...
        'FontSize', 36, ...
        'FontWeight', 'bold', ...
        'FontColor', C.railText, ...
        'BackgroundColor', C.rail);

    uilabel(brand, ...
        'Text', 'ATLAS CONSOLE', ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'FontColor', C.accentRail, ...
        'BackgroundColor', C.rail);

    uilabel(brand, ...
        'Text', 'LEO association workflow', ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontColor', C.railMuted, ...
        'BackgroundColor', C.rail);

    railDivider(railGrid, C, fontName, 'CONFIGURATION TABLE');

    setupTable = uitable(railGrid, ...
    'Data', referenceSetupData([]), ...
    'ColumnName', {'Group', 'Parameter', 'Value', 'Unit'}, ...
    'RowName', [], ...
    'ColumnWidth', {60, '1x', 70, 40}, ...
    'FontName', fontName, ...
    'FontSize', 10, ...
    'BackgroundColor', [C.railStatusBg; C.railButton], ...
    'ForegroundColor', C.railText, ...
    'ColumnSortable', [false false false false]);

    try
        styleGroup = uistyle('FontWeight', 'bold');
        addStyle(setupTable, styleGroup, 'column', 1);

        styleCenter = uistyle('HorizontalAlignment', 'center');
        addStyle(setupTable, styleCenter, 'column', [3 4]);
    catch
    end

    railDivider(railGrid, C, fontName, 'PARAMETER SETUP');

    controlsGrid = uigridlayout(railGrid, [6 1]);
    controlsGrid.Padding = [0 0 0 0];
    controlsGrid.RowSpacing = 8;
    controlsGrid.ColumnWidth = {'1x'};
    controlsGrid.RowHeight = {36, 36, 36, 36, 36, 36, 36};
    controlsGrid.BackgroundColor = C.rail;

    numUsersField = railInputRowText(controlsGrid, 'Terminals', '', C, fontName);
    csiDrop       = railInputRowDrop(controlsGrid, 'CSI mode', {'--', 'forecast', 'ideal'}, '--', C, fontName);
    seedField     = railInputRowText(controlsGrid, 'Seed', '', C, fontName);
    algDrop       = railInputRowDrop(controlsGrid, 'Policy', {'--', 'URLLC', 'eMBB'}, '--', C, fontName);

    tuneBtn = flatButton(controlsGrid, '⚙️ Tune Policy', C.railButton, C.accentRail, fontName);

    bottomButtonsGrid = uigridlayout(controlsGrid, [1 2]);
    bottomButtonsGrid.Padding = [0 0 0 0];
    bottomButtonsGrid.ColumnSpacing = 8;
    bottomButtonsGrid.ColumnWidth = {'1x', '1x'};
    bottomButtonsGrid.BackgroundColor = C.rail;

    defaultBtn = flatButton(bottomButtonsGrid, 'Default values', C.accentRail, C.rail, fontName);
    resetWorkspaceBtn = flatButton(bottomButtonsGrid, 'Reset workspace', C.railButton, C.railText, fontName);

    workspace = uigridlayout(root, [2 1]);
    workspace.Layout.Column = 2;
    workspace.RowHeight = {82, '1x'};
    workspace.Padding = [20 18 20 18];
    workspace.RowSpacing = 14;
    workspace.BackgroundColor = C.bg;

    ribbon = uipanel(workspace, ...
        'BackgroundColor', C.card, ...
        'BorderType', 'none');
    ribbon.Layout.Row = 1;

    ribGrid = uigridlayout(ribbon, [1 5]);
    ribGrid.ColumnWidth = {'1x', 110,110,110 420};
    ribGrid.Padding = [22 14 22 14];
    ribGrid.ColumnSpacing = 10;
    ribGrid.BackgroundColor = C.card;

        titleBox = uigridlayout(ribGrid, [1 2]);
    titleBox.RowHeight = {'1x'};
    titleBox.ColumnWidth = {'fit', 40};
    titleBox.Padding = [0 0 0 0];
    titleBox.RowSpacing = 0;
    titleBox.BackgroundColor = C.card;

    uilabel(titleBox, ...
        'Text', 'Operations workspace', ...
        'FontName', fontName, ...
        'FontSize', 22, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.card);

    helpBtn = uibutton(titleBox, ...
        'Text', '?', ...
        'FontName', fontName, ...
        'FontSize', 18, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', C.bg, ...
        'FontColor', C.text, ...
        'Tooltip', sprintf('Workflow Guide:\n1. Configure parameters on the left rail\n2. Click GENERATE SCENARIO in the top header\n3. Click RUN ASSOCIATION to simulate the system\n4. Click EXPORT to save data and graphs'));

    scenarioBadge = ribbonBadge(ribGrid, 'Scenario', 'SETUP', C.neutralSoft, C.muted, C, fontName);
    assocBadge    = ribbonBadge(ribGrid, 'Association', 'LOCKED', C.neutralSoft, C.disabled, C, fontName);
    exportBadge   = ribbonBadge(ribGrid, 'Export Datas', 'LOCKED', C.neutralSoft, C.disabled, C, fontName);
    runMeter      = runtimeBar(ribGrid, C, fontName);

    middle = uigridlayout(workspace, [2 2]);
    middle.Layout.Row = 2;
    middle.ColumnWidth = {'1x', 365};
    middle.RowHeight = {'1x', 112};
    middle.ColumnSpacing = 14;
    middle.Padding = [0 0 0 0];
    middle.BackgroundColor = C.bg;

    canvasPanel = atlasCard(middle, C);
    canvasPanel.Layout.Row = 1;
    canvasPanel.Layout.Column = 1;

    canv = uigridlayout(canvasPanel, [3 1]);
    canv.RowHeight = {58, '1x', 42};
    canv.Padding = [18 18 18 18];
    canv.RowSpacing = 12;
    canv.BackgroundColor = C.card;

    canvasTitleBox = uigridlayout(canv, [2 1]);
    canvasTitleBox.RowHeight = {28, 22};
    canvasTitleBox.Padding = [0 0 0 0];
    canvasTitleBox.RowSpacing = 0;
    canvasTitleBox.BackgroundColor = C.card;

    canvasTitleLabel = uilabel(canvasTitleBox, ...
        'Text', 'KPI Analytics Dashboard', ...
        'FontName', fontName, ...
        'FontSize', 22, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.card);

    canvasSubtitle = uilabel(canvasTitleBox, ...
        'Text', '', ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.card);

    ax = uiaxes(canv);
    ax.Color = C.canvas;
    ax.XColor = C.axis;
    ax.YColor = C.axis;
    ax.GridColor = C.grid;
    ax.Box = 'off';
    ax.Toolbar.Visible = 'off';
    ax.FontName = fontName;
    ax.FontSize = 9;
    clearAtlasMap(ax, C);

    canvasFooter = uilabel(canv, ...
        'Text', '', ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.cardAlt, ...
        'HorizontalAlignment', 'center');

analyticsPanel = uipanel(middle, 'BackgroundColor', C.bg, 'BorderType', 'none');
analyticsPanel.Layout.Row = [1 2];
analyticsPanel.Layout.Column = 2;
analyticsPanel.Scrollable = 'on';

ana = uigridlayout(analyticsPanel, [3 1]);
ana.RowHeight = {35, 550, '1x'};
ana.Padding = [18 18 18 18];
ana.RowSpacing = 6;
ana.BackgroundColor = C.bg;

hdr1 = uigridlayout(ana, [1 2]);
hdr1.RowHeight = {'1x'};
hdr1.ColumnWidth = {'1x', 30};
hdr1.Padding = [0 0 0 0];
hdr1.BackgroundColor = C.bg;
uilabel(hdr1, ...
    'Text', 'KPI CONTROLS', ...
    'FontName', fontName, ...
    'FontSize', 22, ...
    'FontWeight', 'bold', ...
    'FontColor', C.text, ...
    'BackgroundColor', C.bg);
infoBtn1 = uibutton(hdr1, ...
    'Text', '?', ...
    'Tooltip', 'Click on any button below to generate and visualize the corresponding KPI plot.', ...
    'FontName', fontName, ...
    'FontSize', 16, ...
    'FontWeight', 'bold', ...
    'FontColor', C.accent, ...
    'BackgroundColor', C.bg);

kpiGrid = uigridlayout(ana, [9, 2]);
kpiGrid.Layout.Row = 2;
kpiGrid.Layout.Column = 1;
kpiGrid.RowSpacing = 8;
kpiGrid.ColumnSpacing = 8;
kpiGrid.BackgroundColor = C.bg;
kpiGrid.RowHeight = {38, 38, 38, 38, 38,40, 35, 'fit', '1x'};
kpiGrid.ColumnWidth = {'1x', '1x'};

btnLabels = {'User Dist.', 'View Const.', 'SNR Evol', 'Rate CDF', 'Throughput', 'Handovers', 'Served Users', 'HO Freq CDF', 'Dyn1', 'Dyn2'};
plotIDs = {"UserDistribution", "ViewConstellation", "SNREvolution", "rateFairnessCDF", "throughputEvolution", "totalHandoversEvolution", "servedUsersFractionEvolution", "handoverFrequencyCDF", "", ""};
kpiBtns = gobjects(1, 10);
for j = 1:10
    kpiBtns(j) = uibutton(kpiGrid, ...
        'Text', btnLabels{j}, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', C.neutralSoft, ...
        'FontColor', C.disabled, ...
        'Enable', 'off');
    kpiBtns(j).Layout.Row = ceil(j/2);
    kpiBtns(j).Layout.Column = mod(j-1, 2) + 1;

    if j == 2
        kpiBtns(j).ButtonPushedFcn = @launchViewer;
    elseif j <= 8
        kpiBtns(j).ButtonPushedFcn = @(src, event) handleKPIClick(btnLabels{j}, plotIDs{j});
    end
end

inspectorBtn = flatButton(kpiGrid, '🔍 User Inspector', C.neutralSoft, [0,0,0], fontName);
inspectorBtn.Layout.Row = 6;
inspectorBtn.Layout.Column = [1 2];
inspectorBtn.FontSize = 13;
inspectorBtn.ButtonPushedFcn = @openUserInspector;



hdr2 = uigridlayout(kpiGrid, [1 2]);
hdr2.Layout.Row = 7;
hdr2.Layout.Column = [1 2];
hdr2.RowHeight = {'1x'};
hdr2.ColumnWidth = {'1x', 30};
hdr2.Padding = [0 0 0 0];
hdr2.BackgroundColor = C.bg;
lblSummary = uilabel(hdr2, ...
    'Text', 'KPI SUMMARY', ...
    'FontName', fontName, ...
    'FontSize', 22, ...
    'FontWeight', 'bold', ...
    'FontColor', C.text, ...
    'BackgroundColor', C.bg);
infoBtn2 = uibutton(hdr2, ...
    'Text', '?', ...
    'Tooltip', 'This table summarizes the main general KPIs computed over the entire simulation.', ...
    'FontName', fontName, ...
    'FontSize', 16, ...
    'FontWeight', 'bold', ...
    'FontColor', C.accent, ...
    'BackgroundColor', C.bg);

kpiTable = uitable(kpiGrid, ...
    'Data', kpiTableData([], []), ...
    'ColumnName', [], ...
    'RowName', [], ...
    'ColumnWidth', {'5x', '2x', '2x'}, ...
    'FontName', fontName, ...
    'FontSize', 12, ...
    'ColumnSortable', [false false false]);
kpiTable.Layout.Row = 8;
kpiTable.Layout.Column = [1 2];

kpiTable.BackgroundColor = [1 1 1; 0.94 0.95 0.96];
kpiTable.ForegroundColor = [0.15 0.15 0.15];

kpiTable.BackgroundColor = [1 1 1];
kpiTable.ForegroundColor = [0.15 0.15 0.15];

try
    tryStyleTable(kpiTable, C);

    styleMetric = uistyle('FontWeight', 'bold');
    addStyle(kpiTable, styleMetric, 'column', 1);

    styleValues = uistyle('HorizontalAlignment', 'center');
    addStyle(kpiTable, styleValues, 'column', [2 3]);

    styleHeader = uistyle('FontWeight', 'bold', 'BackgroundColor', C.cardAlt);
    addStyle(kpiTable, styleHeader, 'row', 1);
catch
end
    consolePanel = atlasCard(middle, C);
    consolePanel.Layout.Row = 2;
    consolePanel.Layout.Column = 1;

    con = uigridlayout(consolePanel, [1 4]);
    con.ColumnWidth = {120, '1x', 110, 110};
    con.Padding = [18 14 18 14];
    con.ColumnSpacing = 12;
    con.BackgroundColor = C.card;

    uilabel(con, ...
        'Text', 'Console', ...
        'FontName', fontName, ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'FontColor', C.accent, ...
        'BackgroundColor', C.blueSoft, ...
        'HorizontalAlignment', 'center');

    logBox = uitextarea(con, ...
        'Editable', 'off', ...
        'Enable', 'off', ...
        'BackgroundColor', C.cardAlt, ...
        'FontColor', C.text, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'Value', {'READY'});

    clearLogBtn = flatButton(con, 'Clear log', C.cardAlt, C.text, fontName);
    copyLogBtn  = flatButton(con, 'Copy log', C.cardAlt, C.text, fontName);

    scenarioBadge.Button.ButtonPushedFcn = @onGenerate;
    assocBadge.Button.ButtonPushedFcn = @onAssociate;
    exportBadge.Button.ButtonPushedFcn = @onExport;
    tuneBtn.ButtonPushedFcn = @onTune;
    defaultBtn.ButtonPushedFcn = @onDefaultValues;
    resetWorkspaceBtn.ButtonPushedFcn = @onResetWorkspace;

    clearLogBtn.ButtonPushedFcn = @(~,~) clearLog();
    copyLogBtn.ButtonPushedFcn = @(~,~) copyLog();

    numUsersField.ValueChangedFcn = @onInputChanged;
    csiDrop.ValueChangedFcn = @onInputChanged;
    algDrop.ValueChangedFcn = @onPolicyChanged;
    seedField.ValueChangedFcn = @onInputChanged;

    setInputFieldsEmpty();
    clearSimulationWorkspace(false);
    refreshUI('initial');

    function onInputChanged(varargin)

        if isfield(State, 'scenarioGenerated') && State.scenarioGenerated
            selection=uiconfirm(fig, ...
                ['Attention: the modification of the parameter will generate a new scenario. The datas of the current scenario will be discarded. ' ...
                'A new simulation will be performed. Continue?'], ...
                'Invalida Scenario', ...
                'Options', {'Continue', 'Retry'},...
                'DefaultOption', 'Retry',...
                'CancelOption', 'Retry',...
                'Icon', 'warning');


            if strcmp(selection, 'Retry')
                if ~isempty(State.params)
                    setInputFieldsFromParams(State.params);
                end
                appendLog('MODIFICA PARAMETRI ANNULLATA. SCENARIO PRESERVATO.');
                return;
            end
        end

        State.params = readGUI(false);
        clearSimulationWorkspace(false);

        appendLog('PARAMETERS UPDATED; CURRENT RUN INVALIDATED');
        refreshUI('stale');
    end

    function onValidate(~, ~)
        try
            params = readGUI();
            validate_NAPOLEON_params(params);
            State.params = params;
            appendLog('PARAMETERS VALID');
            uialert(fig, 'The current mission configuration is valid.', 'Validation passed');
        catch ME
            handleError(ME, false);
            uialert(fig, ME.message, 'Validation failed');
        end
    end


    function onPolicyChanged(~, ~)
        newParams = readGUI(false);

        if State.associationCompleted
            selection = uiconfirm(fig, ...
                ['Changing the association policy will discard the current ' ...
                 'association results. The scenario will be preserved and ' ...
                 'you can re-run the association with the new policy. Continue?'], ...
                'Change Policy', ...
                'Options',       {'Change policy', 'Keep current'}, ...
                'DefaultOption', 'Keep current', ...
                'CancelOption',  'Keep current', ...
                'Icon',          'warning');

            if strcmp(selection, 'Keep current')
                if ~isempty(State.params) && isfield(State.params, 'associationAlgorithm')
                    algDrop.Value = char(string(State.params.associationAlgorithm));
                end
                appendLog('POLICY CHANGE CANCELLED — RESULTS PRESERVED.');
                return
            end
        end

        State.params = newParams;
        State.RESULTS = [];
        State.associationCompleted = false;
        appendLog('POLICY UPDATED — SCENARIO PRESERVED, RESULTS RESET. Re-run association.');
        refreshUI('scenarioReady');
    end


    function onGenerate(~, ~)
        try
            params = readGUI();

            if params.numUsers > 600
                choice = uiconfirm(fig, ...
                    'Large scenario. Continue?', ...
                    'Scenario warning', ...
                    'Options', {'Continue', 'Cancel'}, ...
                    'DefaultOption', 'Cancel', ...
                    'CancelOption', 'Cancel');

                if strcmp(choice, 'Cancel')
                    appendLog('GENERATION CANCELLED');
                    return;
                end
            end

            validate_NAPOLEON_params(params);

            State.lastRunStarted = datetime('now');
            State.lastRunFinished = [];
            setBusy(true, 'GENERATING');
            appendLog('CHANNEL MODEL STARTED');

            SCENARIO = run_NAPOLEON_scenario(params);

            State.params = params;
            State.SCENARIO = SCENARIO;
            State.scenarioPlotData = buildScenarioPlotData(SCENARIO);
            State.RESULTS = [];
            State.viewer = [];
            State.scenarioGenerated = true;
            State.associationCompleted = false;
            State.lastRunFinished = datetime('now');

            appendLog('SCENARIO READY');
            refreshUI('scenarioReady');


        catch ME
            handleError(ME, true);
        end

        setBusy(false, 'READY');
    end

    function onViewer(~, ~)
        if ~State.scenarioGenerated
            uialert(fig, 'Generate a scenario first.', 'Viewer unavailable');
            return;
        end

        openSatelliteViewer();
        refreshUI('viewer');
    end

    function onAssociate(~, ~)
        try
            if ~State.scenarioGenerated
                uialert(fig, 'Generate a scenario first.', 'Missing scenario');
                return;
            end

            State.lastRunStarted = datetime('now');
            State.lastRunFinished = [];
            setBusy(true, 'ASSOCIATING');
            appendLog('ASSOCIATION STARTED');

            RESULTS = run_NAPOLEON_simulation(State.SCENARIO, State.params);

            State.RESULTS = RESULTS;
            State.associationCompleted = true;
            State.lastRunFinished = datetime('now');

            appendLog('ASSOCIATION DONE');
            refreshUI('resultsReady');

        catch ME
            handleError(ME, true);
        end

        setBusy(false, 'READY');
    end

    function onExport(~, ~)
        try
            if ~State.associationCompleted || isempty(State.RESULTS)
                uialert(fig, 'Nothing to export.', 'Export unavailable');
                return;
            end

            path = uigetdir(pwd, 'Select Export Folder');
            if isequal(path, 0)
                appendLog('EXPORT CANCELLED');
                return;
            end

            folderName = sprintf('NAPOLEON_Export_%s', datestr(now, 'yyyyMMdd_HHmmss'));
            exportDir = fullfile(path, folderName);
            mkdir(exportDir);

            setBusy(true, 'EXPORTING');
            appendLog('EXPORT STARTED. This might take a minute...');
            drawnow;

            excelFile = fullfile(exportDir, 'NAPOLEON_Tables_Report.xlsx');

            writecell([setupTable.ColumnName'; setupTable.Data], excelFile, 'Sheet', 'Configuration');
            writecell([kpiTable.ColumnName'; kpiTable.Data], excelFile, 'Sheet', 'KPI_Summary');

            matFile = fullfile(exportDir, 'NAPOLEON_RawData.mat');
            RESULTS = State.RESULTS;
            SCENARIO = State.SCENARIO;
            params = State.params;
            save(matFile, 'RESULTS', 'SCENARIO', 'params');

            tempFig = figure('Visible', 'off', 'Position', [100 100 1200 800], 'Color', 'w');
            tempAx = axes(tempFig);

            plotsToExport = {"SNREvolution", "rateFairnessCDF", "throughputEvolution", ...
                             "totalHandoversEvolution", "servedUsersFractionEvolution", "handoverFrequencyCDF"};

            policy = string(State.params.associationAlgorithm);
            if policy == "URLLC"
                plotsToExport = [plotsToExport, {"URLLC_latency90", "URLLC_TCR"}];
            elseif policy == "eMBB"
                plotsToExport = [plotsToExport, {"eMBB_spectralEfficiency", "eMBB_TCR"}];
            end

            for i = 1:length(plotsToExport)
                cla(tempAx, 'reset');


                tempAx.Color = [1 1 1];
                tempAx.XColor = [0 0 0];
                tempAx.YColor = [0 0 0];
                tempAx.GridColor = [0.15 0.15 0.15];
                tempAx.Box = 'off';

                plotNAPOLEONKPI(State.RESULTS, State.SCENARIO, plotsToExport{i}, 'Axes', tempAx, 'LineWidth', 2);

                tempAx.Title.Color = 'k';
                if ~isempty(tempAx.Subtitle)
                    tempAx.Subtitle.Color = 'k';
                end

                exportgraphics(tempFig, fullfile(exportDir, sprintf('%s.png', plotsToExport{i})), 'Resolution', 300);
            end


            cla(tempAx);

            tempAx.Color = [1 1 1];
            tempAx.XColor = [0 0 0];
            tempAx.YColor = [0 0 0];
            tempAx.GridColor = [0.15 0.15 0.15];
            tempAx.Box = 'off';

            plotUserScenarioDistribution(State.SCENARIO.satelliteScenario, State.SCENARIO.configAoI, 'Axes', tempAx, 'ShowCityLabels', true, 'ShowUsers', true);
            tempAx.Title.Color = 'k';

            exportgraphics(tempFig, fullfile(exportDir, 'UserDistributionMap.png'), 'Resolution', 300);
            close(tempFig);

            appendLog(['EXPORTED TO: ', exportDir]);
            setBusy(false);
            uialert(fig, sprintf('All data successfully exported to:\n%s', exportDir), 'Export Complete', 'Icon', 'success');

            uialert(fig, sprintf('All data successfully exported to:\n%s', exportDir), 'Export Complete', 'Icon', 'success');

        catch ME
            if exist('tempFig', 'var') && isgraphics(tempFig)
                close(tempFig);
            end
            setBusy(false);
            uialert(fig, ME.message, 'Export Error');
            appendLog(['EXPORT ERROR: ', ME.message]);
        end
    end

    function onDefaultValues(~, ~)
        params = State.defaultParams;
        setInputFieldsFromParams(params);
        State.params = params;
        clearSimulationWorkspace(false);
        kpiTable.Data = kpiTableData([], params);
        complianceTable.Data = serviceComplianceData([], params);
        violationsTable.Data = violationsPanelData([], params);
        appendLog('DEFAULT PARAMETERS LOADED');
        refreshUI('initial');
    end

        function onResetWorkspace(~, ~)
        msg = "Resetting the workspace will discard all current configurations and results. Do you want to continue?";
        scelta = uiconfirm(fig, msg, "Warning", ...
            "Icon", "warning", ...
            "Options", ["Continue", "Cancel"], ...
            "DefaultOption", 2, "CancelOption", 2);

        if strcmp(scelta, "Cancel")
            return;
        end

        setInputFieldsEmpty();
        State.params = [];
        clearSimulationWorkspace(false);
        kpiTable.Data = kpiTableData([], []);
        complianceTable.Data = serviceComplianceData([], []);
        violationsTable.Data = violationsPanelData([], []);
        clearLog();
        setRuntimeBar(runMeter, 0.00, '00:00', C.railMuted, C);
        refreshUI('initial');
    end
    function onTune(~, ~)
        switch string(algDrop.Value)
            case "URLLC"
                tuneURLLC();
            case "eMBB"
                tuneEMBB();
        end

        setupTable.Data = referenceSetupData(State.params);
    end

    function onClearResults(~, ~)
        State.RESULTS = [];
        State.associationCompleted = false;
        appendLog('RESULTS CLEARED');
        refreshUI('scenarioReady');
    end

    function onCopySummary(~, ~)
        txt = strjoin(composeSummaryLines(), newline);
        clipboard('copy', txt);
        appendLog('SUMMARY COPIED TO CLIPBOARD');
    end

    function clearLog()
        logBox.Value = {'READY'};
    end

    function copyLog()
        v = logBox.Value;
        if ischar(v)
            v = {v};
        end
        clipboard('copy', strjoin(v, newline));
        appendLog('LOG COPIED TO CLIPBOARD');
    end

    function [params, isComplete] = readGUI(requireComplete)
        if nargin < 1
            requireComplete = true;
        end

        if isfield(State, 'params') && ~isempty(State.params)
            params = State.params;
        else
            params = State.defaultParams;
        end
        missing = {};
        isComplete = true;

        numUsersTxt = strtrim(string(numUsersField.Value));
        seedTxt = strtrim(string(seedField.Value));
        csiValue = string(csiDrop.Value);
        algValue = string(algDrop.Value);

        if numUsersTxt == ""
            missing{end+1} = 'Terminals';
            isComplete = false;
        else
            numUsersValue = str2double(numUsersTxt);
            if isnan(numUsersValue) || ~isfinite(numUsersValue) || numUsersValue <= 0
                isComplete = false;
                if requireComplete
                    error('Terminals must be a positive numeric value.');
                end
            else
                params.numUsers = round(numUsersValue);
            end
        end


        if csiValue == "--"
            missing{end+1} = 'CSI mode';
            isComplete = false;
        else
            params.CSImode = csiValue;
        end

        if algValue == "--"
            missing{end+1} = 'Policy';
            isComplete = false;
        else
            params.associationAlgorithm = algValue;
        end

        if seedTxt == ""
            missing{end+1} = 'Seed';
            isComplete = false;
        else
            seedValue = str2double(seedTxt);
            if isnan(seedValue) || ~isfinite(seedValue)
                isComplete = false;
                if requireComplete
                    error('Seed must be a numeric value.');
                end
            else
                params.seed = round(seedValue);
            end
        end

        if ~isComplete
            if requireComplete
                error(['Complete parameter setup before running: ', strjoin(missing, ', '), '.']);
            end
        end
    end

    function clearSimulationWorkspace(resetParams)
        if nargin < 1
            resetParams = false;
        end

        if isfield(State, 'viewer') && ~isempty(State.viewer) && isvalid(State.viewer)
            try
                close(State.viewer);
            catch
            end
        end

        State.SCENARIO = [];
        State.scenarioPlotData = [];
        State.RESULTS = [];
        State.viewer = [];
        State.scenarioGenerated = false;
        State.associationCompleted = false;
        State.lastRunStarted = [];
        State.lastRunFinished = [];
        State.runPhase = "";
        stopRunTimer(false);

        if resetParams
            State.params = [];
        end

        clearAtlasMap(ax, C);
        canvasSubtitle.Text = '';
        canvasFooter.Text = '';
    end

    function setInputFieldsFromParams(params)
        numUsersField.Value = num2str(params.numUsers);
        csiDrop.Value = char(string(params.CSImode));
        algDrop.Value = char(string(params.associationAlgorithm));
        seedField.Value = num2str(params.seed);
    end

    function setInputFieldsEmpty()
        numUsersField.Value = '';
        csiDrop.Value = '--';
        algDrop.Value = '--';
        seedField.Value = '';
    end

    function openSatelliteViewer()
        try
            if isempty(State.SCENARIO) || ~isfield(State.SCENARIO, 'satelliteScenario') || isempty(State.SCENARIO.satelliteScenario)
                uialert(fig, 'satelliteScenario object missing.', 'Viewer unavailable');
                return;
            end

            State.viewer = satelliteScenarioViewer(State.SCENARIO.satelliteScenario);
            appendLog('SATELLITE VIEWER OPENED');

        catch ME
            handleError(ME, false);
        end
    end

    function setBusy(flag, label)
        if flag
            State.runPhase = string(label);
            startRunTimer(label);

            State.savedFooterText = canvasFooter.Text;
            canvasFooter.Text = '';

            wg = findobj(canv, 'Tag', 'welcomeGrid');
            if ~isempty(wg)
                delete(wg);
            end


            if isfield(State, 'kpiTabGroup') && ~isempty(State.kpiTabGroup) && isgraphics(State.kpiTabGroup)
                if label == "EXPORTING"
                    State.kpiTabGroup.Visible = 'off';
                else
                    delete(State.kpiTabGroup.Children);
                    State.kpiTabs = struct();
                    State.kpiTabGroup.Visible = 'off';
                end
            end

            vt = findobj(canv, 'Tag', 'testoVuotoKPI');
            if ~isempty(vt)
                vt.Text = ['[' char(label) '] in progress... Please wait.'];
                vt.Visible = 'on';
            end

            if isgraphics(ax)
                ax.Visible = 'off';
            end

            drawnow;


            enableAction(scenarioBadge, false);
            enableAction(assocBadge, false);
            enableAction(exportBadge, false);
            numUsersField.Enable = 'off';
            csiDrop.Enable = 'off';
            algDrop.Enable = 'off';
            seedField.Enable = 'off';
            defaultBtn.Enable = 'off';
            resetWorkspaceBtn.Enable = 'off';
        else
            stopRunTimer(true);
            if isfield(State, 'savedFooterText')
                canvasFooter.Text = State.savedFooterText;
            end
            refreshUI('preserve');
        end

        drawnow;
    end

    function refreshUI(mode)
        if nargin < 1
            mode = 'preserve';
        end

        [currentParams, paramsComplete] = readGUI(false);
        State.params = currentParams;
        setupTable.Data = referenceSetupData(currentParams);

        if State.associationCompleted
            canvasTitleLabel.Text = 'KPI Analytics Dashboard';
            setRailStatus('RESULTS READY', C.ready, C);
            setRibbonBadge(scenarioBadge, 'Scenario', 'READY', C.greenSoft, C.ready);
            setRibbonBadge(assocBadge, 'Association', 'DONE', C.greenSoft, C.ready);
            setRibbonBadge(exportBadge, 'Export', 'READY', C.blueSoft, C.accent);

            enableAction(scenarioBadge, true);
            enableAction(assocBadge, true);
            enableAction(exportBadge, true);
            numUsersField.Enable = 'on';
            csiDrop.Enable = 'on';
            algDrop.Enable = 'on';
            seedField.Enable = 'on';
            defaultBtn.Enable = 'on';
            resetWorkspaceBtn.Enable = 'on';

            complianceTable.Data = serviceComplianceData(State.RESULTS, State.params);
            violationsTable.Data = violationsPanelData(State.RESULTS, State.params);
            kpiTable.Data = kpiTableData(State.RESULTS, State.params);

           policy = string(currentParams.associationAlgorithm);
           updateDynamicKPIButtons("results", policy);


            canvasSubtitle.Text = '';
            canvasFooter.Text = '';

            canv.RowHeight = {58, '1x', 55};
            canvasFooter.WordWrap = 'on';
            canvasFooter.Text = 'Select a KPI to visualize its description.';
            canvasFooter.FontColor = C.muted;




            ax.Visible = 'off';
            cla(ax);

            wasUserDistOpen = false;
            if isfield(State, 'kpiTabGroup') && ~isempty(State.kpiTabGroup) && isgraphics(State.kpiTabGroup)
                for k = 1:length(State.kpiTabGroup.Children)
                    if strcmp(State.kpiTabGroup.Children(k).Title, 'User Dist.')
                        wasUserDistOpen = true;
                        break;
                    end
                end
            end

            if isfield(State, 'kpiTabGroup') && ~isempty(State.kpiTabGroup) && isgraphics(State.kpiTabGroup)
                delete(State.kpiTabGroup);
            end

            State.kpiTabGroup = uitabgroup(canv);
            State.kpiTabGroup.SelectionChangedFcn = @(src, event) updateFooterText(event.NewValue.Title);
            State.kpiTabGroup.Layout.Row = 2;
            State.kpiTabGroup.Layout.Column = 1;
            State.kpiTabGroup.Visible = 'off';

            State.kpiTabs = struct();

            vecchioTesto = findobj(canv, 'Tag', 'testoVuotoKPI');
            delete(vecchioTesto);

            testoSegnaposto = uilabel(canv, ...
                'Text', 'Select from the right panel the Performance indicator that you want to analyze', ...
                'FontName', fontName, ...
                'FontSize', 16, ...
                'FontColor', C.disabled, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'center', ...
                'Tag', 'testoVuotoKPI');
            testoSegnaposto.Layout.Row = 2;
            testoSegnaposto.Layout.Column = 1;

             if wasUserDistOpen
                handleKPIClick('User Dist.', "UserDistribution");
            end



        elseif State.scenarioGenerated
            canvasTitleLabel.Text = 'KPI Analytics Dashboard';

            if isfield(State, 'kpiTabGroup') && ~isempty(State.kpiTabGroup) && isgraphics(State.kpiTabGroup)
                State.kpiTabGroup.SelectionChangedFcn = '';
                delete(State.kpiTabGroup.Children);
                State.kpiTabGroup.SelectionChangedFcn = @(src, event) updateFooterText(event.NewValue.Title);

                State.kpiTabs = struct();
                State.kpiTabGroup.Visible = 'off';
            else
                State.kpiTabGroup = uitabgroup(canv);
                State.kpiTabGroup.SelectionChangedFcn = @(src, event) updateFooterText(event.NewValue.Title);
                State.kpiTabGroup.Layout.Row = 2;
                State.kpiTabGroup.Layout.Column = 1;
                State.kpiTabGroup.Visible = 'off';
                State.kpiTabs = struct();
            end

            vecchioTesto = findobj(canv, 'Tag', 'testoVuotoKPI');
            delete(vecchioTesto);

            nuovoTesto = uilabel(canv, ...
                'Text', 'Scenario Generated. Click "User Dist." to view the terminal distribution map.', ...
                'FontName', fontName, ...
                'FontSize', 16, ...
                'FontColor', C.disabled, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'center', ...
                'Tag', 'testoVuotoKPI');

            nuovoTesto.Layout.Row = 2;
            nuovoTesto.Layout.Column = 1;

            ax.Visible = 'off';
            cla(ax);

            setRailStatus('SCENARIO READY', C.ready, C);
            setRibbonBadge(scenarioBadge, 'Scenario', 'READY', C.greenSoft, C.ready);
            setRibbonBadge(assocBadge, 'Association', 'RUN', C.blueSoft, C.accent);
            setRibbonBadge(exportBadge, 'Export', 'LOCKED', C.neutralSoft, C.disabled);

            enableAction(scenarioBadge, true);
            enableAction(assocBadge, true);
            enableAction(exportBadge, false);
            numUsersField.Enable = 'on';
            csiDrop.Enable = 'on';
            algDrop.Enable = 'on';
            seedField.Enable = 'on';
            defaultBtn.Enable = 'on';
            resetWorkspaceBtn.Enable = 'on';

            complianceTable.Data = serviceComplianceData([], State.params);
            violationsTable.Data = violationsPanelData([], State.params);
            kpiTable.Data = kpiTableData([], currentParams);

            policy = string(currentParams.associationAlgorithm);
            updateDynamicKPIButtons("scenario", policy);

            canvasSubtitle.Text = '';
            canvasFooter.Text = scenarioDistributionFooter(State.scenarioPlotData, State.params);
        else


            if strcmp(mode, 'stale')
                if paramsComplete
                    setRailStatus('CONFIG STALE', C.warnText, C);
                    setRibbonBadge(scenarioBadge, 'Scenario', 'RUN', C.warnSoft, C.warnText);
                    complianceTable.Data = serviceComplianceData([], currentParams);
                    violationsTable.Data = violationsPanelData([], currentParams);
                else
                    setRailStatus('STANDBY', C.railMuted, C);
                    setRibbonBadge(scenarioBadge, 'Scenario', 'SETUP', C.neutralSoft, C.disabled);
                    complianceTable.Data = serviceComplianceData([], []);
                    violationsTable.Data = violationsPanelData([], []);
                end
            else
                setRailStatus('STANDBY', C.railMuted, C);
                if paramsComplete
                    setRibbonBadge(scenarioBadge, 'Scenario', 'RUN', C.blueSoft, C.accent);
                    complianceTable.Data = serviceComplianceData([], currentParams);
                    violationsTable.Data = violationsPanelData([], currentParams);
                else
                    setRibbonBadge(scenarioBadge, 'Scenario', 'SETUP', C.neutralSoft, C.disabled);
                    complianceTable.Data = serviceComplianceData([], []);
                    violationsTable.Data = violationsPanelData([], []);
                end
            end

            setRibbonBadge(assocBadge, 'Association', 'LOCKED', C.neutralSoft, C.disabled);
            setRibbonBadge(exportBadge, 'Export', 'LOCKED', C.neutralSoft, C.disabled);

            enableAction(scenarioBadge, paramsComplete);
            enableAction(assocBadge, false);
            enableAction(exportBadge, false);
            numUsersField.Enable = 'on';
            csiDrop.Enable = 'on';
            algDrop.Enable = 'on';
            seedField.Enable = 'on';
            defaultBtn.Enable = 'on';
            resetWorkspaceBtn.Enable = 'on';

            kpiTable.Data = kpiTableData([], currentParams);

            policy = string(currentParams.associationAlgorithm);
            updateDynamicKPIButtons("off", policy);
            clearAtlasMap(ax, C);
            canvasTitleLabel.Text = '';
            canvasSubtitle.Text = '';
            canvasFooter.Text = '';

            if isfield(State, 'kpiTabGroup') && ~isempty(State.kpiTabGroup) && isgraphics(State.kpiTabGroup)
                delete(State.kpiTabGroup);
                State.kpiTabGroup = [];
                State.kpiTabs = struct();
            end



            delete(findobj(canv, 'Tag', 'testoVuotoKPI'));
            delete(findobj(canv, 'Tag', 'welcomeGrid'));

            wGrid = uigridlayout(canv, [1 1]);
            wGrid.RowHeight = {'1x'};
            wGrid.ColumnWidth = {'1x'};
            wGrid.Padding = [0 0 0 0];
            wGrid.BackgroundColor = C.canvas;
            wGrid.Layout.Row = 2;
            wGrid.Layout.Column = 1;
            wGrid.Tag = 'welcomeGrid';

            img = uiimage(wGrid);
            img.ImageSource = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'images', 'Background_image.jpeg');
            img.HorizontalAlignment = 'center';
            img.VerticalAlignment = 'center';
            img.ScaleMethod = 'fit';


            vt = uilabel(canv, 'Text', '', 'Tag', 'testoVuotoKPI', 'Visible', 'off', ...
                'FontName', fontName, 'FontSize', 16, 'FontColor', [0.55 0.55 0.55], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'center');
            vt.Layout.Row = 2;
            vt.Layout.Column = 1;


        end
    end

    function txt = scenarioDistributionFooter(D, params)
        txt='';
    end

    function setRailStatus(txt, color, C)
        state = upper(string(txt));
        if state == "RESULTS READY"
            setRuntimeBar(runMeter, 1.00, currentElapsedText(), color, C);
        elseif state == "SCENARIO READY"
            setRuntimeBar(runMeter, 1.00, currentElapsedText(), color, C);
        elseif state == "CONFIG STALE"
            setRuntimeBar(runMeter, 0.00, '00:00', color, C);
        elseif state == "ERROR"
            setRuntimeBar(runMeter, 1.00, currentElapsedText(), color, C);
        else
            setRuntimeBar(runMeter, 0.00, '00:00', color, C);
        end
    end

    function startRunTimer(label)
        stopRunTimer(false);
        State.runPhase = string(label);
        updateRuntimeBarLive();

        try
            State.runTimer = timer( ...
                'ExecutionMode', 'fixedSpacing', ...
                'Period', 0.25, ...
                'BusyMode', 'drop', ...
                'TimerFcn', @(~,~) updateRuntimeBarLive());
            start(State.runTimer);
        catch
            State.runTimer = [];
        end
    end

    function stopRunTimer(finalize)
        if isfield(State, 'runTimer') && ~isempty(State.runTimer)
            try
                if isvalid(State.runTimer)
                    stop(State.runTimer);
                    delete(State.runTimer);
                end
            catch
            end
        end
        State.runTimer = [];

        if finalize
            updateRuntimeBarLive(true);
        end
    end

    function updateRuntimeBarLive(varargin)
        if isempty(State.lastRunStarted)
            elapsedText = '00:00';
            elapsedSeconds = 0;
        else
            if ~isempty(State.lastRunFinished)
                dt = State.lastRunFinished - State.lastRunStarted;
            else
                dt = datetime('now') - State.lastRunStarted;
            end
            elapsedSeconds = max(0, seconds(dt));
            elapsedText = elapsedToText(elapsedSeconds);
        end

        phase = upper(string(State.runPhase));
        if nargin > 0 && ~isempty(varargin{1}) && varargin{1}
            fraction = 1.0;
            fillColor = C.ready;
        elseif phase == "GENERATING"
            fraction = chargingFraction(elapsedSeconds, 18.0);
            fillColor = C.busy;
        elseif phase == "ASSOCIATING"
            fraction = chargingFraction(elapsedSeconds, 28.0);
            fillColor = C.accent;
        elseif phase == "EXPORTING"
            fraction = chargingFraction(elapsedSeconds, 8.0);
            fillColor = C.accent2;
        else
            fraction = 0.0;
            fillColor = C.railMuted;
        end

        setRuntimeBar(runMeter, fraction, elapsedText, fillColor, C);

        if ~isempty(runMeter) && isfield(runMeter, 'Arc') && ...
       isvalid(runMeter.Arc) && fraction > 0 && fraction < 1

        runMeter.SpinAngle = runMeter.SpinAngle + 0.25;

        arcSpan = runMeter.arcSpan;
        theta   = linspace(runMeter.SpinAngle, runMeter.SpinAngle + arcSpan, 40);
        runMeter.Arc.XData = cos(theta);
        runMeter.Arc.YData = sin(theta);
    end




        drawnow limitrate;
    end

    function fraction = chargingFraction(elapsedSeconds, timeScale)
        fraction = 0.04 + 0.91*(1 - exp(-elapsedSeconds/timeScale));
        fraction = min(max(fraction, 0.04), 0.95);
    end

    function txt = currentElapsedText()
        if isempty(State.lastRunStarted)
            txt = '00:00';
            return;
        end

        if isempty(State.lastRunFinished)
            dt = datetime('now') - State.lastRunStarted;
        else
            dt = State.lastRunFinished - State.lastRunStarted;
        end

        txt = elapsedToText(max(0, seconds(dt)));
    end

    function txt = elapsedToText(elapsedSeconds)
        s = max(0, floor(elapsedSeconds));
        h = floor(s/3600);
        m = floor(mod(s, 3600)/60);
        sec = mod(s, 60);

        if h > 0
            txt = sprintf('%02d:%02d:%02d', h, m, sec);
        else
            txt = sprintf('%02d:%02d', m, sec);
        end
    end

    function onClose(~, ~)
        stopRunTimer(false);
        delete(fig);
    end

    function appendLog(msg)
        old = logBox.Value;
        if ischar(old)
            old = {old};
        end

        stamp = datestr(now, 'HH:MM:SS');
        newLine = [stamp, '  ', msg];
        lines = [old; {newLine}];

        if numel(lines) > 120
            lines = lines(end-119:end);
        end

        logBox.Value = lines;

    end

    function handleError(ME, showDialog)
        setRailStatus('ERROR', C.error, C);
        appendLog(['ERROR  ', ME.message]);

        if showDialog
            uialert(fig, getReport(ME, 'extended', 'hyperlinks', 'off'), 'NAPOLEON+ error');
        end
    end

    function s = scenarioSubtitle()
        s = sprintf('%d terminals | %s CSI | seed %d', ...
            State.params.numUsers, char(string(State.params.CSImode)), State.params.seed);
    end

    function s = kpiSubtitle()
        if isempty(State.RESULTS)
            s = 'No KPI object';
            return;
        end

        if isfield(State.RESULTS, 'KPI_results')
            names = fieldnames(State.RESULTS.KPI_results);
            s = sprintf('%d KPI fields detected', numel(names));
        else
            s = 'RESULTS.KPI_results not found';
        end
    end

    function lines = composeSummaryLines()
        lines = { ...
            ['Scenario: ', ternary(State.scenarioGenerated, 'ready', 'empty')], ...
            ['Association: ', ternary(State.associationCompleted, 'completed', 'not completed')], ...
            ['Terminals: ', num2str(State.params.numUsers)], ...
            ['CSI mode: ', char(string(State.params.CSImode))], ...
            ['Policy: ', char(string(State.params.associationAlgorithm))], ...
            ['Seed: ', num2str(State.params.seed)]};

        if State.associationCompleted && isfield(State.RESULTS, 'KPI_results')
            lines = [lines; {' '; 'KPI results:'}; structToLines(State.RESULTS.KPI_results)];
        end
    end

    function tuneURLLC()
        if isempty(State.params)
            State.params = State.defaultParams;
        end
        p = State.params.policy.URLLC;
         d = modalWindow('URLLC Policy Tuning', C, [470 315 455 465]);
        g = uigridlayout(d, [10 2]);
         g.RowHeight = {50, 16, 42, 16, 42, 42, 42, 42, 12, 42};
        g.ColumnWidth = {205, '1x'};
        g.Padding = [20 20 20 20];
        g.RowSpacing = 8;
        g.BackgroundColor = C.bg;

        testoInfo_URLLC = {
            'TUNABLE PARAMETERS FOR URLLC:',
            '',
            '• Delta latency: Handover occurs only if',
            '  the new satellite reduces latency by at least this amount.',
            '• Max latency: The absolute maximum delay tolerated by the service.',
            '• Min SNR: The minimum Signal-to-Noise Ratio required to guarantee',
            '  ultra-high reliability.',
            '• Time window: Number of slots used to evaluate strict KPIs.',
            '• Max handovers: Strict limit on handovers within the window,',
            '  as handovers cause unacceptable latency spikes.'
        };

        modalHeader(g, 'URLLC policy', 'Latency-constrained association controls', testoInfo_URLLC, C, fontName);
        modalSectionLabel(g, 'Association Control', C, fontName);
        f1 = modalNumeric(g, 'Delta latency [s]', p.URLLC_DeltaTau_switch_s, C, fontName);

        modalSectionLabel(g, 'KPI Control', C, fontName);
        f2 = modalNumeric(g, 'Max latency [s]', p.latency_max_URLLC, C, fontName);
        f3 = modalNumeric(g, 'Min SNR [linear]', p.SNRmin_URLLC_lin, C, fontName);
        f4 = modalNumeric(g, 'Time window', p.time_window, C, fontName);
        f5 = modalNumeric(g, 'Max handovers', p.handoverMax_URLLC, C, fontName);

        spacer(g, C.bg, fontName); spacer(g, C.bg, fontName);

        reset = flatButton(g, 'Default', C.cardAlt, C.text, fontName);
        apply = flatButton(g, 'Apply', C.blueSoft, C.accent, fontName);

        reset.ButtonPushedFcn = @(~,~) resetURLLC();
        apply.ButtonPushedFcn = @(~,~) applyURLLC();

        function resetURLLC()
            q = default_NAPOLEON_params();
            f1.Value = q.policy.URLLC.URLLC_DeltaTau_switch_s;
            f2.Value = q.policy.URLLC.latency_max_URLLC;
            f3.Value = q.policy.URLLC.SNRmin_URLLC_lin;
            f4.Value = q.policy.URLLC.time_window;
            f5.Value = q.policy.URLLC.handoverMax_URLLC;
        end

        function applyURLLC()
            if State.associationCompleted
                msg = 'Changing the parameters will require performing the association again. All current results will be deleted. Do you want to proceed?';
                scelta = uiconfirm(d, msg, 'Warning', 'Options', {'Proceed', 'Cancel'}, ...
                                   'DefaultOption', 2, 'CancelOption', 2, 'Icon', 'warning');
                if strcmp(scelta, 'Cancel')
                    return;
                end
            end

            try
                State.params.policy.URLLC.URLLC_DeltaTau_switch_s = f1.Value;
                State.params.policy.URLLC.latency_max_URLLC = f2.Value;
                State.params.policy.URLLC.SNRmin_URLLC_lin = f3.Value;
                State.params.policy.URLLC.time_window = round(f4.Value);
                State.params.policy.URLLC.handoverMax_URLLC = round(f5.Value);

                validate_NAPOLEON_params(State.params);
                appendLog('URLLC POLICY UPDATED');
                State.RESULTS = [];
                State.associationCompleted = false;
                refreshUI('scenarioReady');
                delete(d);
            catch ME
                uialert(d, ME.message, 'Invalid URLLC values');
            end
        end
    end

    function tuneEMBB()
        if isempty(State.params)
            State.params = State.defaultParams;
        end
        p = State.params.policy.eMBB;
                d = modalWindow('eMBB Policy Tuning', C, [470 335 455 420]);

        g = uigridlayout(d, [9 2]);
        g.RowHeight = {50, 16, 42, 16, 42, 42, 42, 12, 42};
        g.ColumnWidth = {205, '1x'};
        g.Padding = [20 20 20 20];
        g.RowSpacing = 8;
        g.BackgroundColor = C.bg;

       testoInfo_eMBB = {
            'TUNABLE PARAMETERS FOR eMBB:',
            '',
            '• Delta rate: A handover triggers only if',
            '  the new satellite offers this much more throughput (prevents ping-pong).',
            '• Min rate: The target minimum throughput required to satisfy the service.',
            '• Time window: Number of slots used to evaluate stability and KPIs.',
            '• Max handovers: Maximum allowed handovers within the time window',
            '  to limit signaling overhead.'
        };

        modalHeader(g, 'eMBB policy', 'Throughput-constrained association controls', testoInfo_eMBB, C, fontName);

        modalSectionLabel(g, 'Association Control', C, fontName);
        f1 = modalNumeric(g, 'Delta rate [bit/s]', p.eMBB_DeltaR_switch_bps, C, fontName);

        modalSectionLabel(g, 'KPI Control', C, fontName);
        f2 = modalNumeric(g, 'Min rate [bit/s]', p.rateMin_eMBB_bps, C, fontName);
        f3 = modalNumeric(g, 'Time window', p.time_window, C, fontName);
        f4 = modalNumeric(g, 'Max handovers', p.handoverMax_eMBB, C, fontName);

        spacer(g, C.bg, fontName); spacer(g, C.bg, fontName);
        reset = flatButton(g, 'Default', C.cardAlt, C.text, fontName);
        apply = flatButton(g, 'Apply', C.blueSoft, C.accent, fontName);

        reset.ButtonPushedFcn = @(~,~) resetEMBB();
        apply.ButtonPushedFcn = @(~,~) applyEMBB();

        function resetEMBB()
            q = default_NAPOLEON_params();
            f1.Value = q.policy.eMBB.eMBB_DeltaR_switch_bps;
            f2.Value = q.policy.eMBB.rateMin_eMBB_bps;
            f3.Value = q.policy.eMBB.time_window;
            f4.Value = q.policy.eMBB.handoverMax_eMBB;
        end

        function applyEMBB()
            if State.associationCompleted
                msg = 'Changing the parameters will require performing the association again. All current results will be deleted. Do you want to proceed?';
                scelta = uiconfirm(d, msg, 'Warning', 'Options', {'Proceed', 'Cancel'}, ...
                                   'DefaultOption', 2, 'CancelOption', 2, 'Icon', 'warning');
                if strcmp(scelta, 'Cancel')
                    return;
                end
            end

            try
                State.params.policy.eMBB.eMBB_DeltaR_switch_bps = f1.Value;
                State.params.policy.eMBB.rateMin_eMBB_bps = f2.Value;
                State.params.policy.eMBB.time_window = round(f3.Value);
                State.params.policy.eMBB.handoverMax_eMBB = round(f4.Value);

                validate_NAPOLEON_params(State.params);
                appendLog('eMBB POLICY UPDATED');
                State.RESULTS = [];
                State.associationCompleted = false;
                refreshUI('scenarioReady');
                delete(d);
            catch ME
                uialert(d, ME.message, 'Invalid eMBB values');
            end
        end
    end

function launchViewer(~, ~)
        State.viewer = satelliteScenarioViewer(State.SCENARIO.satelliteScenario);
end



function handleKPIClick(tabTitle, plotID)

        tabKey = matlab.lang.makeValidName(tabTitle);

        if isempty(State.kpiTabGroup) || ~isgraphics(State.kpiTabGroup)
            return;
        end

        State.kpiTabGroup.Visible = 'on';

        canvasFooter.FontColor = C.text;

        updateFooterText(tabTitle);
        testoSegnaposto = findobj(State.kpiTabGroup.Parent, 'Tag', 'testoVuotoKPI');
        if ~isempty(testoSegnaposto)
            testoSegnaposto.Visible = 'off';
        end

        if isfield(State.kpiTabs, tabKey) && isgraphics(State.kpiTabs.(tabKey))
            State.kpiTabGroup.SelectedTab = State.kpiTabs.(tabKey);
            return;
        end


        testoSegnaposto = findobj(State.kpiTabGroup.Parent, 'Tag', 'testoVuotoKPI');
        if ~isempty(testoSegnaposto)
            testoSegnaposto.Visible = 'off';
        end

        if isfield(State.kpiTabs, tabKey) && isgraphics(State.kpiTabs.(tabKey))
            State.kpiTabGroup.SelectedTab = State.kpiTabs.(tabKey);
            return;
        end

        newTab = uitab(State.kpiTabGroup, 'Title', tabTitle);
        newTab.BackgroundColor = [1 1 1];
        State.kpiTabs.(tabKey) = newTab;

        tabGrid = uigridlayout(newTab, [1 1]);
        tabGrid.Padding = [0 0 0 0];
        tabGrid.BackgroundColor = [1 1 1];

        tabAx = uiaxes(tabGrid);
        tabAx.Layout.Row = 1;
        tabAx.Layout.Column = 1;

        tabAx.Color = [1 1 1];
        tabAx.XColor = [0 0 0];
        tabAx.YColor = [0 0 0];
        tabAx.GridColor = [0.15 0.15 0.15];
        tabAx.Box = 'off';
        State.kpiTabGroup.SelectedTab = newTab;

         try
            if plotID == "UserDistribution"
                plotUserScenarioDistribution(State.SCENARIO.satelliteScenario, State.SCENARIO.configAoI, 'Axes', tabAx, 'ShowCityLabels', true, 'ShowUsers', true);
            else
                plotNAPOLEONKPI(State.RESULTS, State.SCENARIO, plotID, 'Axes', tabAx, 'LineWidth', 2);
            end
            tabAx.Box = 'off';

            tabAx.Title.Color = 'k';
            if ~isempty(tabAx.Subtitle)
                tabAx.Subtitle.Color = 'k';
            end

        catch ME
            uialert(fig, sprintf('Impossibile generare il grafico "%s".\nMotivo: %s', tabTitle, ME.message), 'Avviso KPI');
            delete(newTab);
            State.kpiTabs = rmfield(State.kpiTabs, tabKey);
            if isempty(State.kpiTabGroup.Children)
                State.kpiTabGroup.Visible = 'off';
            end
        end
end



        function openUserInspector(~, ~)
        if ~State.associationCompleted
            uialert(fig, 'Run association first to inspect a user.', 'No Results');
            return;
        end

        d = modalWindow('User Inspector', C, [100 100 900 650]);
        movegui(d, 'center');

        mainGrid = uigridlayout(d, [4 1]);
        mainGrid.RowHeight = {65, 45, '1x', 30};
        mainGrid.Padding = [20 20 20 20];
        mainGrid.BackgroundColor = C.bg;

        headerGrid = uigridlayout(mainGrid, [2 2]);
        headerGrid.Layout.Row = 1;
        headerGrid.RowHeight = {30, 20};
        headerGrid.ColumnWidth = {'1x', 30};
        headerGrid.Padding = [0 0 0 0];
        headerGrid.RowSpacing = 2;
        headerGrid.BackgroundColor = C.bg;

        tit = uilabel(headerGrid, 'Text', 'User Inspector', 'FontName', fontName, 'FontSize', 24, 'FontWeight', 'bold', 'FontColor', C.text);
        tit.Layout.Row = 1;
        tit.Layout.Column = 1;

        sub = uilabel(headerGrid, 'Text', 'Inspect the evolution of specific KPIs for a single user', 'FontName', fontName, 'FontSize', 13, 'FontColor', C.muted);
        sub.Layout.Row = 2;
        sub.Layout.Column = [1 2];

        infoTextUser = {
            'USER PLOTS EXPLANATION:',
            '',
            '• Rate Evolution: Shows how the data rate assigned to this user changes over time.',
            '• Service State Evolution: Shows if the user is served for each time step.',
            '     The curve il blue if the user is served during the whole simulation, red if the user',
            '     has some time windows without service. The time step without service are highlighted in grey.'

        };

        infoBtn = uibutton(headerGrid, ...
            'Text', '?', ...
            'Tooltip', infoTextUser, ...
            'FontName', fontName, ...
            'FontSize', 18, ...
            'FontWeight', 'bold', ...
            'FontColor', C.accent, ...
            'BackgroundColor', C.bg);
        infoBtn.Layout.Row = 1;
        infoBtn.Layout.Column = 2;
        ctrlGrid = uigridlayout(mainGrid, [1 5]);
        ctrlGrid.Layout.Row = 2;
        ctrlGrid.ColumnWidth = {'fit', 70, 160, 200, '1x'};
        ctrlGrid.ColumnSpacing = 15;
        ctrlGrid.Padding = [0 0 0 0];
        ctrlGrid.BackgroundColor = C.bg;

        maxUsers = State.RESULTS.USER_SAT_association.numUsers;
        labelText = sprintf('Insert the user id (from 1 to %d terminals):', maxUsers);

        uilabel(ctrlGrid, 'Text', labelText, 'FontName', fontName, 'FontColor', C.text, ...
            'FontSize', 13, 'HorizontalAlignment', 'left', 'BackgroundColor', C.bg);

        uidField = uieditfield(ctrlGrid, 'numeric');
        uidField.Value = 1;
        uidField.Limits = [1, maxUsers];
        uidField.RoundFractionalValues = 'on';
        uidField.FontName = fontName;
        uidField.FontSize = 13;
        uidField.BackgroundColor = C.card;
        uidField.FontColor = C.text;

        btnRate = flatButton(ctrlGrid, 'Rate Evolution', C.blueSoft, C.accent, fontName);
        btnState = flatButton(ctrlGrid, 'Service State Evolution', C.blueSoft, C.accent, fontName);

        tabGroup = uitabgroup(mainGrid);
        tabGroup.Layout.Row = 3;
        tabGroup.SelectionChangedFcn = @(src, event) updateDescLabel(event.NewValue);

        userTabs = struct();

        placeholderTab = uitab(tabGroup, 'Title', 'Waiting for User');
        placeholderTab.BackgroundColor = [1 1 1];
        placeholderGrid = uigridlayout(placeholderTab, [1 1]);
        placeholderGrid.BackgroundColor = [1 1 1];
        uilabel(placeholderGrid, 'Text', 'Insert a User ID and click a button above to generate a plot.', ...
            'FontName', fontName, 'FontSize', 14, 'FontColor', C.muted, ...
            'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1]);

        descLabel = uilabel(mainGrid, 'Text', '', 'FontName', fontName, 'FontSize', 13, ...
            'FontColor', C.muted, 'HorizontalAlignment', 'center', 'BackgroundColor', C.bg);
        descLabel.Layout.Row = 4;

        function updateDescLabel(selectedTab)
            if ~isempty(selectedTab) && ~isempty(selectedTab.UserData)
                descLabel.Text = selectedTab.UserData;
            else
                descLabel.Text = '';
            end
        end

        btnRate.ButtonPushedFcn = @(src, event) doPlotUser(uidField.Value, 'userRateEvolution', 'Rate', 'Rate Evolution', 'Instantaneous allocated throughput over time.');
        btnState.ButtonPushedFcn = @(src, event) doPlotUser(uidField.Value, 'userServiceStateEvolution', 'State', 'Service State Evolution', 'Handover Event (cumulative) over time.');

        function doPlotUser(uid, plotType, tabKey, titleStr, descStr)
            if isgraphics(placeholderTab)
                delete(placeholderTab);
            end

            if isfield(userTabs, tabKey) && isgraphics(userTabs.(tabKey))
                thisTab = userTabs.(tabKey);
                thisTab.Title = sprintf('%s (User %d)', titleStr, uid);
                delete(thisTab.Children);
            else
                thisTab = uitab(tabGroup, 'Title', sprintf('%s (User %d)', titleStr, uid));
                thisTab.BackgroundColor = [1 1 1];
                userTabs.(tabKey) = thisTab;
            end

            thisTab.UserData = descStr;

            tabGroup.SelectedTab = thisTab;

            tabGrid = uigridlayout(thisTab, [1 1]);
            tabGrid.Padding = [0 0 0 0];
            tabGrid.BackgroundColor = [1 1 1];

            tabAx = uiaxes(tabGrid);
            tabAx.Color = [1 1 1];
            tabAx.XColor = [0 0 0];
            tabAx.YColor = [0 0 0];
            tabAx.GridColor = [0.15 0.15 0.15];
            tabAx.Box = 'off';

            updateDescLabel(thisTab);

            try
                plotNAPOLEONKPI(State.RESULTS, State.SCENARIO, plotType, 'UserIndex', uid, 'Axes', tabAx);
                tabAx.Title.Color = 'k';
                if ~isempty(tabAx.Subtitle)
                    tabAx.Subtitle.Color = 'k';
                end
                tabAx.XLabel.Color = 'k';
                tabAx.YLabel.Color = 'k';
                tabAx.Box = 'off';
            catch ME
                uialert(d, sprintf('Error plotting user %d:\n%s', uid, ME.message), 'Error');
            end
        end
    end




        function updateDynamicKPIButtons(enabledFlag, policy)
        for j = 1:2
            if enabledFlag == "scenario" || enabledFlag == "results"
                kpiBtns(j).Enable = 'on';
                kpiBtns(j).BackgroundColor = C.blueSoft;
                kpiBtns(j).FontColor = C.accent;
            else
                kpiBtns(j).Enable = 'off';
                kpiBtns(j).BackgroundColor = C.neutralSoft;
                kpiBtns(j).FontColor = C.disabled;
            end
        end

        for j = 3:8
            if enabledFlag == "results"
                kpiBtns(j).Enable = 'on';
                kpiBtns(j).BackgroundColor = C.blueSoft;
                kpiBtns(j).FontColor = C.accent;
            else
                kpiBtns(j).Enable = 'off';
                kpiBtns(j).BackgroundColor = C.neutralSoft;
                kpiBtns(j).FontColor = C.disabled;
            end
        end

        if policy == "URLLC"
            kpiBtns(9).Text = 'URLLC Percentile';
            kpiBtns(9).ButtonPushedFcn = @(src, event) handleKPIClick('URLLC Percentile', 'URLLC_latency90');
            kpiBtns(9).Visible = 'on';

            kpiBtns(10).Text = 'URLLC TCR';
            kpiBtns(10).ButtonPushedFcn = @(src, event) handleKPIClick('URLLC TCR', 'URLLC_TCR');
            kpiBtns(10).Visible = 'on';
        elseif policy == "eMBB"
            kpiBtns(9).Text = 'eMBB SE';
            kpiBtns(9).ButtonPushedFcn = @(src, event) handleKPIClick('eMBB SE', 'eMBB_spectralEfficiency');
            kpiBtns(9).Visible = 'on';

            kpiBtns(10).Text = 'eMBB TCR';
            kpiBtns(10).ButtonPushedFcn = @(src, event) handleKPIClick('eMBB TCR', 'eMBB_TCR');
            kpiBtns(10).Visible = 'on';
        else
            kpiBtns(9).Visible = 'off';
            kpiBtns(10).Visible = 'off';
        end

        for j = 9:10
            if enabledFlag == "results"
                kpiBtns(j).Enable = 'on';
                kpiBtns(j).BackgroundColor = C.blueSoft;
                kpiBtns(j).FontColor = C.accent;
            else
                kpiBtns(j).Enable = 'off';
                kpiBtns(j).BackgroundColor = C.neutralSoft;
                kpiBtns(j).FontColor = C.disabled;
            end
        end
    end



function updateFooterText(tabTitle)
        canvasFooter.FontColor = C.text;
        switch tabTitle
            case 'User Dist.'
                canvasFooter.Text = 'User Distribution: 3D map showing the actual terminal positions extracted from the generated scenario.';
            case 'SNR Evol'
                canvasFooter.Text = 'SNR Evolution: Shows the time evolution of the average signal-to-noise ratio (SNR) of active links.';
            case 'Rate CDF'
                canvasFooter.Text = 'Rate Fairness CDF: Represents the Cumulative Distribution Function (CDF) of the average bitrate per user.';
            case 'Throughput'
                canvasFooter.Text = 'Throughput Evolution: Shows the evolution of the average throughput per terminal (in Mbit/s).';
            case 'Handovers'
                canvasFooter.Text = 'Total Handovers Evolution: Tracks the aggregated total number of handover events performed.';
            case 'Served Users'
                canvasFooter.Text = 'Served Users Fraction Evolution: Shows the instantaneous percentage of ground users successfully covered.';
            case 'HO Freq CDF'
                canvasFooter.Text = 'Handover Frequency CDF: Shows the statistical distribution of the handover frequency per user (HO/s).';
            case 'eMBB SE'
                canvasFooter.Text = 'eMBB Spectral Efficiency: Represents the aggregated spectral efficiency of the system (bit/s/Hz).';
            case 'eMBB TCR'
                canvasFooter.Text = 'eMBB TCR: Represents the Target Code Rate (TCR) evolution over time for the active links.';
            case 'URLLC Percentile'
                canvasFooter.Text = 'URLLC 90th Percentile Latency: Monitors the trend of the 90th percentile of packet latency.';
            case 'URLLC TCR'
                canvasFooter.Text = 'URLLC TCR: Represents the Target Code Rate (TCR) evolution over time for the active URLLC links.';
            otherwise
                canvasFooter.Text = '';
        end
    end











end


function C = atlasTheme()
    C.bg          = [0.935 0.950 0.990];
    C.card        = [1.000 1.000 1.000];
    C.cardAlt     = [0.955 0.970 0.990];
    C.canvas      = [0.965 0.982 1.000];
    C.table1      = [1.000 1.000 1.000];
    C.table2      = [0.960 0.972 0.990];

    C.rail        = [0.028 0.055 0.090];
    C.railStatusBg = [0.055 0.090 0.140];
    C.railButton  = [0.070 0.112 0.170];
    C.railLog     = [0.020 0.040 0.066];
    C.railText    = [0.930 0.960 1.000];
    C.railMuted   = [0.560 0.650 0.760];
    C.railDisabled = [0.360 0.430 0.515];

    C.text        = [0.060 0.085 0.125];
    C.muted       = [0.380 0.430 0.500];
    C.disabled    = [0.600 0.650 0.720];

    C.accent      = [0.000 0.315 0.760];
    C.accent2     = [0.020 0.560 0.820];
    C.accentRail  = [0.440 0.800 1.000];

    C.ready       = [0.060 0.580 0.320];
    C.busy        = [0.890 0.480 0.060];
    C.warnText    = [0.720 0.430 0.000];
    C.error       = [0.780 0.110 0.180];

    C.blueSoft    = [0.885 0.935 1.000];
    C.greenSoft   = [0.890 0.970 0.925];
    C.warnSoft    = [1.000 0.955 0.850];
    C.redSoft     = [1.000 0.910 0.920];
    C.neutralSoft = [0.940 0.950 0.965];

    C.grid        = [0.800 0.850 0.910];
    C.axis        = [0.500 0.560 0.640];
end

function f = preferredFont()
    fonts = listfonts;
    candidates = {'Aptos', 'Segoe UI', 'SF Pro Display', 'Helvetica Neue', 'Helvetica', 'Arial'};
    f = 'Arial';

    for k = 1:numel(candidates)
        if any(strcmpi(fonts, candidates{k}))
            f = candidates{k};
            return;
        end
    end
end

function p = atlasCard(parent, C)
    p = uipanel(parent, ...
        'BackgroundColor', C.card, ...
        'BorderType', 'none');
end

function b = railButton(parent, txt, bg, fg, fontName)
    b = uibutton(parent, ...
        'Text', txt, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', bg, ...
        'FontColor', fg);
end

function b = flatButton(parent, txt, bg, fg, fontName)
    b = uibutton(parent, ...
        'Text', txt, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', bg, ...
        'FontColor', fg);
end

function lab = railStatus(parent, txt, C, fontName)
    lab = uilabel(parent, ...
        'Text', txt, ...
        'FontName', fontName, ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', C.railStatusBg, ...
        'FontColor', C.railMuted);
end

function railDivider(parent, C, fontName, txt)
    uilabel(parent, ...
        'Text', txt, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'FontColor', C.railMuted, ...
        'BackgroundColor', C.rail, ...
        'HorizontalAlignment', 'left');
end

function field = railInputRowText(parent, labelText, value, C, fontName)
    g = uigridlayout(parent, [1 2]);
    g.ColumnWidth = {118, '1x'};
    g.ColumnSpacing = 6;
    g.Padding = [0 0 0 0];
    g.BackgroundColor = C.rail;

    uilabel(g, ...
        'Text', labelText, ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontColor', C.railMuted, ...
        'BackgroundColor', C.railStatusBg, ...
        'HorizontalAlignment', 'center');

    field = uieditfield(g, 'text', ...
        'Value', value, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontColor', C.railText, ...
        'BackgroundColor', C.railButton);
end

function field = railInputRowNumeric(parent, labelText, value, C, fontName)
    g = uigridlayout(parent, [1 2]);
    g.ColumnWidth = {118, '1x'};
    g.ColumnSpacing = 6;
    g.Padding = [0 0 0 0];
    g.BackgroundColor = C.rail;

    uilabel(g, ...
        'Text', labelText, ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontColor', C.railMuted, ...
        'BackgroundColor', C.railStatusBg, ...
        'HorizontalAlignment', 'center');

    field = uieditfield(g, 'numeric', ...
        'Value', value, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontColor', C.railText, ...
        'BackgroundColor', C.railButton);
end

function drop = railInputRowDrop(parent, labelText, items, value, C, fontName)
    g = uigridlayout(parent, [1 2]);
    g.ColumnWidth = {118, '1x'};
    g.ColumnSpacing = 6;
    g.Padding = [0 0 0 0];
    g.BackgroundColor = C.rail;

    uilabel(g, ...
        'Text', labelText, ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontColor', C.railMuted, ...
        'BackgroundColor', C.railStatusBg, ...
        'HorizontalAlignment', 'center');

    drop = uidropdown(g, ...
        'Items', items, ...
        'Value', value, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontColor', C.railText, ...
        'BackgroundColor', C.railButton);
end

function panelTitle(parent, txt, C, fontName)
    uilabel(parent, ...
        'Text', txt, ...
        'FontName', fontName, ...
        'FontSize', 13, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.card);
end

function panelCaption(parent, txt, C, fontName)
    uilabel(parent, ...
        'Text', txt, ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.card);
end

function field = inputRowNumeric(parent, labelText, value, C, fontName)
    g = uigridlayout(parent, [1 2]);
    g.ColumnWidth = {150, '1x'};
    g.ColumnSpacing = 0;
    g.Padding = [0 0 0 0];
    g.BackgroundColor = C.card;

    uilabel(g, ...
        'Text', labelText, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.cardAlt, ...
        'HorizontalAlignment', 'center');

    field = uieditfield(g, 'numeric', ...
        'Value', value, ...
        'FontName', fontName, ...
        'FontSize', 12, ...
        'FontColor', C.text, ...
        'BackgroundColor', C.card);
end

function drop = inputRowDrop(parent, labelText, items, value, C, fontName)
    g = uigridlayout(parent, [1 2]);
    g.ColumnWidth = {150, '1x'};
    g.ColumnSpacing = 0;
    g.Padding = [0 0 0 0];
    g.BackgroundColor = C.card;

    uilabel(g, ...
        'Text', labelText, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.cardAlt, ...
        'HorizontalAlignment', 'center');

    drop = uidropdown(g, ...
        'Items', items, ...
        'Value', value, ...
        'FontName', fontName, ...
        'FontSize', 12, ...
        'FontColor', C.text, ...
        'BackgroundColor', C.card);
end

function H = ribbonBadge(parent, title, value, bg, fg, C, fontName)
    b = uibutton(parent, 'push', ...
        'Text', composeActionText(title, value), ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', bg, ...
        'FontColor', fg);

    H.Button = b;
    H.Title = title;
    H.Value = value;
end

function setRibbonBadge(H, title, value, bg, fg)
    H.Button.Text = composeActionText(title, value);
    H.Button.BackgroundColor = bg;
    H.Button.FontColor = fg;
end

function txt = composeActionText(title, value)
    txt = sprintf('%s\n%s', upper(char(string(title))), upper(char(string(value))));
end

function enableAction(H, enabled)
    if enabled
        H.Button.Enable = 'on';
    else
        H.Button.Enable = 'off';
    end
end

function H = runtimeBar(parent, C, fontName)
    p = uipanel(parent, 'BackgroundColor', [1 1 1], 'BorderType', 'none');

    g = uigridlayout(p, [2 2]);
    g.RowHeight = {16, 26};
    g.ColumnWidth = {'1x', 55};
    g.Padding = [12 8 12 8];
    g.RowSpacing = 4;
    g.ColumnSpacing = 10;
    g.BackgroundColor = [1 1 1];

    titleLbl = uilabel(g, 'Text', 'RUN TIME / ELAPSED', 'FontName', fontName, ...
        'FontSize', 10, 'FontWeight', 'bold', 'FontColor', C.muted, ...
        'BackgroundColor', [1 1 1], 'HorizontalAlignment', 'left');
    titleLbl.Layout.Row = 1;
    titleLbl.Layout.Column = [1 2];

    trackBox = uipanel(g, 'BackgroundColor', [0.9 0.92 0.95], 'BorderType', 'none');
    trackBox.Layout.Row = 2;
    trackBox.Layout.Column = 1;

    trackGrid = uigridlayout(trackBox, [1 2]);
    trackGrid.Padding = [0 0 0 0];
    trackGrid.ColumnSpacing = 0;
    trackGrid.RowHeight = {'1x'};
    trackGrid.ColumnWidth = {0, '1x'};
    trackGrid.BackgroundColor = [0.9 0.92 0.95];

    fillBar = uipanel(trackGrid, 'BackgroundColor', C.busy, 'BorderType', 'none');
    fillBar.Layout.Row = 1;
    fillBar.Layout.Column = 1;

    valueLbl = uilabel(g, 'Text', '00:00', 'FontName', fontName, ...
        'FontSize', 16, 'FontWeight', 'bold', 'FontColor', C.muted, ...
        'BackgroundColor', [1 1 1], 'HorizontalAlignment', 'right');
    valueLbl.Layout.Row = 2;
    valueLbl.Layout.Column = 2;

    H.Panel = p;
    H.Grid = g;
    H.Title = titleLbl;
    H.TrackBox = trackBox;
    H.TrackGrid = trackGrid;
    H.FillBar = fillBar;
    H.Value = valueLbl;
end

function setRuntimeBar(H, fraction, elapsedText, fillColor, C)
    H.Value.Text = elapsedText;

    bgIdle  = [1 1 1];
    bgBusy  = [1.000 0.950 0.880];
    bgReady = C.greenSoft;
    bgError = C.redSoft;

    if isequal(fillColor, C.ready)
        bg = bgReady;
    elseif isequal(fillColor, C.error)
        bg = bgError;
    elseif isequal(fillColor, C.railMuted)
        bg = bgIdle;
    else
        bg = bgBusy;
    end

    fraction = max(0, min(1, fraction));

    if isequal(fillColor, C.railMuted)
        H.TrackGrid.ColumnWidth = {0, '1x'};
        H.Value.FontColor = C.muted;
        H.Title.FontColor = C.muted;
    else
        if isequal(fillColor, C.busy) && fraction < 0.02
            fraction = 0.02;
        end

        H.FillBar.BackgroundColor = fillColor;
        H.Value.FontColor = fillColor;
        H.Title.FontColor = C.muted;

        w1 = round(fraction * 1000);
        w2 = 1000 - w1;

        if w1 == 0
            H.TrackGrid.ColumnWidth = {0, '1x'};
        elseif w2 == 0
            H.TrackGrid.ColumnWidth = {'1x', 0};
        else
            H.TrackGrid.ColumnWidth = {sprintf('%dx', w1), sprintf('%dx', w2)};
        end
    end

    H.Panel.BackgroundColor = bg;
    H.Grid.BackgroundColor = bg;
    H.Title.BackgroundColor = bg;
    H.Value.BackgroundColor = bg;
end
function M = metricStrip(parent, titleText, valueText, subtitleText, C, fontName)
    p = uipanel(parent, ...
        'BackgroundColor', C.cardAlt, ...
        'BorderType', 'none');

    g = uigridlayout(p, [3 1]);
    g.RowHeight = {18, 28, 18};
    g.Padding = [14 8 14 8];
    g.RowSpacing = 0;
    g.BackgroundColor = C.cardAlt;

    title = uilabel(g, ...
        'Text', upper(titleText), ...
        'FontName', fontName, ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'FontColor', C.accent, ...
        'BackgroundColor', C.cardAlt);

    value = uilabel(g, ...
        'Text', valueText, ...
        'FontName', fontName, ...
        'FontSize', 19, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.cardAlt);

    sub = uilabel(g, ...
        'Text', subtitleText, ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.cardAlt);

    M.Panel = p;
    M.Title = title;
    M.Value = value;
    M.Subtitle = sub;
end

function H = workflowTile(parent, num, label, state, C, fontName)
    p = uipanel(parent, ...
        'BackgroundColor', C.cardAlt, ...
        'BorderType', 'none');

    g = uigridlayout(p, [2 2]);
    g.RowHeight = {34, 24};
    g.ColumnWidth = {56, '1x'};
    g.Padding = [12 10 12 10];
    g.RowSpacing = 0;
    g.BackgroundColor = C.cardAlt;

    n = uilabel(g, ...
        'Text', num, ...
        'FontName', fontName, ...
        'FontSize', 19, ...
        'FontWeight', 'bold', ...
        'FontColor', C.accent, ...
        'BackgroundColor', C.cardAlt);
    n.Layout.Row = [1 2];
    n.Layout.Column = 1;

    l = uilabel(g, ...
        'Text', label, ...
        'FontName', fontName, ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.cardAlt);
    l.Layout.Row = 1;
    l.Layout.Column = 2;

    s = uilabel(g, ...
        'Text', upper(state), ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.cardAlt);
    s.Layout.Row = 2;
    s.Layout.Column = 2;

    H.Panel = p;
    H.Num = n;
    H.Label = l;
    H.State = s;

    H = setWorkflowTile(H, num, label, state, C);
end

function H = setWorkflowTile(H, num, label, state, C)
    H.Num.Text = num;
    H.Label.Text = label;
    H.State.Text = upper(state);

    switch lower(state)
        case 'done'
            H.Panel.BackgroundColor = C.greenSoft;
            H.Num.FontColor = C.ready;
            H.State.FontColor = C.ready;
        case 'ready'
            H.Panel.BackgroundColor = C.blueSoft;
            H.Num.FontColor = C.accent;
            H.State.FontColor = C.accent;
        case 'stale'
            H.Panel.BackgroundColor = C.warnSoft;
            H.Num.FontColor = C.warnText;
            H.State.FontColor = C.warnText;
        case 'locked'
            H.Panel.BackgroundColor = C.neutralSoft;
            H.Num.FontColor = C.disabled;
            H.State.FontColor = C.disabled;
        otherwise
            H.Panel.BackgroundColor = C.cardAlt;
            H.Num.FontColor = C.accent;
            H.State.FontColor = C.muted;
    end

    H.Label.BackgroundColor = H.Panel.BackgroundColor;
    H.Num.BackgroundColor = H.Panel.BackgroundColor;
    H.State.BackgroundColor = H.Panel.BackgroundColor;
end

function enableButton(btn, enabled, C, style)
    if enabled
        btn.Enable = 'on';
        switch style
            case 'railAccent'
                btn.BackgroundColor = C.accentRail;
                btn.FontColor = C.rail;
            case 'rail'
                btn.BackgroundColor = C.railButton;
                btn.FontColor = C.railText;
            otherwise
                btn.BackgroundColor = C.blueSoft;
                btn.FontColor = C.accent;
        end
    else
        btn.Enable = 'off';
        switch style
            case {'railAccent', 'rail'}
                btn.BackgroundColor = C.railButton;
                btn.FontColor = C.railDisabled;
            otherwise
                btn.BackgroundColor = C.cardAlt;
                btn.FontColor = C.disabled;
        end
    end
end

function clearAtlasMap(ax, C)
    cla(ax);
    ax.Visible = 'off';
    ax.Color = C.card;
    ax.XTick = [];
    ax.YTick = [];
    ax.XTickLabel = [];
    ax.YTickLabel = [];
    ax.Box = 'off';
    grid(ax, 'off');
    xlabel(ax, '');
    ylabel(ax, '');
end


function data = referenceSetupData(params)
    if isempty(params)
        data = { ...
            'CONST', 'Planes',            '72',      '-'; ...
            'CONST', 'Sats/plane',       '22',      '-'; ...
            'CONST', 'Altitude',         '540',     'km'; ...
            'CONST', 'Inclination',      '53.2',    'deg'; ...
            'CONST', 'Phasing',          '17',      '-'; ...
            'AOI',   'Lat range',        '35..60',  'deg'; ...
            'AOI',   'Lon range',        '-10..30', 'deg'; ...
            'AOI',   'Grid step',        '2 x 2',   'deg'; ...
            'RADIO', 'Carrier',          '2',       'GHz'; ...
            'RADIO', 'Bandwidth',        '5',       'MHz'; ...
            'RADIO', 'Sat power',        '1',       'W'; ...
            'RADIO', 'Sat gain',         '50',      'dBi'; ...
            'RADIO', 'User gain',        '0',       'dBi'; ...
            'RADIO', 'System temp.',     '290',     'K'; ...
            'RADIO', 'Min elevation',    '25',      'deg'; ...
            'RUN',   'Terminals',        '--',      '-'; ...
            'RUN',   'CSI',              '--',      '-'; ...
            'RUN',   'Policy',           '--',      '-'; ...
            'RUN',   'Seed',             '--',      '-'};
        return;
    end

    data = { ...
        'CONST', 'Planes',            num2str(params.constellation.planes),              '-'; ...
        'CONST', 'Sats/plane',       num2str(params.constellation.satellitesPerPlane),  '-'; ...
        'CONST', 'Altitude',         num2str(params.constellation.altitude_km),         'km'; ...
        'CONST', 'Inclination',      num2str(params.constellation.inclination_deg),     'deg'; ...
        'CONST', 'Phasing',          num2str(params.constellation.phasingParam),        '-'; ...
        'AOI',   'Lat range',        sprintf('%g..%g', params.AoI.latMin, params.AoI.latMax),  'deg'; ...
        'AOI',   'Lon range',        sprintf('%g..%g', params.AoI.lonMin, params.AoI.lonMax),  'deg'; ...
        'AOI',   'Grid step',        sprintf('%g x %g', params.AoI.deltaLat, params.AoI.deltaLon), 'deg'; ...
        'RADIO', 'Carrier',          sprintf('%.6g', params.channel.carrierFrequency_Hz/1e9), 'GHz'; ...
        'RADIO', 'Bandwidth',        sprintf('%.6g', params.channel.bandwidth_Hz/1e6),        'MHz'; ...
        'RADIO', 'Sat power',        sprintf('%.6g', params.channel.satellitePower_W),        'W'; ...
        'RADIO', 'Sat gain',         sprintf('%.6g', params.channel.satelliteGain_dBi),       'dBi'; ...
        'RADIO', 'User gain',        sprintf('%.6g', params.channel.userGain_dBi),            'dBi'; ...
        'RADIO', 'System temp.',     sprintf('%.6g', params.channel.systemTemperature_K),     'K'; ...
        'RADIO', 'Min elevation',    sprintf('%.6g', params.minimumElevation_deg),            'deg'; ...
        'RUN',   'Terminals',        num2str(params.numUsers),                                '-'; ...
        'RUN',   'CSI',              char(string(params.CSImode)),                            '-'; ...
        'RUN',   'Policy',           char(string(params.associationAlgorithm)),                '-'; ...
        'RUN',   'Seed',             num2str(params.seed),                                    '-'};

    switch string(params.associationAlgorithm)
        case "URLLC"
            data = [data; { ...
                'URLLC', 'Δ latency HO',   sprintf('%.3g', params.policy.URLLC.URLLC_DeltaTau_switch_s), 's'; ...
                'URLLC', 'Max latency',    sprintf('%.3g', params.policy.URLLC.latency_max_URLLC),       's'; ...
                'URLLC', 'Min SNR',        sprintf('%.6g', params.policy.URLLC.SNRmin_URLLC_lin),        'linear'; ...
                'URLLC', 'Time window',    num2str(params.policy.URLLC.time_window),                    'samples'; ...
                'URLLC', 'Max HO',         num2str(params.policy.URLLC.handoverMax_URLLC),              '-'}];

        case "eMBB"
            data = [data; { ...
                'eMBB',  'Δ rate HO',      sprintf('%.6g', params.policy.eMBB.eMBB_DeltaR_switch_bps),  'bit/s'; ...
                'eMBB',  'Min rate',       sprintf('%.6g', params.policy.eMBB.rateMin_eMBB_bps),        'bit/s'; ...
                'eMBB',  'Time window',    num2str(params.policy.eMBB.time_window),                    'samples'; ...
                'eMBB',  'Max HO',         num2str(params.policy.eMBB.handoverMax_eMBB),               '-'}];
    end
end

function data = kpiTableData(RESULTS, params)
    rows = {'Metric', 'Value', 'Unit'};

    if isempty(RESULTS) || ~isfield(RESULTS, 'KPI_results')
        rows(end+1,:) = {'Avg User SNR', '-', 'dB'};
        rows(end+1,:) = {'Avg User Rate', '-', 'Mbps'};
        rows(end+1,:) = {'Avg User Spectral Efficiency', '-', 'b/s/Hz'};
        rows(end+1,:) = {'Mean Total Handovers', '-', 'HO/step'};

        if ~isempty(params) && isfield(params, 'associationAlgorithm')
            if strcmpi(string(params.associationAlgorithm), 'eMBB')
                rows(end+1,:) = {'Mean eMBB TCR', '-', '%'};
            elseif strcmpi(string(params.associationAlgorithm), 'URLLC')
                rows(end+1,:) = {'URLLC 90th Percentile', '-', 'ms'};
                rows(end+1,:) = {'Mean URLLC TCR', '-', '%'};
            end
        end
    else
        K = RESULTS.KPI_results;
        if ~isfield(K, 'generalKPIs')
            rows(end+1,:) = {'generalKPIs not found', '-', '-'};
        else
            G = K.generalKPIs;
            has_data = false;

            if isfield(G, 'SNR') && isfield(G.SNR, 'globalAvgUserSNR_dB')
                v = G.SNR.globalAvgUserSNR_dB;
                if isnumeric(v) && isscalar(v)
                    rows(end+1,:) = {'Avg User SNR', sprintf('%.2f', v), 'dB'};
                    has_data = true;
                end
            end

            if isfield(G, 'throughput') && isfield(G.throughput, 'globalAvgUserRate_Mbps')
                v = G.throughput.globalAvgUserRate_Mbps;
                if isnumeric(v) && isscalar(v)
                    rows(end+1,:) = {'Avg User Rate', sprintf('%.3f', v), 'Mbps'};
                    has_data = true;
                end
            end

            if isfield(G, 'throughput') && isfield(G.throughput, 'globalAvgUserRate_bpsHz')
                v = G.throughput.globalAvgUserRate_bpsHz;
                if isnumeric(v) && isscalar(v)
                    rows(end+1,:) = {'Avg User Spectral Efficiency', sprintf('%.4f', v), 'b/s/Hz'};
                    has_data = true;
                end
            end

            if isfield(G, 'serviceContinuity') && isfield(G.serviceContinuity, 'userHandoverTime')
                totalHO = sum(G.serviceContinuity.userHandoverTime, 1);
                v = mean(totalHO);
                rows(end+1,:) = {'Mean Total Handovers', sprintf('%.2f', v), 'HO/step'};
                has_data = true;
            end

            if ~isempty(params) && isfield(params, 'associationAlgorithm') && strcmpi(string(params.associationAlgorithm), 'eMBB')
                if isfield(K, 'specificeMBB') && isfield(K.specificeMBB, 'TCR_eMBB')
                    v = mean(K.specificeMBB.TCR_eMBB, 'omitnan') * 100;
                    rows(end+1,:) = {'Mean eMBB TCR', sprintf('%.2f', v), '%'};
                    has_data = true;
                end
            end

               if ~isempty(params) && isfield(params, 'associationAlgorithm') && ...
               strcmpi(string(params.associationAlgorithm), 'URLLC')

                if isfield(K, 'specificURLLC') && isfield(K.specificURLLC, 'PL_URLLC_global')
                    v = K.specificURLLC.PL_URLLC_global;
                    if isnumeric(v) && isscalar(v)
                        rows(end+1,:) = {'URLLC 90th Percentile', sprintf('%.4f', v), 'ms'};
                        has_data = true;
                    end
                end

                if isfield(K, 'specificURLLC') && isfield(K.specificURLLC, 'TCR_URLLC')
                    v = mean(K.specificURLLC.TCR_URLLC, 'omitnan') * 100;
                    rows(end+1,:) = {'Mean URLLC TCR', sprintf('%.2f', v), '%'};
                    has_data = true;
                end
            end

            if ~has_data
                rows(end+1,:) = {'No valid KPI fields', '-', '-'};
            end
        end
    end

    righe_totali = size(rows, 1);
    if righe_totali < 11
        righe_vuote = cell(11 - righe_totali, 3);
        righe_vuote(:) = {''};
        rows = [rows; righe_vuote];
    end

    data = rows;
end

function data = serviceComplianceData(RESULTS, params)
    if isempty(params)
        data = {'Policy', '--', '--', 'waiting'};
        return;
    end

    if isempty(RESULTS) || ~isfield(RESULTS, 'KPI_results')
        switch string(params.associationAlgorithm)
            case "URLLC"
                data = { ...
                    'Latency', sprintf('%.3g s', params.policy.URLLC.latency_max_URLLC), '--', 'pending'; ...
                    'SNR',     sprintf('%.6g lin', params.policy.URLLC.SNRmin_URLLC_lin), '--', 'pending'; ...
                    'Handovers', sprintf('<= %d', params.policy.URLLC.handoverMax_URLLC), '--', 'pending'};
            case "eMBB"
                data = { ...
                    'Rate', sprintf('%.6g bit/s', params.policy.eMBB.rateMin_eMBB_bps), '--', 'pending'; ...
                    'Handovers', sprintf('<= %d', params.policy.eMBB.handoverMax_eMBB), '--', 'pending'};
            otherwise
                data = {'Policy', '--', '--', 'pending'};
        end
        return;
    end

    S = RESULTS.KPI_results;
    flat = flattenStruct(S);

    switch string(params.associationAlgorithm)
        case "URLLC"
            data = { ...
                'Latency', sprintf('%.3g s', params.policy.URLLC.latency_max_URLLC), inferMetric(flat, ["latency","delay"], "not found"), inferStatus(flat, ["latency","delay"], params.policy.URLLC.latency_max_URLLC, "max"); ...
                'SNR', sprintf('%.6g lin', params.policy.URLLC.SNRmin_URLLC_lin), inferMetric(flat, ["snr"], "not found"), inferStatus(flat, ["snr"], params.policy.URLLC.SNRmin_URLLC_lin, "min"); ...
                'Handovers', sprintf('<= %d', params.policy.URLLC.handoverMax_URLLC), inferMetric(flat, ["handover","HO"], "not found"), inferStatus(flat, ["handover","HO"], params.policy.URLLC.handoverMax_URLLC, "max")};

        case "eMBB"
            data = { ...
                'Rate', sprintf('%.6g bit/s', params.policy.eMBB.rateMin_eMBB_bps), inferMetric(flat, ["rate","throughput"], "not found"), inferStatus(flat, ["rate","throughput"], params.policy.eMBB.rateMin_eMBB_bps, "min"); ...
                'Handovers', sprintf('<= %d', params.policy.eMBB.handoverMax_eMBB), inferMetric(flat, ["handover","HO"], "not found"), inferStatus(flat, ["handover","HO"], params.policy.eMBB.handoverMax_eMBB, "max")};

        otherwise
            data = {'Policy', '--', '--', 'unknown'};
    end
end

function data = violationsPanelData(RESULTS, params)
    if isempty(params)
        data = {'No run', '-', 'waiting'};
        return;
    end

    if isempty(RESULTS) || ~isfield(RESULTS, 'KPI_results')
        data = {'No association run', '-', 'pending'};
        return;
    end

    S = RESULTS.KPI_results;
    flat = flattenStruct(S);

    rows = {};

    switch string(params.associationAlgorithm)
        case "URLLC"
            rows = [rows; violationRow(flat, ["latency","delay"], params.policy.URLLC.latency_max_URLLC, "max", "Latency target")];
            rows = [rows; violationRow(flat, ["snr"], params.policy.URLLC.SNRmin_URLLC_lin, "min", "SNR target")];
            rows = [rows; violationRow(flat, ["handover","HO"], params.policy.URLLC.handoverMax_URLLC, "max", "Handover limit")];
        case "eMBB"
            rows = [rows; violationRow(flat, ["rate","throughput"], params.policy.eMBB.rateMin_eMBB_bps, "min", "Rate target")];
            rows = [rows; violationRow(flat, ["handover","HO"], params.policy.eMBB.handoverMax_eMBB, "max", "Handover limit")];
    end

    if isempty(rows)
        data = {'No checks available', '-', 'unknown'};
    else
        data = rows;
    end
end

function row = violationRow(flat, keys, threshold, direction, label)
    [value, found] = findNumericMetric(flat, keys);

    if ~found
        row = {char(string(label)), 'n/a', 'unknown'};
        return;
    end

    if direction == "max"
        violated = value > threshold;
        margin = value - threshold;
    else
        violated = value < threshold;
        margin = threshold - value;
    end

    if violated
        severity = 'violation';
        countTxt = sprintf('%.6g', margin);
    else
        severity = 'none';
        countTxt = '0';
    end

    row = {char(string(label)), char(string(countTxt)), char(string(severity))};
end

function status = inferStatus(flat, keys, threshold, direction)
    [value, found] = findNumericMetric(flat, keys);

    if ~found
        status = 'unknown';
        return;
    end

    if direction == "max"
        ok = value <= threshold;
    else
        ok = value >= threshold;
    end

    if ok
        status = 'ok';
    else
        status = 'violated';
    end
end

function txt = inferMetric(flat, keys, fallback)
    [value, found] = findNumericMetric(flat, keys);
    if found
        txt = valueToText(value);
    else
        txt = char(string(fallback));
    end
end

function [value, found] = findNumericMetric(flat, keys)
    value = [];
    found = false;

    if isempty(flat)
        return;
    end

    names = string(flat(:,1));
    values = flat(:,2);

    score = zeros(size(names));

    for k = 1:numel(keys)
        key = lower(string(keys(k)));
        score = score + contains(lower(names), key);
    end

    idx = find(score > 0, 1, 'last');

    if isempty(idx)
        return;
    end

    candidate = values{idx};

    if isnumeric(candidate)
        if isscalar(candidate)
            value = candidate;
        else
            value = mean(candidate(:), 'omitnan');
        end
        found = true;
    elseif islogical(candidate)
        value = double(candidate);
        found = true;
    end
end

function flat = flattenStruct(S)
    flat = {};
    recurse("", S);

    function recurse(prefix, value)
        if isstruct(value)
            names = fieldnames(value);
            for i = 1:numel(names)
                if prefix == ""
                    nextName = string(names{i});
                else
                    nextName = prefix + "." + string(names{i});
                end
                recurse(nextName, value.(names{i}));
            end
        else
            flat(end+1, :) = {char(prefix), value};
        end
    end
end


function txt = valueToText(value)
    if isnumeric(value)
        if isscalar(value)
            txt = sprintf('%.6g', value);
        else
            sz = size(value);
            txt = sprintf('[%s] numeric', char(strjoin(string(sz), ' x ')));
        end
    elseif isstring(value) || ischar(value)
        txt = char(string(value));
    elseif islogical(value)
        txt = char(string(value));
    elseif istable(value)
        txt = sprintf('table %d x %d', height(value), width(value));
    elseif isstruct(value)
        txt = sprintf('struct with %d fields', numel(fieldnames(value)));
    else
        txt = class(value);
    end
end

function lines = structToLines(S)
    try
        txt = evalc('disp(S)');
        lines = splitlines(string(txt));
        lines = cellstr(lines);
        lines = lines(~cellfun(@isempty, lines));

        if isempty(lines)
            lines = {'KPI object empty'};
        end
    catch
        lines = {'Cannot display KPI object'};
    end
end

function d = modalWindow(name, C, position)
    d = uifigure( ...
        'Name', name, ...
        'Position', position, ...
        'Color', C.bg, ...
        'WindowStyle', 'modal');
end

function modalHeader(parent, titleText, subText, infoText, C, fontName)
    g = uigridlayout(parent, [2 2]);
    g.Layout.Row = 1;
    g.Layout.Column = [1 2];
    g.RowHeight = {30, 18};
    g.ColumnWidth = {'1x', 30};
    g.Padding = [0 0 0 0];
    g.RowSpacing = 0;
    g.BackgroundColor = C.bg;

    tit = uilabel(g, ...
        'Text', titleText, ...
        'FontName', fontName, ...
        'FontSize', 22, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.bg);
    tit.Layout.Row = 1;
    tit.Layout.Column = 1;

    sub = uilabel(g, ...
        'Text', subText, ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.bg);
    sub.Layout.Row = 2;
    sub.Layout.Column = [1 2];

    btn = uibutton(g, ...
        'Text', '?', ...
        'Tooltip', infoText, ...
        'FontName', fontName, ...
        'FontSize', 16, ...
        'FontWeight', 'bold', ...
        'FontColor', C.accent, ...
        'BackgroundColor', C.bg);
    btn.Layout.Row = 1;
    btn.Layout.Column = 2;
end


function modalSectionLabel(parent, txt, C, fontName)
    lbl = uilabel(parent, ...
        'Text', txt, ...
        'FontName', fontName, ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'FontColor', C.accent, ...
        'VerticalAlignment', 'bottom',...
        'BackgroundColor', C.bg);
    lbl.Layout.Column = [1 2];
end






function field = modalNumeric(parent, label, value, C, fontName)
    uilabel(parent, ...
        'Text', label, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontColor', C.text, ...
        'BackgroundColor', C.bg);

    field = uieditfield(parent, 'numeric', ...
        'Value', value, ...
        'BackgroundColor', C.card, ...
        'FontColor', C.text, ...
        'FontName', fontName, ...
        'FontSize', 11);
end

function spacer(parent, color, fontName)
    uilabel(parent, 'Text', '', 'BackgroundColor', color, 'FontName', fontName);
end

function tryStyleTable(tbl, C)
    try
        s1 = uistyle('BackgroundColor', C.table1, 'FontColor', C.text);
        s2 = uistyle('BackgroundColor', C.table2, 'FontColor', C.text);
        addStyle(tbl, s1, 'row', 1:2:200);
        addStyle(tbl, s2, 'row', 2:2:200);
    catch
    end
end

function out = ternary(condition, a, b)
    if condition
        out = a;
    else
        out = b;
    end
end
