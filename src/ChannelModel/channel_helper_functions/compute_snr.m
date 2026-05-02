%The Gain for the transmition and receiver are the linear quantities.
function snr_tensor = compute_snr(pathgain_tensor, configChannel)
         snr_tensor = (configChannel.P_sat_lin * configChannel.G_sat_lin * configChannel.G_u_lin .* pathgain_tensor)/configChannel.N_0;

end