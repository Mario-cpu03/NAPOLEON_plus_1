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

### 1. Scenario and Geometry Module
Responsible for defining the physical simulation context:
- user distribution,
- environment parameters,
- constellation description,
- visibility relations between users and satellites.

### 2. Channel Modeling Module
Responsible for deriving the communication conditions of visible links:
- channel states,
- propagation parameters,
- channel coefficients,
- link-quality indicators.

### 3. Association and Handover Module
Core decision layer of the simulator:
- baseline user–satellite association,
- load-balancing logic,
- handover and soft-handover management.

### 4. KPI Evaluation Module
Responsible for performance assessment:
- sum bit rate,
- handover frequency,
- additional system-level metrics.

### 5. GUI Layer
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
│ 		…
├── data/
│ 		…
│
├── tests/
│ 		…
├── docs/
│ 		…
│
└── README.md


---

## Authors

# Head Professor:
Alberto Tarable 

# Team: 
Mario Pellegrino Ambrosone
Santi La Spina
Aditya Gohite
Giovanni Natalizi
