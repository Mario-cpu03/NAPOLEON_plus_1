function traceBank = generate_trace_bank(configChannel)

env = ["Urban", "Suburban", "Village", "RuralWooded"];

elevationClasses = [30 45 60 70];

numEnv=numel(env);
numElev = numel(elevationClasses);

% Creation of the cell of traces, that is the set of environmentxelevation
% channel coefficients. I.e., traceBank.h2{i,j} is the cell containing the 4000
% channel coefficients of the i-th channel at the j-th elevation
traceBank.h2=cell(numEnv, numElev);
traceBank.h2Mean=zeros(numEnv, numElev);

traceBank.elevationClasses = elevationClasses;

for iEnv = 1:numEnv

    %for every environment we define the "associated" vector of channels
    %with different angles.
    for iElev = 1:numElev

        lmsChannel = p681LMSChannel( ...
            'CarrierFrequency', configChannel.carrierFrequency, ...
            'Environment',      env(iEnv), ...
            'MobileSpeed',      configChannel.mobileSpeed, ...
            'SampleRate',       configChannel.sampleRate, ...
            'ElevationAngle',   elevationClasses(iElev), ...
            'ChannelFiltering', false, ...
            'NumSamples',       configChannel.traceLengthSamples);

        % Channel coefficients of a fixed environment-elevation channel
        [pathGain, ~, ~] = lmsChannel();

        release(lmsChannel);

        % the trace h2Trace is used to obtain the time slot non-averaged
        % coefficients for the ideal model, which will be critical to obtain a
        % more ideal Rate computation
        h2Trace = abs(pathGain(:)).^2;

        traceBank.h2{iEnv,iElev} = h2Trace;

        % the h2Mean computed averaging the h2Trace is used to obtain an
        % estimation of the channel for the forecast mode.
        traceBank.h2Mean(iEnv,iElev) = mean(h2Trace);

    end
end

end