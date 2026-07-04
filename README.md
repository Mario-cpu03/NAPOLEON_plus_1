# NAPOLEON+

## Numerical Assessment of Performance Of next-gen LEO Networks

**NAPOLEON+** is a MATLAB-based simulator for evaluating service-aware user–satellite association policies in Low Earth Orbit (LEO) Non-Terrestrial Networks (NTNs).

The simulator generates a dynamic LEO access scenario, computes time-varying user–satellite visibility and radio-link quality, executes association and handover decisions, and evaluates the resulting performance through system-level and service-specific KPIs.

NAPOLEON+ is designed as a GUI-driven access-planning and evaluation platform: the user configures a scenario, selects an association policy, runs the simulation, inspects the KPIs, and exports the results.

---

## Table of Contents

- [Overview](#overview)
- [Engineering Problem](#engineering-problem)
- [Main Features](#main-features)
- [Simulation Workflow](#simulation-workflow)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Installation](#installation)
- [How to Run](#how-to-run)
- [Default Scenario](#default-scenario)
- [Input Parameters](#input-parameters)
- [Association Policies](#association-policies)
- [Channel-State Information Modes](#channel-state-information-modes)
- [Outputs](#outputs)
- [KPIs](#kpis)
- [Exported Results](#exported-results)
- [References](#references)
- [Authors](#authors)
- [License](#license)

---

## Overview

LEO satellite networks are highly dynamic systems. Unlike terrestrial cellular networks, where the infrastructure is fixed and users move, LEO constellations involve rapidly moving access nodes.

For each user and each simulation instant, the simulator decides which visible satellite should serve the user while accounting for:

- satellite motion;
- short visibility windows;
- elevation-dependent link quality;
- slant range and propagation delay;
- channel-state uncertainty;
- handover frequency;
- service-specific requirements.

For this reason, NAPOLEON+ is not only a constellation viewer or a coverage tool. It is a KPI-driven access evaluation platform for comparing association strategies under LEO mobility, propagation uncertainty and handover constraints.

---

## Engineering Problem

Given a time-varying LEO constellation, a set of terrestrial users, a propagation model and a service-specific association policy, **NAPOLEON+ evaluates whether the resulting user–satellite associations remain service-compliant over time**.

The problem is:

- **dynamic**, because visibility, distance, delay, SNR and rate evolve over time;
- **service-aware**, because the best satellite depends on the selected traffic profile;
- **handover-aware**, because excessive switching may degrade service continuity;
- **KPI-driven**, because the final output is assessed through interpretable performance indicators.

---

## Main Features

- MATLAB GUI for scenario setup, execution and result visualization.
- Starlink-like LEO constellation profile.
- European area-of-interest scenario.
- Time-dependent satellite visibility computation.
- Ground-to-satellite channel characterization.
- Ideal and forecast Channel-State Information modes.
- Service-aware association policies:
  - eMBB-oriented policy;
  - URLLC-oriented policy.
- Handover-aware association logic.
- KPI computation and plotting.
- User-level inspection tools.
- Export of plots, KPI tables and raw MATLAB data.
- Standalone application packages for Windows and macOS.

---

## Simulation Workflow

NAPOLEON+ follows a two-stage backend workflow controlled through the GUI.

### 1. Scenario Generation

The simulator generates the physical and radio-access scenario:

- simulation time window;
- satellite constellation;
- area of interest;
- user distribution;
- visibility map;
- channel quantities;
- SNR and rate of candidate links;
- satellite scenario object for visualization.

This stage builds the dynamic link environment. It does not yet perform user–satellite association or KPI evaluation.

### 2. Association and KPI Evaluation

After the scenario is generated, the selected policy is applied. The simulator:

- builds the association configuration;
- runs the user–satellite association algorithm;
- records assigned satellites over time;
- detects handover events;
- computes general and service-specific KPIs;
- updates plots and summary tables.

---

## Project Structure

```text
NAPOLEON_plus_1/
│
├── src/
│   ├── default_NAPOLEON_params.m
│   ├── validate_NAPOLEON_params.m
│   ├── run_NAPOLEON_scenario.m
│   ├── run_NAPOLEON_simulation.m
│   │
│   ├── ChannelModel/
│   │   └── Channel and visibility generation routines
│   │
│   ├── UserSatAssoc/
│   │   └── Association and handover logic
│   │
│   ├── KPIs/
│   │   └── KPI computation routines
│   │
│   ├── GUI/
│   │   ├── NAPOLEON_GUI_v0.m
│   │   ├── buildScenarioPlotData.m
│   │   ├── plotNAPOLEONKPI.m
│   │   └── plotUserScenarioDistribution.m
│   │
│   └── images/
│
├── data/
│   └── Reference outputs for defualt policies
│
├── docs/
│   └── Documentation and report material
│
├── NAPOLEON_MACOS/
│   └── macOS standalone app
│
├── NAPOLEON_Windows/
│   └── Windows standalone app
│
├── README.md
└── LICENSE
```

---

## Requirements

### Source execution

To run the simulator from MATLAB source code:

- MATLAB **R2024a or later**;
- Satellite Communications Toolbox.

The Satellite Communications Toolbox is required for satellite scenarios, orbital geometry, visibility computation and related satellite-link operations.

### Standalone execution

For users without a MATLAB license, the simulator can be executed through the packaged standalone applications. The required MATLAB Runtime is installed automatically by the installer when needed.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/Mario-cpu03/NAPOLEON_plus_1.git
cd NAPOLEON_plus_1
```

Open MATLAB from the repository root and add the source tree:

```matlab
addpath(genpath("src"))
```

---

## How to Run

### Run the GUI from MATLAB

From the repository root:

```matlab
addpath(genpath("src"))
run("src/GUI/NAPOLEON_GUI_v0.m")
```

The GUI is the recommended entry point.

### Run the backend manually

A minimal backend run can be executed as follows:

```matlab
addpath(genpath("src"))

params = default_NAPOLEON_params();

SCENARIO = run_NAPOLEON_scenario(params);
RESULTS  = run_NAPOLEON_simulation(SCENARIO, params);
```

This bypasses the GUI and directly executes the two main simulation stages.

### Run the standalone application

Download the package corresponding to your operating system from the repository releases:

- Windows: use the Windows installer;
- macOS: download and extract the macOS archive.

Then launch the installed NAPOLEON+ application. If the MATLAB Runtime is missing, the installer will download and configure it.

---

## Default Scenario

The default configuration is defined in `src/default_NAPOLEON_params.m`.

### Time Settings

| Parameter | Default value |
|---|---:|
| Simulation duration | 192 min |
| Sample time | 20 s |
| Random seed | 13 |

### Constellation

| Parameter | Default value |
|---|---:|
| Orbital planes | 72 |
| Satellites per plane | 22 |
| Total satellites | 1584 |
| Inclination | 53.2 deg |
| Phasing parameter | 17 |
| Altitude | 540 km |

### Area of Interest

| Parameter | Default value |
|---|---:|
| Latitude range | 35 deg to 60 deg |
| Longitude range | -10 deg to 30 deg |
| Latitude step | 2 deg |
| Longitude step | 2 deg |
| Minimum elevation | 25 deg |

The default scenario represents a Starlink-like LEO shell serving users over Europe.

### Radio and Channel Parameters

| Parameter | Default value |
|---|---:|
| Satellite transmit power | 1 W |
| Satellite antenna gain | 50 dBi |
| User antenna gain | 0 dBi |
| System temperature | 290 K |
| Bandwidth | 5 MHz |
| Carrier frequency | 2 GHz |
| Mobile speed | 5 km/h |
| Channel sample rate | 100 Hz |

---

## Input Parameters

In the default access-planning mode, the user controls the high-level scenario parameters:

- number of terminals;
- CSI mode;
- random seed;
- association policy.

This keeps the GUI interaction at system-planning level. The constellation, area of interest, radio profile and link-budget parameters are predefined but visible in the configuration table.

---

## Association Policies

NAPOLEON+ currently implements two service-aware policies.

### eMBB Policy

The eMBB policy is throughput-oriented. Candidate links are evaluated mainly through achievable rate:

```text
R = B log2(1 + SNR)
```

A handover is accepted only if the candidate satellite provides a sufficient rate improvement with respect to the current serving satellite.

Default eMBB parameters:

| Parameter | Meaning | Default value |
|---|---|---:|
| Delta rate | Minimum rate improvement required for handover | 2 Mbit/s |
| Minimum rate | eMBB compliance threshold | 50 Mbit/s |
| Time window | Samples used for handover-window evaluation | 13 |
| Maximum handovers | Maximum handovers in the window | 4 |

The eMBB policy is useful for testing whether the association strategy can provide broadband-oriented connectivity while avoiding excessive handovers.

### URLLC Policy

The URLLC policy is latency- and reliability-oriented. Candidate links are evaluated mainly through propagation delay:

```text
tau = d / c
```

where `d` is the slant range and `c` is the speed of light.

A handover is accepted only if the candidate satellite provides a sufficient latency reduction with respect to the current serving satellite.

Default URLLC parameters:

| Parameter | Meaning | Default value |
|---|---|---:|
| Delta latency | Minimum latency reduction required for handover | 1 ms |
| Maximum latency | URLLC latency-compliance threshold | 3 ms |
| Minimum SNR | Minimum accepted SNR for compliance | 10 linear |
| Time window | Samples used for handover-window evaluation | 6 |
| Maximum handovers | Maximum handovers in the window | 1 |
| Percentile latency | Percentile used for latency KPI | 90% |

In this simulator, URLLC is used as a strict latency-sensitive stress profile. The latency threshold is a propagation-delay proxy, not a full end-to-end terrestrial URLLC requirement.

---

## Channel-State Information Modes

NAPOLEON+ supports two CSI modes.

### Ideal CSI

The association algorithm uses instantaneous channel information for all visible links.

This mode represents a benchmark condition and is useful for estimating the best achievable behavior of a policy under perfect channel awareness.

### Forecast CSI

The association algorithm relies on averaged or predicted channel behavior derived from expected geometry and channel coefficients.

This mode is more operationally plausible, because instantaneous CSI may be delayed, incomplete or outdated in a fast-moving LEO network, while satellite motion and visibility are largely predictable.

---

## Outputs

After a complete run, the simulator stores:

- assigned satellite index for each user and time step;
- SNR of the selected links;
- achievable rate;
- slant distance;
- propagation latency;
- handover events;
- served-user mask;
- general KPI results;
- service-specific KPI results.

The main output structures are:

```matlab
SCENARIO
RESULTS
```

where `SCENARIO` contains the generated physical/channel scenario and `RESULTS` contains association and KPI outputs.

---

## KPIs

NAPOLEON+ computes both general KPIs and service-specific KPIs.

### General KPIs

- Average SNR evolution.
- Average throughput evolution.
- CDF of average user rate.
- Per-user handover-frequency CDF.
- Number of handover events over time.
- Served-user fraction over time.

### eMBB KPIs

A user is eMBB-compliant if:

```text
rate >= minimum rate
and
number of handovers in the evaluation window <= maximum handovers
```

Additional eMBB indicators include:

- temporal compliance ratio;
- aggregate spectral efficiency;
- average user rate;
- handover statistics.

### URLLC KPIs

A user is URLLC-compliant if:

```text
latency <= maximum latency
and
SNR >= minimum SNR
and
number of handovers in the evaluation window <= maximum handovers
```

Additional URLLC indicators include:

- temporal compliance ratio;
- percentile latency over served users;
- global percentile latency;
- handover statistics.

---

## User-Level Inspection

System-level averages can hide local service degradation. For this reason, the GUI includes a user inspector tool.

For a selected terminal, the user inspector displays:

- available rate evolution;
- service-state evolution;
- cumulative handover behavior;
- total number of handovers;
- service percentage;
- outage or lack-of-service intervals.

This is useful for debugging policies and identifying users that are poorly served even when aggregate KPIs appear acceptable.

---

## Exported Results

After the association stage is completed, NAPOLEON+ can export a complete result package.

The export includes:

- Excel report with configuration and KPI summary tables;
- MATLAB `.mat` file with raw `SCENARIO`, `RESULTS` and parameter structures;
- high-resolution PNG figures for KPI plots;
- user-distribution map.

The raw-data export enables reproducibility without rerunning the simulation.

---

## Notes on Reproducibility

The random seed controls the generated user distribution and scenario realization. To compare policies fairly, use the same seed and scenario settings while changing only the association policy or policy-tuning parameters.

Recommended comparison modes:

- eMBB vs URLLC under the same scenario;
- Ideal CSI vs Forecast CSI under the same policy;
- default policy vs tuned policy;
- aggregate KPIs vs user-level inspection.

---

## Current Limitations

- The default GUI exposes only high-level planning parameters.
- The default constellation and area of interest are fixed in the standard workflow.
- URLLC latency is evaluated as a propagation-delay proxy, not as a full protocol-stack end-to-end latency.
- Results depend on the implemented channel and association assumptions.
- MATLAB release compatibility should be verified on the target machine.

---

## References

NAPOLEON+ builds on technical literature and standards related to NTN systems, LEO constellations, propagation modeling and handover management.

- 3GPP TR 38.811, *Study on New Radio (NR) to Support Non-Terrestrial Networks*, Release 15, 2019.
- ITU-R M.2410-0, *Minimum Requirements Related to Technical Performance for IMT-2020 Radio Interface(s)*, 2017.
- ITU-R P.681-10, *Propagation Data Required for the Design of Earth-Space Land Mobile Telecommunication Systems*, 2017.
- A. Z. Khalifeh, *Optimization of User–LEO Satellite Assignments*, Master’s Thesis, Politecnico di Torino, 2024–2025.
- H. Ben Salem, A. Tarable, A. Nordio, and B. Makki, *Uplink Soft Handover for LEO Constellations: How Strong the Inter-Satellite Link Should Be*.
- J. Liang, A. U. Chaudhry, and H. Yanikomeroglu, *Phasing Parameter Analysis for Satellite Collision Avoidance in Starlink and Kuiper Constellations*.
- Federal Communications Commission, *Order and Authorization and Order on Reconsideration: Space Exploration Holdings, LLC Request for Modification of the Authorization for the SpaceX NGSO Satellite System*, FCC 21-48, 2021.
- N. Pachler, I. del Portillo, E. F. Crawley, and B. G. Cameron, *An Updated Comparison of Four Low Earth Orbit Satellite Constellation Systems to Provide Global Broadband*.

---

## Authors

Project developed for **Software-Defined Communication Systems 2025/26**, Politecnico di Torino.

### Team 1

- Mario Pellegrino Ambrosone
- Santi La Spina
- Aditya Gohite

### Supervisor

- Prof. Alberto Tarable

---

## License

This project is released under the MIT License.
