function [xOut,tOut] = helperChunkSequences(x,t,chunkLength)
% helperChunkSequences Split feature sequences into fixed-length chunks.
%   [xOut,tOut] = helperChunkSequences(x,t,chunkLength) splits each
%   T-by-C sequence in the cell array x into chunks of chunkLength frames
%   and replicates the labels t accordingly. Each sequence is first padded
%   by repetition (not zeros) to a multiple of chunkLength, so the
%   statistics pooling layer is not biased by padding. A final chunk that
%   would contain more than half padding is dropped, unless the sequence
%   is shorter than one chunk.
%
%   If chunkLength is 0, x and t are returned unchanged.

arguments
    x cell
    t
    chunkLength (1,1) double {mustBeNonnegative,mustBeInteger}
end

if chunkLength == 0
    xOut = x;
    tOut = t;
    return
end

numChunks = zeros(numel(x),1);
xOut = cell(numel(x),1);
for ii = 1:numel(x)
    seq = x{ii};
    seqLength = size(seq,1);
    % Drop a final chunk with more than half padding, but keep at least one
    numChunks(ii) = max(1,round(seqLength/chunkLength));

    % Pad by repetition (or truncate) to a multiple of chunkLength, then split
    paddedSeqLength = numChunks(ii)*chunkLength;
    idx = mod(0:paddedSeqLength-1,seqLength) + 1;
    xOut{ii} = mat2cell(seq(idx,:),repmat(chunkLength,numChunks(ii),1));
end
xOut = vertcat(xOut{:});
tOut = repelem(t(:),numChunks);
end
