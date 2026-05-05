function snrTensor = compute_snr(channelGainTensor, configChannel)

snrTensor =(configChannel.P_sat_lin * configChannel.G_sat_lin * configChannel.G_u_lin .* channelGainTensor)./ configChannel.N_0;

end