function NAPOLEON_GUI_v0()
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

    close all;

    %% Paths
    guiDir = fileparts(mfilename('fullpath'));
    srcDir = fileparts(guiDir);

    addpath(srcDir);
    addpath(genpath(fullfile(srcDir, 'ChannelModel')));
    addpath(genpath(fullfile(srcDir, 'UserSatAssoc')));
    addpath(genpath(fullfile(srcDir, 'KPIs')));
    addpath(fullfile(srcDir, 'GUI'));

    %% State
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

    %% Theme
    C = atlasTheme();
    fontName = preferredFont();

    %% Figure
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

    %% LEFT COMMAND RAIL
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
    'RowName', [], ... % FONDAMENTALE: [] elimina del tutto la colonna invisibile a sinistra
    'ColumnWidth', {60, '1x', 70, 40}, ... % '1x' fa riempire lo spazio esattamente, niente slider orizzontale!
    'FontName', fontName, ...
    'FontSize', 10, ... % Leggermente ingrandito per una lettura più chiara
    'BackgroundColor', [C.railStatusBg; C.railButton], ...
    'ForegroundColor', C.railText, ...
    'ColumnSortable', [false false false false]); % Rimuove le frecce di ordinamento dalle intestazioni

    % STILIZZAZIONE AVANZATA (uistyle) PER ALLINEAMENTI ELEGANTI
    try
        % 1. Grassetto per la colonna "Group" (opzionale, ma aiuta la leggibilità)
        styleGroup = uistyle('FontWeight', 'bold');
        addStyle(setupTable, styleGroup, 'column', 1);
    
        % 2. Allineamento centrato per "Value" e "Unit"
        styleCenter = uistyle('HorizontalAlignment', 'center');
        addStyle(setupTable, styleCenter, 'column', [3 4]);
    catch
        % Fallback per versioni di MATLAB precedenti che non supportano uistyle
    end

    railDivider(railGrid, C, fontName, 'PARAMETER SETUP');

  % --- CONTENITORE PER INPUT E BOTTONI (STESSA LARGHEZZA TABELLA) ---
    controlsGrid = uigridlayout(railGrid, [6 1]); 
    controlsGrid.Padding = [0 0 0 0];
    controlsGrid.RowSpacing = 8;
    controlsGrid.ColumnWidth = {'1x'}; % Il segreto è qui: '1x' occupa il 100% della larghezza!
    controlsGrid.RowHeight = {36, 36, 36, 36, 36, 36, 36};
    controlsGrid.BackgroundColor = C.rail;

    % 1. Box di Input (si espandono su tutta la larghezza della barra)
    numUsersField = railInputRowText(controlsGrid, 'Terminals', '', C, fontName);
    csiDrop       = railInputRowDrop(controlsGrid, 'CSI mode', {'--', 'forecast', 'ideal'}, '--', C, fontName);
    seedField     = railInputRowText(controlsGrid, 'Seed', '', C, fontName);
    algDrop       = railInputRowDrop(controlsGrid, 'Policy', {'--', 'URLLC', 'eMBB'}, '--', C, fontName);

    % 3. Bottoni (si espandono su tutta la larghezza allineandosi alla tabella)
    tuneBtn = flatButton(controlsGrid, '⚙️ Tune Policy', C.railButton, C.accentRail, fontName);
    
    bottomButtonsGrid = uigridlayout(controlsGrid, [1 2]);
    bottomButtonsGrid.Padding = [0 0 0 0];
    bottomButtonsGrid.ColumnSpacing = 8;          % Spazio tra i due bottoni affiancati
    bottomButtonsGrid.ColumnWidth = {'1x', '1x'};  % Ogni bottone occupa esattamente il 50%
    bottomButtonsGrid.BackgroundColor = C.rail;

    % NOTA: i due bottoni ora sono figli di 'bottomButtonsGrid' invece che di 'controlsGrid'
    defaultBtn = flatButton(bottomButtonsGrid, 'Default values', C.accentRail, C.rail, fontName);
    resetWorkspaceBtn = flatButton(bottomButtonsGrid, 'Reset workspace', C.railButton, C.railText, fontName);
    
    %% MAIN WORKSPACE
    workspace = uigridlayout(root, [3 1]);
    workspace.Layout.Column = 2;
    workspace.RowHeight = {82, '1x', 112};
    workspace.Padding = [20 18 20 18];
    workspace.RowSpacing = 14;
    workspace.BackgroundColor = C.bg;

    %% TOP RIBBON
    ribbon = uipanel(workspace, ...
        'BackgroundColor', C.card, ...
        'BorderType', 'none');
    ribbon.Layout.Row = 1;

    ribGrid = uigridlayout(ribbon, [1 5]);
    ribGrid.ColumnWidth = {'1x', 110,110,110 420};
    ribGrid.Padding = [22 14 22 14];
    ribGrid.ColumnSpacing = 10;
    ribGrid.BackgroundColor = C.card;

    titleBox = uigridlayout(ribGrid, [2 1]);
    titleBox.RowHeight = {30, 22};
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

    workspaceSubtitle = uilabel(titleBox, ...
        'Text', 'Header buttons execute the workflow; the left rail summarize the configuration parameters', ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.card);

    scenarioBadge = ribbonBadge(ribGrid, 'Scenario', 'SETUP', C.neutralSoft, C.muted, C, fontName)
    assocBadge    = ribbonBadge(ribGrid, 'Association', 'LOCKED', C.neutralSoft, C.disabled, C, fontName);
    exportBadge   = ribbonBadge(ribGrid, 'Export Datas', 'LOCKED', C.neutralSoft, C.disabled, C, fontName);
    runMeter      = runtimeBar(ribGrid, C, fontName);

    %% MIDDLE CONTENT
    middle = uigridlayout(workspace, [1 2]);
    middle.Layout.Row = 2;
    middle.ColumnWidth = {'1x', 365};
    middle.ColumnSpacing = 14;
    middle.Padding = [0 0 0 0];
    middle.BackgroundColor = C.bg;

    %% CANVAS PANEL
    canvasPanel = atlasCard(middle, C);
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
        'Text', '', ...
        'FontName', fontName, ...
        'FontSize', 13, ...
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
    clearAtlasMap(ax, C);  % Startup: central workspace is empty until a real scenario is generated.

    canvasFooter = uilabel(canv, ...
        'Text', '', ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.cardAlt, ...
        'HorizontalAlignment', 'center');

%% ANALYTICS PANEL
analyticsPanel = uipanel(middle, 'BackgroundColor', C.bg, 'BorderType', 'none');
analyticsPanel.Layout.Column = 2;
analyticsPanel.Scrollable = 'on';

ana = uigridlayout(analyticsPanel, [3 1]);
ana.RowHeight = {25, 430, '1x'};
ana.Padding = [18 18 18 18];
ana.RowSpacing = 6;
ana.BackgroundColor = C.bg;

uilabel(ana, ...
    'Text', 'KPI CONTROLS', ...
    'FontName', fontName, ...
    'FontSize', 18, ...
    'FontWeight', 'bold', ...
    'FontColor', C.text, ...
    'BackgroundColor', C.bg);

kpiGrid = uigridlayout(ana, [6, 2]);
kpiGrid.Layout.Row = 2;
kpiGrid.Layout.Column = 1;
kpiGrid.RowSpacing = 8;
kpiGrid.ColumnSpacing = 8;
kpiGrid.BackgroundColor = C.bg;
kpiGrid.RowHeight = {38, 38, 38, 38, 48, 135};
kpiGrid.ColumnWidth = {'1x', '1x'};

% 8 BOTTONI
btnList = {'SNR CDF', 'Rate CDF', 'Avg Rate', 'Handover', 'KPI 5', 'KPI 6', 'KPI 7', 'KPI 8'};
kpiBtns = gobjects(1, 8);
for i = 1:8
    kpiBtns(i) = uibutton(kpiGrid, ...
        'Text', btnList{i}, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', C.neutralSoft, ...
        'FontColor', C.disabled, ...
        'Enable', 'off');
    kpiBtns(i).Layout.Row = ceil(i/2);
    kpiBtns(i).Layout.Column = mod(i-1, 2) + 1;
end

% TITOLO KPI SUMMARY
lblSummary = uilabel(kpiGrid, ...
    'Text', 'KPI SUMMARY', ...
    'FontName', fontName, ...
    'FontSize', 18, ...
    'FontWeight', 'bold', ...
    'FontColor', C.text, ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', C.bg);
lblSummary.Layout.Row = 5;
lblSummary.Layout.Column = [1 2];

% TABELLA KPI
% TABELLA KPI% TABELLA KPI
kpiTable = uitable(kpiGrid, ...
    'Data', { ...
        'Waiting for association', '-', '-'; ...
        'Total Average Rate', '-', '-'; ...
        'System Throughput', '-', '-'; ...
        'Average SNR', '-', '-'}, ...
    'ColumnName', {'Metric', 'Value', 'Unit'}, ...
    'RowName', [], ... % Rimuove i numeri di riga per un look minimal ed elegante
    'ColumnWidth', {'5x', '2x', '2x'}, ... % Proporzioni dinamiche per evitare barre di scorrimento
    'FontName', fontName, ...
    'FontSize', 12, ...
    'ColumnSortable', [false false false]);
kpiTable.Layout.Row = 6;
kpiTable.Layout.Column = [1 2];

% COPIA DINAMICA DEI COLORI DALLA TABELLA A SINISTRA E STILIZZAZIONE
try
    % 1. Trova tutte le tabelle nella figura principale
    mainFig = ancestor(kpiGrid, 'figure');
    allTables = findobj(mainFig, 'Type', 'uitable');
    
    % Escludiamo la tabella appena creata per isolare quella di sinistra
    leftTable = allTables(allTables ~= kpiTable);
    
    if ~isempty(leftTable)
        % Copia l'esatta combinazione di colori della tabella di sinistra
        kpiTable.BackgroundColor = leftTable(1).BackgroundColor;
        kpiTable.ForegroundColor = leftTable(1).ForegroundColor;
    else
        % Fallback di sicurezza se la tabella di sinistra non fosse ancora nata nel codice
        kpiTable.BackgroundColor = [1 1 1; 0.97 0.975 0.98];
        kpiTable.ForegroundColor = [0.15 0.15 0.15];
    end

    % 2. Manteniamo il layout elegante: grassetto a sinistra e valori centrati
    styleMetric = uistyle('FontWeight', 'bold');
    addStyle(kpiTable, styleMetric, 'column', 1);

    styleValues = uistyle('HorizontalAlignment', 'center');
    addStyle(kpiTable, styleValues, 'column', [2 3]);
catch
    % Fallback nel caso di versioni MATLAB molto vecchie senza supporto a uistyle
    kpiTable.BackgroundColor = [1 1 1; 0.97 0.975 0.98];
end
    %% BOTTOM CONSOLE
    consolePanel = atlasCard(workspace, C);
    consolePanel.Layout.Row = 3;

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
        'BackgroundColor', C.cardAlt, ...
        'FontColor', C.text, ...
        'FontName', fontName, ...
        'FontSize', 11, ...
        'Value', {'READY'});

    clearLogBtn = flatButton(con, 'Clear log', C.cardAlt, C.text, fontName);
    copyLogBtn  = flatButton(con, 'Copy log', C.cardAlt, C.text, fontName);

    %% CALLBACK WIRING
    scenarioBadge.Button.ButtonPushedFcn = @onGenerate;
    %viewerBadge.Button.ButtonPushedFcn = @onViewer;
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

    %% CALLBACK IMPLEMENTATION
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
                % Ripristina le caselle di testo ai vecchi valori salvati in State.params
                if ~isempty(State.params)
                    setInputFieldsFromParams(State.params);
                end
                appendLog('MODIFICA PARAMETRI ANNULLATA. SCENARIO PRESERVATO.');
                return; % Blocca l'esecuzione della funzione! Non cancella nulla.
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
        % Leggi il nuovo valore selezionato nel dropdown
        State.params = readGUI(false);
    
        % Se c'è già un'associazione completata, chiedi conferma prima di cancellarla
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
                % Ripristina il dropdown al valore precedente salvato in State.params
                if ~isempty(State.params) && isfield(State.params, 'associationAlgorithm')
                    algDrop.Value = char(string(State.params.associationAlgorithm));
                end
                appendLog('POLICY CHANGE CANCELLED — RESULTS PRESERVED.');
                return
            end
        end
    
        % L'utente ha confermato (o non c'era un'associazione): aggiorna e resetta solo i RESULTS
        State.RESULTS = [];
        State.associationCompleted = false;
        appendLog('POLICY UPDATED — SCENARIO PRESERVED, RESULTS RESET. Re-run association.');
        refreshUI('scenarioReady');   % ← lo scenario rimane valido, assocBadge → "RUN"
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

            %openSatelliteViewer();

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
            if ~State.scenarioGenerated
                uialert(fig, 'Nothing to export.', 'Export unavailable');
                return;
            end

            [file, path] = uiputfile('NAPOLEON_v3_results.mat', 'Export NAPOLEON+ results');

            if isequal(file, 0)
                appendLog('EXPORT CANCELLED');
                return;
            end

            State.lastRunStarted = datetime('now');
            State.lastRunFinished = [];
            setBusy(true, 'EXPORTING');
            appendLog('EXPORT STARTED');

            params = State.params;
            SCENARIO = State.SCENARIO;
            RESULTS = State.RESULTS;

            save(fullfile(path, file), 'params', 'SCENARIO', 'RESULTS', '-v7.3');

            State.lastRunFinished = datetime('now');
            appendLog(['EXPORTED: ', fullfile(path, file)]);
            refreshUI('exported');

        catch ME
            handleError(ME, true);
        end

        setBusy(false, 'READY');
    end

    function onDefaultValues(~, ~)
        params = State.defaultParams;
        setInputFieldsFromParams(params);
        State.params = params;
        clearSimulationWorkspace(false);
        kpiTable.Data = {'No KPI data', '-'};
        complianceTable.Data = serviceComplianceData([], params);
        violationsTable.Data = violationsPanelData([], params);
        appendLog('DEFAULT PARAMETERS LOADED');
        refreshUI('initial');
    end

    function onResetWorkspace(~, ~)
        setInputFieldsEmpty();
        State.params = [];
        clearSimulationWorkspace(false);
        kpiTable.Data = {'No KPI data', '-'};
        complianceTable.Data = serviceComplianceData([], []);
        violationsTable.Data = violationsPanelData([], []);
        logBox.Value = {'READY'};
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

    %% INTERNAL HELPERS
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
            missing{end+1} = 'Terminals'; %#ok<AGROW>
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
            missing{end+1} = 'CSI mode'; %#ok<AGROW>
            isComplete = false;
        else
            params.CSImode = csiValue;
        end

        if algValue == "--"
            missing{end+1} = 'Policy'; %#ok<AGROW>
            isComplete = false;
        else
            params.associationAlgorithm = algValue;
        end

        if seedTxt == ""
            missing{end+1} = 'Seed'; %#ok<AGROW>
            isComplete = false;
        else
            seedValue = str2double(seedTxt);
            if isnan(seedValue) || ~isfinite(seedValue)
                isComplete = false;
                if requireComplete
                    error('Seed must be a numeric value.');
                end
            else
                params.seed = round(seedValue);  % ← SPOSTARE QUI
            end
        end

        % Controllo finale (non distrugge più la variabile params!)
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
        canvasTitleLabel.Text = '';
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

            enableAction(scenarioBadge, false);
            %enableAction(viewerBadge, false);
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
            setRailStatus('RESULTS READY', C.ready, C);
            setRibbonBadge(scenarioBadge, 'Scenario', 'READY', C.greenSoft, C.ready);
            %setRibbonBadge(viewerBadge, 'Viewer', 'OPEN', C.blueSoft, C.accent);
            setRibbonBadge(assocBadge, 'Association', 'DONE', C.greenSoft, C.ready);
            setRibbonBadge(exportBadge, 'Export', 'READY', C.blueSoft, C.accent);

            enableAction(scenarioBadge, true);
            %enableAction(viewerBadge, true);
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
            
            for i = 1:numel(kpiBtns)
                kpiBtns(i).Enable = 'on';
                kpiBtns(i).BackgroundColor = C.blueSoft;
                kpiBtns(i).FontColor = C.accent;
            end
            canvasTitleLabel.Text = '3D user distribution in AoI';
            canvasSubtitle.Text = 'Actual terminal positions extracted from SCENARIO.satelliteScenario.GroundStations.';
            drawScenarioDistribution(ax, State.scenarioPlotData, C, 'association');
            canvasFooter.Text = scenarioDistributionFooter(State.scenarioPlotData, State.params);

        elseif State.scenarioGenerated
            setRailStatus('SCENARIO READY', C.ready, C);
            setRibbonBadge(scenarioBadge, 'Scenario', 'READY', C.greenSoft, C.ready);
            %setRibbonBadge(viewerBadge, 'Viewer', 'OPEN', C.blueSoft, C.accent);
            setRibbonBadge(assocBadge, 'Association', 'RUN', C.blueSoft, C.accent);
            setRibbonBadge(exportBadge, 'Export', 'LOCKED', C.neutralSoft, C.disabled);

            enableAction(scenarioBadge, true);
            %enableAction(viewerBadge, true);
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
            kpiTable.Data = {'No KPI data', '-'};
            
            for i = 1:numel(kpiBtns)
                kpiBtns(i).Enable = 'off';
                kpiBtns(i).BackgroundColor = C.neutralSoft;
                kpiBtns(i).FontColor = C.disabled;
            end
            canvasTitleLabel.Text = '3D user distribution in AoI';
            canvasSubtitle.Text = 'Actual terminal positions extracted from SCENARIO.satelliteScenario.GroundStations.';
            drawScenarioDistribution(ax, State.scenarioPlotData, C, 'scenario');
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

            %setRibbonBadge(viewerBadge, 'Viewer', 'LOCKED', C.neutralSoft, C.disabled);
            setRibbonBadge(assocBadge, 'Association', 'LOCKED', C.neutralSoft, C.disabled);
            setRibbonBadge(exportBadge, 'Export', 'LOCKED', C.neutralSoft, C.disabled);

            enableAction(scenarioBadge, paramsComplete);
            %enableAction(viewerBadge, false);
            enableAction(assocBadge, false);
            enableAction(exportBadge, false);
            numUsersField.Enable = 'on';
            csiDrop.Enable = 'on';
            algDrop.Enable = 'on';
            seedField.Enable = 'on';
            defaultBtn.Enable = 'on';
            resetWorkspaceBtn.Enable = 'on';

            kpiTable.Data = {'No KPI data', '-'};
            
            for i = 1:numel(kpiBtns)
                kpiBtns(i).Enable = 'off';
                kpiBtns(i).BackgroundColor = C.neutralSoft;
                kpiBtns(i).FontColor = C.disabled;
            end
            clearAtlasMap(ax, C);
            canvasTitleLabel.Text = '';
            canvasSubtitle.Text = '';
            canvasFooter.Text = '';
        end
    end

    function txt = scenarioDistributionFooter(D, params)
        if isempty(D) || ~isstruct(D)
            txt = 'Scenario generated, but no plot data is available.';
            return;
        end

        try
            txt = sprintf('%d real terminals plotted inside AoI | %s CSI | %s policy | external Satellite Scenario Viewer available.', ...
                D.numUsers, char(string(params.CSImode)), char(string(params.associationAlgorithm)));
        catch
            txt = sprintf('%d real terminals plotted inside AoI | external Satellite Scenario Viewer available.', D.numUsers);
        end
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
            lines = [lines; {' '; 'KPI results:'}; structToLines(State.RESULTS.KPI_results)]; %#ok<AGROW>
        end
    end

    function tuneURLLC()
        if isempty(State.params)
            State.params = State.defaultParams;
        end
        p = State.params.policy.URLLC;
        d = modalWindow('URLLC Policy Tuning', C, [470 315 455 400]);

        g = uigridlayout(d, [8 2]);
        g.RowHeight = {42, 42, 42, 42, 42, 42, 12, 42};
        g.ColumnWidth = {205, '1x'};
        g.Padding = [20 20 20 20];
        g.RowSpacing = 8;
        g.BackgroundColor = C.bg;

        modalHeader(g, 'URLLC policy', 'Latency-constrained association controls', C, fontName);
        f1 = modalNumeric(g, 'Delta latency [s]', p.URLLC_DeltaTau_switch_s, C, fontName);
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
            try
                State.params.policy.URLLC.URLLC_DeltaTau_switch_s = f1.Value;
                State.params.policy.URLLC.latency_max_URLLC = f2.Value;
                State.params.policy.URLLC.SNRmin_URLLC_lin = f3.Value;
                State.params.policy.URLLC.time_window = round(f4.Value);
                State.params.policy.URLLC.handoverMax_URLLC = round(f5.Value);

                validate_NAPOLEON_params(State.params);
                appendLog('URLLC POLICY UPDATED');
                delete(d);
                State.RESULTS = [];
                State.associationCompleted = false;
                refreshUI('scenarioReady');
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
        d = modalWindow('eMBB Policy Tuning', C, [470 335 455 360]);

        g = uigridlayout(d, [7 2]);
        g.RowHeight = {42, 42, 42, 42, 42, 12, 42};
        g.ColumnWidth = {205, '1x'};
        g.Padding = [20 20 20 20];
        g.RowSpacing = 8;
        g.BackgroundColor = C.bg;

        modalHeader(g, 'eMBB policy', 'Throughput-constrained association controls', C, fontName);
        f1 = modalNumeric(g, 'Delta rate [bit/s]', p.eMBB_DeltaR_switch_bps, C, fontName);
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
            try
                State.params.policy.eMBB.eMBB_DeltaR_switch_bps = f1.Value;
                State.params.policy.eMBB.rateMin_eMBB_bps = f2.Value;
                State.params.policy.eMBB.time_window = round(f3.Value);
                State.params.policy.eMBB.handoverMax_eMBB = round(f4.Value);

                validate_NAPOLEON_params(State.params);
                appendLog('eMBB POLICY UPDATED');
                delete(d);
                State.RESULTS = [];
                State.associationCompleted = false;
                refreshUI('scenarioReady');
            catch ME
                uialert(d, ME.message, 'Invalid eMBB values');
            end
        end
    end
end

%% THEME AND UI FUNCTIONS

function C = atlasTheme()
    C.bg          = [0.935 0.950 0.970];
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
    p = uipanel(parent, ...
    'BackgroundColor', C.bg, ...
    'BorderType', 'none');
axBg = uiaxes(p, 'Position', [0 0 420 54]);
axBg.XAxis.Visible = 'off'; axBg.YAxis.Visible = 'off';
axBg.Color = 'none';
axBg.XLim = [0 1]; axBg.YLim = [0 1];
% Rettangolo arrotondato con bordo — stesso aspetto dei bottoni
rectangle(axBg, 'Position', [0.01 0.05 0.98 0.90], 'Curvature', [0.15 0.5], ...
    'FaceColor', C.neutralSoft, 'EdgeColor', [0.75 0.80 0.88], 'LineWidth', 1.2);

    g = uigridlayout(p, [3 1]);
    g.RowHeight = {16, 46, 18};
    g.Padding = [12 3 12 3];
    g.RowSpacing = 2;
    g.BackgroundColor = C.neutralSoft;

    title = uilabel(g, ...
        'Text', 'RUN TIME / ELAPSED', ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.neutralSoft);

    ax = uiaxes(g);
    ax.Toolbar.Visible = 'off';
    ax.Box = 'off';
    ax.XTick = [];
    ax.YTick = [];
    ax.XLim = [0 1];
    ax.YLim = [0 1];
    ax.Color = C.neutralSoft;
    try
        disableDefaultInteractivity(ax);
    catch
    end

    hold(ax, 'on');
   
   ax.Color = C.card; 

    % 1. Track di base (lo sfondo grigino vuoto della barra)
    patch('Parent', ax, ...
        'XData', [0 1 1 0], 'YData', [0.18 0.18 0.82 0.82], ...
        'FaceColor', C.neutralSoft, 'EdgeColor', 'none');

    % 2. Barra di riempimento (quella che si colorerà)
    % (Nota: assegnala a H.Fill o r.Fill in base a come si chiama la tua struttura di ritorno)
    H.Fill = patch('Parent', ax, ...
        'XData', [0 0.001 0.001 0], 'YData', [0.18 0.18 0.82 0.82], ...
        'FaceColor', C.accent, 'EdgeColor', 'none');

    % 3. Cornice perimetrale elegante
    patch('Parent', ax, ...
        'XData', [0 1 1 0], 'YData', [0.18 0.18 0.82 0.82], ...
        'FaceColor', 'none', 'EdgeColor', C.axis, 'LineWidth', 1.0);

    hold(ax, 'off');

    value = uilabel(g, ...
        'Text', '00:00', ...
        'FontName', fontName, ...
        'FontSize', 16, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.neutralSoft, ...
        'HorizontalAlignment', 'right');

    H.Panel = p;
    H.Grid = g;
    H.Title = title;
    H.Axes = ax;
    %H.Fill = fillPatch;
    H.Value = value;
end

function setRuntimeBar(H, fraction, elapsedText, fillColor, C)
    fraction = min(max(fraction, 0), 1);
    x = max(fraction, 0.001);

    H.Fill.XData = [0 x x 0];
    H.Fill.YData = [0.18 0.18 0.82 0.82];
    H.Fill.FaceColor = fillColor;
    H.Value.Text = elapsedText;

    % if fraction <= 0
    %     bg = C.neutralSoft;
    % elseif isequal(fillColor, C.warnText)
    %     bg = C.warnSoft;
    % elseif isequal(fillColor, C.error)
    %     bg = C.redSoft;
    % elseif isequal(fillColor, C.ready)
    %     bg = C.greenSoft;
    % else
    %     bg = C.blueSoft;
    % end
    bg = C.card;

    H.Panel.BackgroundColor = bg;
    H.Grid.BackgroundColor = bg;
    H.Title.BackgroundColor = bg;
    H.Value.BackgroundColor = bg;
    H.Axes.Color = bg;
    
    if fraction <= 0
        H.Value.FontColor = C.muted;
    else
        H.Value.FontColor = fillColor;
    end
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
    if isempty(RESULTS) || ~isfield(RESULTS, 'KPI_results')
        data = {'No KPI data', '-', '-'};
        return;
    end

    K = RESULTS.KPI_results;

    if ~isfield(K, 'generalKPIs')
        data = {'generalKPIs not found', '-', '-'};
        return;
    end

    G = K.generalKPIs;
    rows = {};

    % SNR medio globale utente
    if isfield(G, 'SNR') && isfield(G.SNR, 'globalAvgUserSNR_dB')
        v = G.SNR.globalAvgUserSNR_dB;
        if isnumeric(v) && isscalar(v)
            rows(end+1,:) = {'Avg User SNR', sprintf('%.2f', v), 'dB'};
        end
    end

    % Throughput medio globale utente in Mbps
    if isfield(G, 'throughput') && isfield(G.throughput, 'globalAvgUserRate_Mbps')
        v = G.throughput.globalAvgUserRate_Mbps;
        if isnumeric(v) && isscalar(v)
            rows(end+1,:) = {'Avg User Rate', sprintf('%.3f', v), 'Mbps'};
        end
    end

    % Efficienza spettrale media globale utente
    if isfield(G, 'throughput') && isfield(G.throughput, 'globalAvgUserRate_bpsHz')
        v = G.throughput.globalAvgUserRate_bpsHz;
        if isnumeric(v) && isscalar(v)
            rows(end+1,:) = {' Avg User Spectral Efficiency', sprintf('%.4f', v), 'b/s/Hz'};
        end
    end

    % KPI specifico URLLC
    if ~isempty(params) && isfield(params, 'associationAlgorithm') && ...
       strcmpi(string(params.associationAlgorithm), 'URLLC')
        if isfield(K, 'specificURLLC') && isfield(K.specificURLLC, 'PL_URLLC_global')
            v = K.specificURLLC.PL_URLLC_global;
            if isnumeric(v) && isscalar(v)
                rows(end+1,:) = {'URLLC 90th Percentile', sprintf('%.4f', v), 'ms'};
            end
        end
    end

    if isempty(rows)
        data = {'No valid KPI fields', '-', '-'};
    else
        data = rows;
    end
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
            rows = [rows; violationRow(flat, ["latency","delay"], params.policy.URLLC.latency_max_URLLC, "max", "Latency target")]; %#ok<AGROW>
            rows = [rows; violationRow(flat, ["snr"], params.policy.URLLC.SNRmin_URLLC_lin, "min", "SNR target")]; %#ok<AGROW>
            rows = [rows; violationRow(flat, ["handover","HO"], params.policy.URLLC.handoverMax_URLLC, "max", "Handover limit")]; %#ok<AGROW>
        case "eMBB"
            rows = [rows; violationRow(flat, ["rate","throughput"], params.policy.eMBB.rateMin_eMBB_bps, "min", "Rate target")]; %#ok<AGROW>
            rows = [rows; violationRow(flat, ["handover","HO"], params.policy.eMBB.handoverMax_eMBB, "max", "Handover limit")]; %#ok<AGROW>
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
            flat(end+1, :) = {char(prefix), value}; %#ok<AGROW>
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

function modalHeader(parent, titleText, subText, C, fontName)
    g = uigridlayout(parent, [2 1]);
    g.Layout.Row = 1;
    g.Layout.Column = [1 2];
    g.RowHeight = {22, 18};
    g.Padding = [0 0 0 0];
    g.RowSpacing = 0;
    g.BackgroundColor = C.bg;

    uilabel(g, ...
        'Text', titleText, ...
        'FontName', fontName, ...
        'FontSize', 16, ...
        'FontWeight', 'bold', ...
        'FontColor', C.text, ...
        'BackgroundColor', C.bg);

    uilabel(g, ...
        'Text', subText, ...
        'FontName', fontName, ...
        'FontSize', 10, ...
        'FontColor', C.muted, ...
        'BackgroundColor', C.bg);
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
        % Table styling differs across MATLAB releases; the GUI remains functional.
    end
end

function out = ternary(condition, a, b)
    if condition
        out = a;
    else
        out = b;
    end
end
