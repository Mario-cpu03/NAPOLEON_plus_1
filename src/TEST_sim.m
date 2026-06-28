%% Main Function NAPOLEON+ SIMULATOR
% Legacy runner for debugging.
%
% GUI philosophy:
%   1. Generate Scenario  -> run_NAPOLEON_scenario(params)
%   2. Run Association    -> run_NAPOLEON_simulation(SCENARIO, params)
%   3. Export Results     -> future GUI/export function

%close all;
clc;
clear;

params = default_NAPOLEON_params();

%% Optional quick testing modifications
params.numUsers = 100;
params.CSImode = "forecast";
params.associationAlgorithm = "eMBB";

%% Phase 1: generate scenario / ChannelModel
SCENARIO = run_NAPOLEON_scenario(params);

%% Phase 2: association + KPI
RESULTS = run_NAPOLEON_simulation(SCENARIO, params);

disp("NAPOLEON+ two-phase simulation completed.");
disp(RESULTS.KPI_results);