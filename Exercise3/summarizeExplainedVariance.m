function summarizeExplainedVariance(npca, explainedVariance)
%summarizeExplainedVariance Display projector sizes for a target explained variance.
%   summarizeExplainedVariance(NPCA) displays, for each layer analyzed by the
%   neuronPCA object NPCA, the number of principal components (the projector
%   size) needed to explain 95% of the variance in that layer's input and
%   output activations, next to the total number of components available.
%
%   summarizeExplainedVariance(NPCA,EXPLAINEDVARIANCE) uses the target
%   explained variance percentage EXPLAINEDVARIANCE, specified between 1 and
%   100. The default is 95.
%
%   Example:
%       npca = neuronPCA(net,mbq);
%       summarizeExplainedVariance(npca,99)
%
%   See also neuronPCA, compressNetworkUsingProjection.

%   Copyright 2026 The MathWorks, Inc.

arguments
    npca neuronPCA
    explainedVariance (1,1) double {mustBeBetween(explainedVariance, 1, 100)} = 95
end

numLayers  = numel(npca.LayerNames);
layerNames = string(npca.LayerNames(:));

inputProjectorSize  = zeros(numLayers,1);
inputTotal          = zeros(numLayers,1);
outputProjectorSize = zeros(numLayers,1);
outputTotal         = zeros(numLayers,1);
for i = 1:numLayers
    [inputProjectorSize(i),  inputTotal(i)]  = ...
        numComponentsForVariance(npca.InputEigenvalues{i}, explainedVariance);
    [outputProjectorSize(i), outputTotal(i)] = ...
        numComponentsForVariance(npca.OutputEigenvalues{i}, explainedVariance);
end

% Format the per-layer counts as "kept / total" and align them into columns.
inputStr  = compose("%d / %d", inputProjectorSize,  inputTotal);
outputStr = compose("%d / %d", outputProjectorSize, outputTotal);

nameWidth = max(strlength([layerNames; "Layer"]));
inWidth   = max(strlength([inputStr;  "Input"]));
outWidth  = max(strlength([outputStr; "Output"]));

fprintf("\nPrincipal components needed to explain %g%% of activation variance\n", ...
    explainedVariance);
fprintf("(shown as kept / total):\n\n");
fprintf("%-*s   %-*s   %-*s\n", nameWidth, "Layer", inWidth, "Input", outWidth, "Output");
fprintf("%s\n", repmat('-', 1, nameWidth + inWidth + outWidth + 6));
for i = 1:numLayers
    fprintf("%-*s   %-*s   %-*s\n", ...
        nameWidth, layerNames(i), inWidth, inputStr(i), outWidth, outputStr(i));
end
fprintf("\n");
end

function [numComponents, numTotal] = numComponentsForVariance(eigenvalues, targetVariance)
% Number of leading components whose cumulative variance reaches targetVariance.
numTotal = numel(eigenvalues);
cumulativeVariance = cumsum(eigenvalues(:)) / sum(eigenvalues) * 100;
numComponents = find(cumulativeVariance >= targetVariance, 1, "first");
if isempty(numComponents)
    numComponents = numTotal;
end
end
