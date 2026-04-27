# NAPOLEON_plus_1
# NAPOLEON+  
## KPI-Oriented User–Satellite Association Simulator for LEO Constellations

NAPOLEON+ is a MATLAB-based simulator for the analysis of user–satellite association strategies in Low Earth Orbit (LEO) satellite networks.  
The simulator is designed to model a realistic LEO scenario by combining geometric visibility, ground-to-satellite channel characterization, association and handover logic, and system-level KPI evaluation.

The main objective is to assess how LEO-specific parameters — such as satellite motion, limited visibility windows, time-varying channel conditions, and load constraints — affect user–satellite association decisions and the resulting performance.

---

## Table of Contents

- [Overview](#overview)
- [Main Features](#main-features)
- [Simulator Architecture](#simulator-architecture)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Installation](#installation)
- [How to Run](#how-to-run)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Key Performance Indicators](#key-performance-indicators)
- [Development Status](#development-status)
- [References](#references)
- [Authors](#authors)
- [License](#license)

---

## Overview

LEO non-terrestrial networks are characterized by highly dynamic operating conditions.  
Unlike static terrestrial infrastructures, LEO satellites move rapidly with respect to ground users, leading to:

- short visibility intervals,
- frequent handovers,
- time-varying channel conditions,
- dynamic load distribution.

For this reason, user–satellite association in LEO constellations cannot be treated as a static optimization problem.  
NAPOLEON+ provides a modular simulation environment for studying association strategies under realistic geometric and channel constraints, and for evaluating them through system-level KPIs.

---

## Main Features

- Simulation of a LEO satellite network scenario over a configurable time window
- Ground-user and environment modeling
- Constellation and visibility modeling
- Ground-to-satellite channel characterization
- User–satellite association strategy implementation
- Handover and soft-handover logic
- KPI computation and performance post-processing
- Graphical user interface for simulation setup and result visualization

---

## Simulator Architecture

The simulator is organized into five high-level modules:

### 1. Channel Model Module
Responsible for defining the physical simulation context and deriving the communication conditions of visible links::
- user distribution,
- environment parameters,
- constellation description,
- visibility relations between users and satellites;

- channel states,
- propagation parameters,
- channel coefficients,
- link-quality indicators.

### 2. Association and Handover Module
Core decision layer of the simulator:
- baseline user–satellite association,
- potentially load-balancing logic,
- handover and soft-handover management.

### 3. KPI Evaluation Module
Responsible for performance assessment:
- sum bit rate,
- handover frequency,
- additional system-level metrics.

### 4. GUI Layer
Provides:
- simulation parameter configuration,
- execution control,
- result visualization.

---

## Project Structure

```text
NAPOLEON_PLUS/
│
├── /src
│ 	├── NAPOLEON_plus_1.m
│ 	├── /ChannelModel
│ 	├── /UserSatAssoc
│ 	├── /KPIs
│ 	└── /GUI
├── data/
│ 		…
│
├── tests/
│ 		…
│ 		
├── docs/
│ 		…
│
└── README.md
```

---

## Requirements

NAPOLEON+ is developed and executed in the MATLAB environment. The following software components are required:

- MATLAB
- Satellite Communications Toolbox
- MATLAB App Designer

The Satellite Communications Toolbox is required to model satellite scenarios, satellite orbits, ground stations, visibility conditions, and related geometric operations. MATLAB App Designer is used for the graphical user interface, which allows the user to configure simulation parameters, run the simulator, and visualize the results. The project has not yet been tested across different MATLAB releases. For this reason, it is recommended to use a recent MATLAB version with full support for the Satellite Communications Toolbox.

---

## Installation

To install and run NAPOLEON+, clone the repository locally (being developed rn):

```bash
git clone <repository-url>
cd NAPOLEON_PLUS
```

---

## How to Run

After cloning the repository and opening MATLAB from the repository root folder, add the source directory to the MATLAB path:

```matlab
addpath(genpath("src"))
```
Then launch the simulator by running:

```matlab
run("src/NAPOLEON_plus_1.m")
```
---

## References

NAPOLEON+ is (currently being) developed following the academic literature and technical documentations here listed.

### User–Satellite Association and Handover
- A. Z. Khalifeh, *Optimization of User–LEO Satellite Assignments*, Master’s Thesis, Politecnico di Torino, 2024–2025.  
  Main reference for the user–satellite assignment problem, dual-connectivity logic, Hungarian/Munkres-based optimization, link-quality-aware association, and KPI evaluation.
- H. Ben Salem, A. Tarable, A. Nordio, and B. Makki, “Uplink Soft Handover for LEO Constellations: How Strong the Inter-Satellite Link Should Be.”  
  Reference for soft-handover concepts in LEO constellations, inter-satellite-link-assisted handover, and the comparison between hard and soft handover strategies.

### Channel and Propagation Modeling
- ITU-R Recommendation P.681-10, *Propagation Data Required for the Design of Earth-Space Land Mobile Telecommunication Systems*, International Telecommunication Union, 2017.  
  Main reference for land mobile-satellite propagation effects, including shadowing, blockage, multipath, and environment-dependent channel behavior.

### LEO Constellation Modeling and Real-World Constellation Data

- J. Liang, A. U. Chaudhry, and H. Yanikomeroglu, “Phasing Parameter Analysis for Satellite Collision Avoidance in Starlink and Kuiper Constellations.”  
  Used as a reference for Walker constellation phasing, inter-plane satellite spacing, and the impact of the phasing parameter on constellation geometry.
- Federal Communications Commission, *Order and Authorization and Order on Reconsideration: Space Exploration Holdings, LLC Request for Modification of the Authorization for the SpaceX NGSO Satellite System*, FCC 21-48, 2021.  
  Used as a reference for Starlink NGSO constellation parameters, orbital shell, operational altitudes, inclinations, and minimum elevation-angle assumptions.

---

## Development Status: in developing. 
ChannelModel module under development; UserSatAssoc module under knowledge-recovery; GUI and KIPs modules untouched.

---

## Inputs
TOBEDEFINED

---

## Outputs
TOBEDEFINED

---

## Key Performance Indicators
TOBEDEFINED

---

## Authors

### Head Professor:
Alberto Tarable 

### Team: 
- Mario Pellegrino Ambrosone
- Santi La Spina
- Aditya Gohite
- Giovanni Natalizi

---

## License

This project is licensed under the MIT License.

See the [LICENSE](LICENSE) file for details.
