%% DOCUMENT FOR ADVANCED QUANTITIES LISTING AND EXPLANATION

%% The advanced features are optional quantities
% They may be computed from USER_SAT_evolution when required by a 
% specific association policy.
%
% We define:
%       features.remainingVisibilitySamples
%       features.remainingVisibilityTime
%       features.remainingServiceTime
%       features.elevationRate
%       features.elevationMargin
%       features.latencyMatrix
%       features.outageProbability
%       features.reliabilityScore
%       features.linkStabilityScore
%       features.energyCost
%       features.SNRMargin
%       features.availableLinkMask
%       features.dopplerProxy
%       features.predictedRate
%
% Some of those quantities depend on assignment history, thus it is
% preferable to delay their computation in UserSatAssoc. 
% Namely we can define the assocFeatures as:
%       assocFeatures.handoverPenaltyMatrix
%       assocFeatures.loadPenaltyMatrix
%       assocFeatures.fairnessBoost
%       assocPolicy.weightMatrix
%
% Even if we may call them Matrix, each of these object is a tensor.
% Precisely, it is a tensor following the convention:
%       u = user index,       u = 1,...,U
%       s = satellite index,  s = 1,...,S
%       t = time index,       t = 1,...,T
% With fixed size [U x S x T]


%% %% %% ---- PER FEATURE DESCRIPTION ---- %% %% %%

%% Tensor: features.remainingVisibilitySamples
% Name:
%       features.remainingVisibilitySamples(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Number of consecutive future samples, starting from time t, for
%       which the link (u,s) remains geometrically visible.
%
% Mathematical expression:
%       N_rem(u,s,t) = max N such that:
%
%           validLinkMask(u,s,tau) = 1,
%           for all tau = t, t+1, ..., t+N-1.
%
%       If validLinkMask(u,s,t) = 0, then:
%
%           N_rem(u,s,t) = 0.
%
% Explanation:
%       This tensor tells how many future simulation samples the satellite
%       remains visible to the user. It is useful for handover-aware
%       association because it discourages selecting satellites that are
%       about to disappear from visibility.
%
% Possible use:
%       W(u,s,t) = R(u,s,t) + alpha*N_rem(u,s,t)

%% Tensor: features.remainingVisibilityTime
% Name:
%       features.remainingVisibilityTime(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Remaining geometric visibility time of link (u,s), expressed in
%       seconds.
%
% Mathematical expression:
%       T_rem(u,s,t) = DeltaT * N_rem(u,s,t)
%
% where:
%       DeltaT          = simulation sampling time [s]
%       N_rem(u,s,t)   = features.remainingVisibilitySamples(u,s,t)
%
% Explanation:
%       This is the time-domain version of remainingVisibilitySamples.
%       A larger value means that the user-satellite link is expected to
%       remain geometrically feasible for longer.
%
% Possible use:
%       W(u,s,t) = R(u,s,t) + alpha*T_rem(u,s,t)

%% Tensor: features.elevationRate
% Name:
%       features.elevationRate(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Time derivative of the elevation angle of satellite s as observed
%       by user u.
%
% Mathematical expression:
%       For internal samples:
%
%           theta_dot(u,s,t) =
%               [theta(u,s,t+1) - theta(u,s,t-1)] / (2*DeltaT)
%
%       At the first sample:
%
%           theta_dot(u,s,1) =
%               [theta(u,s,2) - theta(u,s,1)] / DeltaT
%
%       At the last sample:
%
%           theta_dot(u,s,T) =
%               [theta(u,s,T) - theta(u,s,T-1)] / DeltaT
%
% where:
%       theta(u,s,t) = USER_SAT_evolution.geometry.elevationMatrix(u,s,t)
%
% Units:
%       deg/s
%
% Explanation:
%       Positive values indicate that the satellite is rising in the sky.
%       Negative values indicate that the satellite is setting. This is
%       useful because a satellite with high current elevation but rapidly
%       decreasing elevation may soon become unsuitable.
%
% Possible use:
%       W(u,s,t) = R(u,s,t) - beta*max(0,-theta_dot(u,s,t))

%% Tensor: features.latencyMatrix
% Name:
%       features.latencyMatrix(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       One-way propagation delay between user u and satellite s.
%
% Mathematical expression:
%       tau_prop(u,s,t) = d(u,s,t) / c
%
% where:
%       d(u,s,t) = slant distance [m]
%       c        = speed of light [m/s]
%
% If distance is stored in km:
%
%       tau_prop(u,s,t) =
%           USER_SAT_evolution.geometry.distanceMatrix(u,s,t)*1e3 / c
%
% Units:
%       seconds
%
% Explanation:
%       This tensor estimates the pure propagation latency of the link.
%       It is especially useful for low-latency service classes.
%
% Possible use:
%       W(u,s,t) = R(u,s,t) - beta*tau_prop(u,s,t)

%% Tensor: features.outageProbability
% Name:
%       features.outageProbability(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Probability that the SNR of link (u,s) at time t falls below a
%       required threshold.
%
% Mathematical expression:
%       P_out(u,s,t) = Pr{ gamma(u,s,t) < gamma_min }
%
% where:
%       gamma(u,s,t) = link SNR
%       gamma_min    = minimum required SNR
%
% If multiple fading/channel realizations are available:
%
%       P_out(u,s,t) ~= N_out(u,s,t) / N_realizations
%
% If only one instantaneous realization is available, use the binary
% outage indicator instead:
%
%       outageIndicator(u,s,t) =
%           1, if gamma(u,s,t) < gamma_min
%           0, otherwise.
%
% Explanation:
%       This tensor measures reliability from an outage perspective.
%       A high value means that the link frequently fails to satisfy the
%       required SNR threshold.
%
% Possible use:
%       W(u,s,t) = R(u,s,t) - beta*P_out(u,s,t)


%% Tensor: features.outageIndicator
% Name:
%       features.outageIndicator(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Binary indicator of whether link (u,s) is in outage at time t.
%
% Mathematical expression:
%       I_out(u,s,t) =
%           1, if gamma(u,s,t) < gamma_min
%           0, otherwise.
%
% Explanation:
%       This is a deterministic sample-level version of outage probability.
%       It is useful when only one instantaneous channel realization is
%       available per time sample.
%
% Possible use:
%       availableLinkMask(u,s,t) =
%           validLinkMask(u,s,t) AND NOT outageIndicator(u,s,t)

%% Tensor: features.reliabilityScore
% Name:
%       features.reliabilityScore(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Normalized reliability score of link (u,s) at time t.
%
% Mathematical expression:
%       If outage probability is available:
%
%           Reliability(u,s,t) = 1 - P_out(u,s,t)
%
%       If only SNR margin is available:
%
%           margin_SNR(u,s,t) =
%               gamma_dB(u,s,t) - gamma_min_dB
%
%       and a sigmoid mapping may be used:
%
%           Reliability(u,s,t) =
%               1 / (1 + exp(-a*margin_SNR(u,s,t)))
%
% where:
%       a = sigmoid steepness parameter.
%
% Range:
%       0 <= Reliability(u,s,t) <= 1
%
% Explanation:
%       This tensor expresses how likely the link is to satisfy a service
%       requirement. It is useful for reliability-aware or URLLC-like
%       association policies.
%
% Possible use:
%       W(u,s,t) =
%           alpha*R(u,s,t) + beta*Reliability(u,s,t)


%% Tensor: features.linkStabilityScore
% Name:
%       features.linkStabilityScore(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Composite score measuring the expected temporal/geometric stability
%       of a user-satellite link.
%
% Mathematical expression:
%       S_stab(u,s,t) =
%           a*T_rem(u,s,t)
%         + b*theta(u,s,t)
%         - c*abs(theta_dot(u,s,t))
%
% where:
%       T_rem(u,s,t)       = remaining visibility time [s]
%       theta(u,s,t)       = elevation angle [deg]
%       theta_dot(u,s,t)   = elevation rate [deg/s]
%       a,b,c              = tunable positive coefficients
%
% Explanation:
%       A stable link is one that remains visible for a long time, has good
%       elevation, and does not vary too rapidly. This is not a direct
%       physical observable; it is a policy feature for robust association.
%
% Possible use:
%       W(u,s,t) =
%           alpha*R(u,s,t) + beta*S_stab(u,s,t)


%% Tensor: features.energyCost
% Name:
%       features.energyCost(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Energy or transmit-power cost proxy required to sustain link
%       (u,s) at time t.
%
% Mathematical expression:
%       If a target SNR gamma_req is imposed:
%
%           P_req(u,s,t) =
%               gamma_req * N0 / G_link(u,s,t)
%
% where:
%       gamma_req   = required SNR in linear scale
%       N0          = noise power
%       G_link      = total channel/link gain in linear scale
%
% In dB:
%
%           P_req_dB(u,s,t) =
%               gamma_req_dB + N0_dB - G_link_dB(u,s,t)
%
% Explanation:
%       Links with larger path loss or lower channel gain require more
%       transmit power to satisfy the same target quality. This tensor is
%       useful for energy-aware or power-constrained association policies.
%
% Possible use:
%       W(u,s,t) =
%           R(u,s,t) - beta_E*energyCost(u,s,t)

%% Tensor: features.remainingServiceTime
% Name:
%       features.remainingServiceTime(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Consecutive future time for which a link remains not only visible,
%       but also service-compliant.
%
% Mathematical expression:
%       Define:
%
%           serviceMask(u,s,t) =
%               validLinkMask(u,s,t)
%               AND SNR(u,s,t) >= gamma_min
%               AND R(u,s,t) >= R_min
%
%       Then:
%
%           T_service_rem(u,s,t) =
%               DeltaT * number of consecutive future samples tau >= t
%               for which serviceMask(u,s,tau) = 1.
%
% Explanation:
%       Remaining visibility time asks:
%
%           "How long is the satellite geometrically visible?"
%
%       Remaining service time asks:
%
%           "How long is the satellite expected to provide acceptable
%            service?"
%
%       This is more meaningful for service-specific association policies.
%
% Possible use:
%       W(u,s,t) =
%           R(u,s,t) + alpha*T_service_rem(u,s,t)


%% Tensor: features.elevationMargin
% Name:
%       features.elevationMargin(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Difference between the current elevation angle and the minimum
%       elevation threshold.
%
% Mathematical expression:
%       margin_theta(u,s,t) =
%           theta(u,s,t) - theta_min
%
% where:
%       theta(u,s,t) = elevation angle [deg]
%       theta_min    = minimum elevation threshold [deg]
%
% Explanation:
%       A small positive margin means that the satellite is barely above
%       the required threshold. A larger margin usually indicates a more
%       robust geometric condition and lower obstruction probability.
%
% Possible use:
%       W(u,s,t) =
%           R(u,s,t) + alpha*margin_theta(u,s,t)


%% Tensor: features.SNRMargin
% Name:
%       features.SNRMargin(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Difference between the current SNR and the minimum service-required
%       SNR.
%
% Mathematical expression:
%       margin_SNR(u,s,t) =
%           gamma_dB(u,s,t) - gamma_min_dB
%
% where:
%       gamma_dB(u,s,t) = SNR [dB]
%       gamma_min_dB    = required SNR threshold [dB]
%
% Explanation:
%       A positive SNR margin means that the link satisfies the service
%       requirement. A larger margin means more robustness against fading,
%       shadowing, and interference.
%
% Possible use:
%       Reliability(u,s,t) =
%           1 / (1 + exp(-a*margin_SNR(u,s,t)))


%% Tensor: features.availableLinkMask
% Name:
%       features.availableLinkMask(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Service-aware link feasibility mask.
%
% Mathematical expression:
%       availableLinkMask(u,s,t) =
%           validLinkMask(u,s,t)
%           AND SNR(u,s,t) >= gamma_min
%           AND R(u,s,t) >= R_min
%
% Explanation:
%       A link can be geometrically visible but not useful for a specific
%       service if the SNR or rate is too low. This tensor captures links
%       that are feasible from both geometry and service-quality
%       perspectives.
%
% Possible use:
%       W_t(~availableLinkMask(:,:,t)) = -Inf


%% Tensor: features.dopplerShift
% Name:
%       features.dopplerShift(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Estimated Doppler shift of link (u,s) at time t.
%
% Mathematical expression:
%       If radial relative velocity is known:
%
%           f_D(u,s,t) =
%               [v_radial(u,s,t) / c] * f_c
%
% where:
%       v_radial = relative radial velocity [m/s]
%       c        = speed of light [m/s]
%       f_c      = carrier frequency [Hz]
%
% Explanation:
%       Doppler shift is relevant in LEO systems because satellites move
%       rapidly. High Doppler may increase synchronization complexity and
%       reduce link robustness.
%
% Possible use:
%       W(u,s,t) =
%           R(u,s,t) - beta_D*abs(f_D(u,s,t))


%% Tensor: features.dopplerProxy
% Name:
%       features.dopplerProxy(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Approximate Doppler-related feature based on the time derivative of
%       slant distance.
%
% Mathematical expression:
%       v_radial_proxy(u,s,t) =
%           [d(u,s,t+1) - d(u,s,t-1)] / (2*DeltaT)
%
%       Then:
%
%           f_D_proxy(u,s,t) =
%               [v_radial_proxy(u,s,t) / c] * f_c
%
% Explanation:
%       This is not a full Doppler computation unless distance evolution is
%       sufficiently accurate and time sampling is adequate. It is useful as
%       a lightweight feature when velocity vectors are not available.
%
% Possible use:
%       W(u,s,t) =
%           R(u,s,t) - beta_D*abs(f_D_proxy(u,s,t))


%% Tensor: features.predictedRate
% Name:
%       features.predictedRate(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Short-horizon predicted average achievable rate for link (u,s)
%       starting at time t.
%
% Mathematical expression:
%       For prediction horizon H:
%
%           R_pred(u,s,t) =
%               (1/H_eff) * sum_{tau=t}^{min(t+H,T)} R(u,s,tau)
%
%       where only valid future samples may be included:
%
%           validLinkMask(u,s,tau) = 1.
%
% Explanation:
%       This feature favors links that are not only good now, but expected
%       to remain good over the next samples.
%
% Possible use:
%       W(u,s,t) = R_pred(u,s,t)


%% Tensor: features.predictedSNR
% Name:
%       features.predictedSNR(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Short-horizon predicted average SNR for link (u,s) starting at time
%       t.
%
% Mathematical expression:
%       For prediction horizon H:
%
%           SNR_pred(u,s,t) =
%               (1/H_eff) * sum_{tau=t}^{min(t+H,T)} SNR(u,s,tau)
%
%       where only valid future samples may be included.
%
% Explanation:
%       This can be used when the association policy is based on predicted
%       channel quality rather than instantaneous channel quality.
%
% Possible use:
%       W(u,s,t) =
%           alpha*SNR_pred(u,s,t)


%% Tensor: assocFeatures.handoverPenaltyMatrix
% Name:
%       assocFeatures.handoverPenaltyMatrix(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Penalty applied when user u would need to switch to satellite s at
%       time t.
%
% Mathematical expression:
%       Let A_u(t-1) be the set of satellites assigned to user u at the
%       previous time sample.
%
%       H_cand(u,s,t) =
%           0, if s belongs to A_u(t-1)
%           1, otherwise.
%
%       The effective handover-aware weight is:
%
%           W_eff(u,s,t) =
%               W_link(u,s,t) - lambda_H*H_cand(u,s,t)
%
% Explanation:
%       This tensor discourages unnecessary satellite changes. It depends
%       on the previous assignment, therefore it belongs naturally to the
%       UserSatAssoc module rather than to Channel_model.
%
% Possible use:
%       W_eff = W_link - lambda_H*handoverPenaltyMatrix


%% Tensor: assocFeatures.loadPenaltyMatrix
% Name:
%       assocFeatures.loadPenaltyMatrix(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Penalty associated with assigning user u to a satellite s that is
%       already heavily loaded.
%
% Mathematical expression:
%       Let:
%
%           L(s,t) = sum_u x(u,s,t)
%
%       be the number of users assigned to satellite s at time t.
%
%       If G is the maximum satellite capacity:
%
%           L_norm(s,t) = L(s,t) / G
%
%       A possible load penalty is:
%
%           P_load(u,s,t) = beta_L * L_norm(s,t)
%
% Explanation:
%       This tensor discourages concentrating too many users on the same
%       satellite. In strict formulations, satellite load is handled by the
%       capacity constraint. In heuristic or soft-constraint versions, it
%       can be included as a penalty.
%
% Possible use:
%       W_eff(u,s,t) =
%           W_link(u,s,t) - P_load(u,s,t)
%
% Important:
%       Since load depends on the assignment decision, this tensor is
%       usually computed inside UserSatAssoc.


%% Tensor: assocFeatures.fairnessBoost
% Name:
%       assocFeatures.fairnessBoost(u,t)
%
% Size:
%       [numUsers x numTimeSteps]
%
% Definition:
%       User-level boost applied to users that have experienced low service
%       quality in the past.
%
% Mathematical expression:
%       Let:
%
%           R_avg(u,t)
%
%       be the historical average throughput of user u before time t.
%
%       A simple fairness boost is:
%
%           F(u,t) = 1 / (epsilon + R_avg(u,t))
%
%       A proportional-fair weight may also be:
%
%           W_eff(u,s,t) =
%               R(u,s,t) / (epsilon + R_avg(u,t))
%
% Explanation:
%       Users with poor historical service receive a larger priority. This
%       prevents the optimizer from always favoring users with naturally
%       better geometry or channel conditions.
%
% Possible use:
%       W_eff(u,s,t) =
%           R(u,s,t) + gamma_F*F(u,t)
%
% Important:
%       This quantity depends on historical assigned performance, so it
%       belongs to UserSatAssoc or KPI-feedback logic.


%% Tensor: assocPolicy.weightMatrix
% Name:
%       assocPolicy.weightMatrix(u,s,t)
%
% Size:
%       [numUsers x numSats x numTimeSteps]
%
% Definition:
%       Final policy-dependent score used by the assignment algorithm.
%
% Mathematical expression:
%       A general composite utility can be:
%
%           W(u,s,t) =
%               alpha_R * R(u,s,t)
%             + alpha_S * S_stab(u,s,t)
%             + alpha_Q * Reliability(u,s,t)
%             - beta_L  * Latency(u,s,t)
%             - beta_H  * HandoverPenalty(u,s,t)
%             - beta_E  * EnergyCost(u,s,t)
%
% Explanation:
%       This tensor is not a physical channel quantity. It is the final
%       optimization utility seen by the Hungarian/Munkres assignment
%       algorithm.
%
% Example policies:
%       eMBB:
%           W = R
%
%       URLLC-like:
%           W = alpha*Reliability - beta*Latency
%
%       Handover-aware:
%           W = R + alpha*T_rem - beta*HandoverPenalty
%
% Important:
%       This tensor should usually be built inside UserSatAssoc because it
%       depends on the selected association policy.

