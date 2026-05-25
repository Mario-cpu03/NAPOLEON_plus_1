%% Main Function KPI Module
% The scope of this function is to evaluate the user-satellite association
% strategy selected by the end-user.
% We extract, for each user and time step, the performance
% quantities associated with the selected satellite link.
% Starting from the selected links, the function builds a compact
% user-time representation of the service actually delivered to each user:
%       (i)   assigned satellite index,
%       (ii)  selected rate,
%       (iii) selected SNR,
%       (iv)  selected propagation latency,
%       (v)   handover events.
%
% This compact representation is then used to compute:
%       (i)   general KPIs, always evaluated independently of the selected
%             association policy;
%       (ii)  algorithm-specific KPIs, evaluated according to the selected
%             association algorithm.

%%%%%% ----- INPUT PARAMETERS ----- %%%%%%
%       1. USER_SAT_association : Data Structure containing the output of
%       the UserSatAssoc module:
%                   (i) associationTensor: tensor containing the selected 
%                       user-satellite association.
%
%       2. USER_SAT_evolution : Structure containing the output of the
%       ChannelModel module.
%
%       3. configKPI : Data Structure containing the parameters needed by
%       the KPI module
%                   (i)   bandwidthHz : system bandwidth [Hz]
%                   (ii)  c : speed of light [m/s], optional. If absent,
%                         c = 3e8 m/s is used
%                   (iii)  URLLC : sub-structure containing URLLC-specific
%                         KPI thresholds
%                   (iv)   eMBB : sub-structure containing eMBB-specific KPI
%                         thresholds
%
%       4. configAssociation : Data Structure containing the information on
%       the selected association policy:
%
%                   (i) association_algorithm : string identifying the
%                       selected policy. Supported values are:
%                           "URLLC"
%                           "eMBB"

%%%%%% ----- INTERNAL DATA STRUCTURE ----- %%%%%%
%       The function internally builds selectedService, a compact structure
%       containing only [U x T] matrices:
%
%                   (i)   assignedSatIdx : matrix [U x T] containing the
%                         selected satellite index for each user and time
%                   (ii)  rate_bps : matrix [U x T] containing the selected
%                         user rate [bit/s]
%                   (iii) SNR_lin : matrix [U x T] containing the selected
%                         user SNR in linear scale
%                   (iv)  latency_s : matrix [U x T] containing the one-way
%                         propagation latency [s]
%                   (v)   handoverEvent : logical matrix [U x T] equal to
%                         true when the serving satellite of a user changes
%                         between two consecutive time steps

%%%%%% ----- OUTPUT PARAMETERS ----- %%%%%%
%       1. KPI_results : Data Structure containing the final KPI evaluation:
%
%                   (i)   metadata : simulation and algorithm information
%                   (ii)  general : general KPI results, independent of the
%                         selected association algorithm
%                   (iii) specific : algorithm-specific KPI results
%                   (iv)  selectedService : optional compact service data,
%                         stored only if configKPI.storeSelectedService is
%                         true

function []=main_KPI_function ()

end