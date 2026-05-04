function bitrate_tensor = compute_bitrate(snr_tensor, configChannel)  %B is the bandwidth
         bitrate_tensor = configChannel.channel_bandwidth .*log2(1+snr_tensor); 
end