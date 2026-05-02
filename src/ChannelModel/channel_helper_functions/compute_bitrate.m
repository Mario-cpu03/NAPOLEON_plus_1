function bitrate_tensor = compute_bitrate(snr_tensor, B)  %B is the bandwidth
         bitrate_tensor = B.*log(1+snr_tensor); 
end