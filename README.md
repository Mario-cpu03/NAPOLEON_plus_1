# NAPOLEON+

## KPI-Oriented User–Satellite Association Simulator for LEO Non-Terrestrial Networks

**NAPOLEON+** is a MATLAB-based simulation framework for the analysis of user–satellite association and handover strategies in Low Earth Orbit (LEO) Non-Terrestrial Networks (NTNs).

The simulator models a dynamic LEO communication scenario by combining:

* satellite constellation geometry,
* ground-user spatial distribution,
* satellite visibility and elevation constraints,
* trace-based land-mobile satellite channel modeling,
* user–satellite association through assignment optimization,
* handover-aware decision policies,
* system-level KPI evaluation,
* graphical visualization through a MATLAB GUI.

The project is designed as an academic simulator for evaluating how LEO-specific effects, such as fast satellite motion, short visibility windows, time-varying channel quality, and limited satellite capacity, affect the quality of service perceived by ground users.

---

## Table of Contents

* [Overview](#overview)
* [Scientific Context](#scientific-context)
* [Main Features](#main-features)
* [Current Implementation](#current-implementation)
* [Simulator Architecture](#simulator-architecture)
* [Project Structure](#project-structure)
* [Requirements](#requirements)
* [Installation](#installation)
* [How to Run](#how-to-run)
* [Configuration Parameters](#configuration-parameters)
* [Simulation Outputs](#simulation-outputs)
* [Key Performance Indicators](#key-performance-indicators)
* [GUI](#gui)
* [Development Status](#development-status)
* [References](#references)
* [Authors](#authors)
* [License](#license)

---

## Overview

LEO satellite networks are a key component of future 5G-Advanced and 6G Non-Terrestrial Network architectures. Compared with Geostationary Earth Orbit (GEO) systems, LEO constellations offer lower propagation delay and reduced free-space path loss. However, these advantages come with a highly dynamic network topology.

A ground user can typically see a given LEO satellite only for a limited time interval. As a consequence, continuous service requires frequent reassignment between satellites. The user–satellite association problem is therefore not static: it must be solved repeatedly over time while accounting for visibility, link quality, satellite capacity, and service-specific constraints.

NAPOLEON+ addresses this problem by simulating a realistic LEO scenario and evaluating association policies through Key Performance Indicators (KPIs) inspired by two main service classes:

* **eMBB**: enhanced Mobile Broadband, where the objective is mainly throughput-oriented;
* **URLLC**: Ultra-Reliable Low-Latency Communications, where latency, reliability, and handover stability are critical.

---

## Scientific Context

The simulator belongs to the domain of LEO satellite communication networks and NTN system-level simulation. The main technical aspects covered by the project are:

1. **LEO constellation geometry**

   The current implementation uses a Starlink-like Walker constellation profile with multiple orbital planes and a fixed phasing parameter. The constellation is propagated through MATLAB satellite scenario tools.

2. **Ground-user distribution**

   Users are placed inside a configurable Area of Interest (AoI), currently focused on continental Europe. The simulator supports heterogeneous propagation environments assigned to ground users.

3. **Satellite visibility**

   At each simulation time step, the simulator determines which satellites are visible from each user according to a minimum elevation-angle constraint.

4. **Ground-to-satellite channel modeling**

   The communication channel is modeled through a simplified trace-based statistical emulator. The model uses environment-dependent and elevation-dependent Land Mobile Satellite (LMS) fading traces. Two CSI modes are supported:

   * `ideal`: link quality is computed using a time-coherent sliding window of the fading trace;
   * `forecast`: link quality is computed from the mean fading profile of the corresponding environment/elevation class.

5. **User–satellite association**

   Association is formulated as an assignment problem and solved through a Munkres/Hungarian-based approach. The cost function depends on the selected service policy.

6. **Handover-aware optimization**

   The association logic includes a penalty for unnecessary handovers. This allows the simulator to study the trade-off between instantaneous link quality and connection stability.

7. **KPI evaluation**

   The output of the association process is evaluated through general and service-specific KPIs, including throughput, SNR, latency, handover count, service continuity, and compliance with URLLC/eMBB constraints.

---

## Main Features

* Dynamic LEO satellite scenario simulation.
* Starlink-like constellation configuration.
* Configurable number of ground users.
* Configurable Area of Interest.
* Minimum elevation-angle filtering.
* Environment-aware ground-user modeling.
* Trace-based LMS channel emulation.
* Support for `ideal` and `forecast` CSI modes.
* eMBB-oriented and URLLC-oriented association policies.
* Handover-aware assignment strategy.
* Satellite capacity constraint.
* General KPI computation.
* Service-specific KPI computation.
* MATLAB GUI for parameter setup, scenario generation, simulation execution, and visualization.
* Modular backend structure for future extension.

---

## Current Implementation

The current implementation is organized around two backend wrapper functions:

```matlab
SCENARIO = run_NAPOLEON_scenario(params);
RESULTS  = run_NAPOLEON_simulation(SCENARIO, params);
```

The intended workflow is:

1. define or load the simulation parameters;
2. generate the LEO scenario and channel evolution;
3. run the user–satellite association algorithm;
4. evaluate the KPIs;
5. visualize the results through MATLAB plots or the GUI.

The legacy script

```matlab
NAPOLEON_plus_1.m
```

still provides a monolithic execution flow, but the recommended structure is now based on the two wrapper functions above, since they separate scenario generation from association and KPI evaluation.

---

## Simulator Architecture

NAPOLEON+ is divided into four main modules.

---

### 1. ChannelModel

The `ChannelModel` module builds the physical and radio environment of the simulation.

It performs:

* satellite scenario initialization;
* LEO constellation generation;
* user distribution generation;
* user environment assignment;
* satellite visibility filtering;
* distance and elevation computation;
* trace-based channel evaluation;
* SNR and rate tensor generation.

The main entry point is:

```matlab
main_channel_function(...)
```

The output is the structure:

```matlab
USER_SAT_evolution
```

which contains the time evolution of the available user–satellite links.

Typical fields include:

```matlab
USER_SAT_evolution.timeVec
USER_SAT_evolution.numUsers
USER_SAT_evolution.numSats
USER_SAT_evolution.numTimeSteps
USER_SAT_evolution.validLinkMask
USER_SAT_evolution.distanceTensor
USER_SAT_evolution.elevationClassTensor
USER_SAT_evolution.pathGainTensor
USER_SAT_evolution.SNRtensor
USER_SAT_evolution.rateTensor
USER_SAT_evolution.satelliteScenario
```

---

### 2. UserSatAssoc

The `UserSatAssoc` module performs the user–satellite association.

The association process uses:

* link-quality information from the channel model;
* service-specific cost functions;
* satellite capacity constraints;
* handover penalties;
* Munkres/Hungarian assignment logic.

The main entry point is:

```matlab
main_association_function(USER_SAT_evolution, configAssociation)
```

The output is the structure:

```matlab
USER_SAT_association
```

which stores the association history and the link quantities selected by the algorithm.

The current implementation supports two policy modes:

```matlab
"URLLC"
"eMBB"
```

The **URLLC** mode is latency-oriented and handover-sensitive.

The **eMBB** mode is throughput-oriented and rate-aware.

---

### 3. KPIs

The `KPIs` module evaluates the performance of the selected association strategy.

The main entry point is:

```matlab
main_KPI_function(USER_SAT_association, configKPI)
```

The output is the structure:

```matlab
KPI_results
```

It includes:

* general system-level KPIs;
* URLLC-specific KPIs;
* eMBB-specific KPIs;
* compliance metrics;
* violation statistics.

---

### 4. GUI

The `GUI` module provides an interactive MATLAB interface for:

* setting simulation parameters;
* loading default values;
* generating the scenario;
* opening the MATLAB satellite scenario viewer;
* running the association algorithm;
* visualizing user distribution and KPI results;
* exporting or inspecting simulation outputs.

The current GUI entry point is:

```matlab
NAPOLEON_GUI_v0
```

The GUI is currently under active development and is intended to become the main user-facing interface of the simulator.

---

## Project Structure

The current repository is organized as follows:

```text
NAPOLEON_plus_1/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── data/
│   └── ...
│
├── docs/
│   └── ...
│
├── tests/
│   └── ...
│
└── src/
    │
    ├── NAPOLEON_plus_1.m
    ├── default_NAPOLEON_params.m
    ├── validate_NAPOLEON_params.m
    ├── run_NAPOLEON_scenario.m
    ├── run_NAPOLEON_simulation.m
    │
    ├── ChannelModel/
    │   ├── main_channel_function.m
    │   ├── Satellite_constellation.m
    │   ├── User_behavior.m
    │   ├── Filter_constellation.m
    │   ├── channel_model.m
    │   ├── Display_globe.m
    │   ├── satellite_helper_functions/
    │   ├── channel_helper_functions/
    │   ├── user behavior functions/
    │   └── preassignment_diagnostics/
    │
    ├── UserSatAssoc/
    │   ├── main_association_function.m
    │   └── munkres_helper_functions/
    │
    ├── KPIs/
    │   ├── main_KPI_function.m
    │   ├── general_KPIS.m
    │   ├── URLLC_KPIs.m
    │   ├── eMBB_KPIs.m
    │   └── KPI_helper_functions/
    │
    └── GUI/
        ├── NAPOLEON_GUI_v0.m
        ├── buildScenarioPlotData.m
        └── drawScenarioDistribution.m
```

---

## Requirements

NAPOLEON+ is developed in MATLAB.

The simulator requires a MATLAB installation supporting:

* `satelliteScenario`;
* satellite propagation and access analysis;
* MATLAB plotting utilities;
* GUI execution from `.m` files.

The recommended software configuration is:

* MATLAB, recent release;
* Satellite Communications Toolbox;
* MATLAB App Designer, for future conversion into a packaged application;
* standard MATLAB graphics support.

The project has not yet been fully validated across different MATLAB releases. For this reason, using a recent MATLAB version with full support for the Satellite Communications Toolbox is recommended.

---

## Installation

Clone the repository locally:

```bash
git clone https://github.com/Mario-cpu03/NAPOLEON_plus_1.git
cd NAPOLEON_plus_1
```

Then open MATLAB from the repository root folder and add the source directory to the MATLAB path:

```matlab
addpath(genpath("src"))
```

---

## How to Run

### Option 1 — Recommended backend workflow

Create the default parameter structure:

```matlab
params = default_NAPOLEON_params();
```

Generate the scenario:

```matlab
SCENARIO = run_NAPOLEON_scenario(params);
```

Run association and KPI evaluation:

```matlab
RESULTS = run_NAPOLEON_simulation(SCENARIO, params);
```

The two-step execution is recommended because it separates:

1. scenario and channel generation;
2. association and KPI computation.

This makes the simulator easier to connect to the GUI and easier to debug.

---

### Option 2 — Legacy script

The original monolithic script can still be executed with:

```matlab
run("src/NAPOLEON_plus_1.m")
```

This script directly executes:

1. scenario generation;
2. channel modeling;
3. user–satellite association;
4. KPI evaluation.

However, for future development, the wrapper-based workflow is preferred.

---

### Option 3 — GUI

Launch the current MATLAB GUI with:

```matlab
NAPOLEON_GUI_v0
```

The GUI is intended to provide a user-facing workflow with buttons for:

* loading default parameters;
* resetting the interface;
* generating the scenario;
* opening the scenario viewer;
* running the association;
* displaying KPI results.

---

## Configuration Parameters

Default parameters are defined in:

```matlab
src/default_NAPOLEON_params.m
```

The main default values are summarized below.

### Reproducibility

```matlab
params.seed = 13;
```

### User-facing inputs

```matlab
params.numUsers = 100;
params.CSImode = "forecast";              % "forecast" or "ideal"
params.associationAlgorithm = "eMBB";     % "URLLC" or "eMBB"
```

### Time settings

```matlab
params.startTime = datetime('today');
params.simulationDuration_min = 192;
params.sampleTime_s = 20;
```

The default simulation duration is 192 minutes, corresponding to 3 hours and 12 minutes.

### Constellation profile

```matlab
params.constellation.planes = 72;
params.constellation.satellitesPerPlane = 22;
params.constellation.inclination_deg = 53.2;
params.constellation.phasingParam = 17;
params.constellation.altitude_km = 540;
```

This corresponds to a Starlink-like LEO shell with:

* 72 orbital planes;
* 22 satellites per plane;
* 1584 total satellites;
* 53.2 degrees inclination;
* 540 km altitude;
* phasing parameter equal to 17.

### Area of Interest

```matlab
params.AoI.latMin = 35;
params.AoI.latMax = 60;
params.AoI.lonMin = -10;
params.AoI.lonMax = 30;
params.AoI.deltaLat = 2;
params.AoI.deltaLon = 2;
```

The default Area of Interest covers a portion of continental Europe.

### Elevation threshold

```matlab
params.minimumElevation_deg = 25;
```

Only satellites above the minimum elevation angle are considered valid for user association.

### Radio and channel profile

```matlab
params.channel.satellitePower_W = 1;
params.channel.satelliteGain_dBi = 50;
params.channel.userGain_dBi = 0;
params.channel.systemTemperature_K = 290;
params.channel.bandwidth_Hz = 5e6;
params.channel.carrierFrequency_Hz = 2e9;
params.channel.mobileSpeed_kmh = 5;
params.channel.sampleRate_Hz = 100;
```

The channel is currently modeled at 2 GHz with a 5 MHz bandwidth. The mobile speed parameter is used for LMS fading trace generation.

### Association profile

```matlab
params.association.satelliteCapacity = 2;
```

The current implementation limits the number of users assigned to each satellite through a capacity parameter.

### URLLC policy parameters

```matlab
params.policy.URLLC.URLLC_DeltaTau_switch_s = 1.00e-3;
params.policy.URLLC.latency_max_URLLC = 3e-3;
params.policy.URLLC.SNRmin_URLLC_lin = 10;
params.policy.URLLC.time_window = 6;
params.policy.URLLC.handoverMax_URLLC = 1;
params.policy.URLLC.percentile_URLLC = 0.90;
```

### eMBB policy parameters

```matlab
params.policy.eMBB.eMBB_DeltaR_switch_bps = 2e6;
params.policy.eMBB.rateMin_eMBB_bps = 50e6;
params.policy.eMBB.time_window = 13;
params.policy.eMBB.handoverMax_eMBB = 4;
```

---

## Simulation Outputs

The backend produces two main high-level objects:

```matlab
SCENARIO
RESULTS
```

---

### SCENARIO

The `SCENARIO` structure is returned by:

```matlab
SCENARIO = run_NAPOLEON_scenario(params);
```

It contains:

```matlab
SCENARIO.params
SCENARIO.startTime
SCENARIO.stopTime
SCENARIO.sampleTime
SCENARIO.configConst
SCENARIO.configAoI
SCENARIO.configChannel
SCENARIO.minimumElev
SCENARIO.USER_SAT_evolution
SCENARIO.satelliteScenario
SCENARIO.scenarioGenerated
```

The most important field is:

```matlab
SCENARIO.USER_SAT_evolution
```

which contains the dynamic channel and visibility tensors.

---

### RESULTS

The `RESULTS` structure is returned by:

```matlab
RESULTS = run_NAPOLEON_simulation(SCENARIO, params);
```

It contains:

```matlab
RESULTS.params
RESULTS.configAssociation
RESULTS.configKPI
RESULTS.USER_SAT_association
RESULTS.KPI_results
RESULTS.associationCompleted
```

The most important fields are:

```matlab
RESULTS.USER_SAT_association
RESULTS.KPI_results
```

---

### USER_SAT_evolution

This structure contains the time evolution of all valid user–satellite links.

Typical quantities include:

* valid link mask;
* user–satellite distance;
* quantized elevation class;
* path gain;
* SNR;
* achievable rate.

The tensors are generally indexed over:

```text
user × satellite × time
```

---

### USER_SAT_association

This structure contains the selected association history after applying the chosen assignment algorithm.

It stores the time evolution of the selected serving satellites and the corresponding link quantities used for KPI evaluation.

---

### KPI_results

This structure contains the output of the KPI evaluation module.

It includes:

* general KPIs;
* URLLC KPIs;
* eMBB KPIs;
* service compliance information;
* violation-related statistics.

---

## Key Performance Indicators

The KPI module evaluates the simulator output at both system level and service level.

---

### General KPIs

General KPIs are independent of the selected service profile and describe the overall behavior of the network.

They include:

* average user throughput;
* average user SNR;
* total system throughput over time;
* total system SNR over time;
* handover statistics;
* service continuity;
* per-user rate distribution;
* per-user SNR distribution.

Typical plots associated with general KPIs are:

* total throughput versus time;
* average SNR versus time;
* CDF of per-user average throughput;
* CDF of per-user average SNR;
* number of handovers versus time;
* per-user average throughput bar plot.

---

### URLLC KPIs

URLLC-oriented KPIs focus on low latency, link robustness, and handover stability.

They include:

* latency compliance;
* SNR compliance;
* handover compliance;
* percentile latency;
* number of URLLC constraint violations;
* user-level URLLC service continuity.

The main URLLC constraints are:

```matlab
latency <= latency_max_URLLC
SNR >= SNRmin_URLLC
handovers <= handoverMax_URLLC
```

URLLC is therefore evaluated by checking whether users remain connected through sufficiently low-latency and sufficiently reliable links while avoiding excessive handovers.

---

### eMBB KPIs

eMBB-oriented KPIs focus on throughput and broadband service quality.

They include:

* rate compliance;
* average user rate;
* system sum rate;
* spectral efficiency;
* handover compliance;
* user-level eMBB service continuity.

The main eMBB constraints are:

```matlab
rate >= rateMin_eMBB
handovers <= handoverMax_eMBB
```

eMBB is therefore evaluated by checking whether users receive sufficient throughput while avoiding unnecessary reassociations.

---

## GUI

The GUI is implemented in:

```matlab
src/GUI/NAPOLEON_GUI_v0.m
```

The GUI is intended to act as the main user-facing control layer of the simulator.

The planned workflow is:

1. select or load simulation parameters;
2. generate the LEO scenario;
3. visualize users and satellites;
4. run the association algorithm;
5. inspect KPI tables and plots;
6. export results.

The GUI currently interacts with the same backend wrappers used by the script-based workflow:

```matlab
run_NAPOLEON_scenario
run_NAPOLEON_simulation
```

Additional GUI helper files include:

```matlab
buildScenarioPlotData.m
drawScenarioDistribution.m
```

These functions support scenario visualization and user/satellite distribution plotting.

---

## Development Status

NAPOLEON+ is currently under active development.

### Implemented

* LEO satellite scenario generation.
* Starlink-like constellation definition.
* Ground-user distribution over a European Area of Interest.
* Satellite visibility filtering using minimum elevation.
* Trace-based LMS channel model.
* Ideal and forecast CSI modes.
* User–satellite association backend.
* eMBB and URLLC association-policy support.
* Munkres/Hungarian-based assignment logic.
* General, URLLC, and eMBB KPI modules.
* Preliminary MATLAB GUI.
* Backend wrappers for GUI-compatible execution.

### In progress

* Final GUI refinement.
* Selection of the final set of KPI plots to display.
* GUI-to-backend integration polishing.
* Result export workflow.
* Conversion into an executable MATLAB application.
* Final project report.

### Future improvements

Possible future extensions include:

* more advanced handover strategies;
* explicit soft-handover or dual-connectivity implementation;
* inter-satellite link modeling;
* load-aware multi-objective association;
* mobility of ground users;
* comparison between multiple constellation shells;
* more realistic traffic models;
* packet-level or protocol-level simulation;
* validation against external NTN benchmarks.

---

## References

The project is based on academic and technical references related to LEO satellite networks, NTN systems, propagation modeling, and handover strategies.

### User–Satellite Association and Handover

* A. Z. Khalifeh, *Optimization of User–LEO Satellite Assignments*, Master’s Thesis, Politecnico di Torino, 2024–2025.

* H. Ben Salem, A. Tarable, A. Nordio, and B. Makki, “Uplink Soft Handover for LEO Constellations: How Strong the Inter-Satellite Link Should Be.”

* J. Wu, S. Su, X. Wang, J. Zhang, and Y. Gao, “Accelerating Handover in Mobile Satellite Network.”

### Channel and Propagation Modeling

* ITU-R Recommendation P.681-10, *Propagation Data Required for the Design of Earth-Space Land Mobile Telecommunication Systems*, International Telecommunication Union, 2017.

* 3GPP TR 38.811, *Study on New Radio (NR) to Support Non-Terrestrial Networks*, Release 15.

### 5G/6G and KPI Requirements

* ITU-R Report M.2410-0, *Minimum Requirements Related to Technical Performance for IMT-2020 Radio Interface(s)*, International Telecommunication Union, 2017.

### LEO Constellation Modeling

* J. Liang, A. U. Chaudhry, and H. Yanikomeroglu, “Phasing Parameter Analysis for Satellite Collision Avoidance in Starlink and Kuiper Constellations.”

* Federal Communications Commission, *Order and Authorization and Order on Reconsideration: Space Exploration Holdings, LLC Request for Modification of the Authorization for the SpaceX NGSO Satellite System*, FCC 21-48, 2021.

* N. Pachler, I. del Portillo, E. F. Crawley, and B. G. Cameron, “An Updated Comparison of Four Low Earth Orbit Satellite Constellation Systems to Provide Global Broadband.”

---

## Authors

### Supervisor

* Prof. Alberto Tarable

### Team

* Mario Pellegrino Ambrosone
* Santi La Spina
* Aditya Gohite

---

## Academic Context

This project was developed for the course:

**Software Defined Communication Systems**
MSc in Communications Engineering
Politecnico di Torino

The project objective is the implementation of a modular simulator for the evaluation of user–satellite association algorithms in LEO Non-Terrestrial Networks.

---

## License

This project is licensed under the MIT License.

See the [LICENSE](LICENSE) file for further details.
