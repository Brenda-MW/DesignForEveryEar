function channels = logChannelActivation(model)
%logChannelActivation  Log the eight-channel bus feeding the Demux.
%   CHANNELS = logChannelActivation(MODEL) runs the model and returns the
%   eight filter-bank channel signals as a [time x 8] matrix ordered Ch0..Ch7.
%   It logs the bus that feeds the Demux, simulates, then restores the port's
%   logging state so the model is left clean.

    model = string(model);

    demux   = model + "/Demux";
    busPort = get_param(get_param(get_param(demux, "PortHandles").Inport(1), "Line"), "SrcPortHandle");

    % Save and restore the port's logging settings around the run.
    oldLog  = get_param(busPort, "DataLogging");
    oldMode = get_param(busPort, "DataLoggingNameMode");
    oldName = get_param(busPort, "DataLoggingName");
    cleanup = onCleanup(@() set_param(busPort, ...
        DataLogging=oldLog, DataLoggingNameMode=oldMode, DataLoggingName=oldName));

    set_param(busPort, DataLogging="on", DataLoggingNameMode="Custom", DataLoggingName="channels")
    out = sim(Simulink.SimulationInput(char(model)));

    channels = squeeze(out.logsout.getElement("channels").Values.Data);
    if size(channels, 1) == 8, channels = channels.'; end   % make it [time x 8]
    channels = fliplr(channels);                            % reorder Demux ports to Ch0..Ch7
end
