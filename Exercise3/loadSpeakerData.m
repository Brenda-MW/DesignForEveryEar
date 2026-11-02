function data = loadSpeakerData(file)
%loadSpeakerData  Load the workshop speaker data with single-precision features.
%   DATA = loadSpeakerData(FILE) loads FILE and converts each feature set
%   (xTrain, xValidation, xTest, xEnroll, xDET) from 8-bit integers back to
%   single-precision MFCC features. The features are stored as 8-bit integers,
%   with a per-feature offset and scale, to keep the download small. The
%   rounding error does not measurably change the network's accuracy.

data = load(file);
for v = ["xTrain" "xValidation" "xTest" "xEnroll" "xDET"]
    data.(v) = cellfun(@(c) single(c) .* data.featureScale + data.featureOffset, ...
        data.(v), UniformOutput=false);
end
data = rmfield(data, ["featureOffset" "featureScale"]);
end
