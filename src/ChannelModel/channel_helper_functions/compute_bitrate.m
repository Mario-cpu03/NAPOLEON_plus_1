function bitrateTensor = compute_bitrate(snrTensor, configChannel)

bitrateTensor = configChannel.channel_bandwidth .* log2(1 + snrTensor);

end