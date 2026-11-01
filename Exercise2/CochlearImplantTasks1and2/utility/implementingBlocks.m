function labels = implementingBlocks(reqs)
%implementingBlocks  Name the block implementing each requirement.
%   LABELS = implementingBlocks(REQS) returns a string array with one entry
%   per requirement in REQS, naming the linked model block(s) that realize it.
%   A requirement with no implementation link is reported as "(not linked)".

    labels = strings(numel(reqs), 1);
    for k = 1:numel(reqs)
        links = slreq.inLinks(reqs(k));
        links = links(arrayfun(@(L) L.Type == "Implement", links));
        if isempty(links)
            labels(k) = "(not linked)";
        else
            names = arrayfun(@(L) string(L.getSourceLabel()), links);
            labels(k) = strjoin(names, "; ");
        end
    end
end
