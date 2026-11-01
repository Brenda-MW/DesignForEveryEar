function setDefaultConfiguration(model)
%setDefaultConfiguration  Put the cochlear implant model in its default case.
%   Clean speech input (no noise), cascaded multirate FIR filter bank, no
%   denoising, and channels played sequentially (interleaved stimulation).
%   These are the four block-mask parameters you would otherwise set by hand
%   on the canvas.

    model = string(model);
    set_param(model + "/Input_Source", source_type="Speech signal", noise_type="off")
    set_param(model + "/Filter bank signal processing", filter_type="Cascade multirate multi-stage FIR")
    set_param(model + "/Denoise", denoise="off")
    set_param(model + "/Speech Reconstruction", syn_mode="Play channels sequentially")
end
