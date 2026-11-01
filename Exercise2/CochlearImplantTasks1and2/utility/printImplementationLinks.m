function printImplementationLinks(reqs)
%printImplementationLinks  Print a clickable link to each implementing block.
%   printImplementationLinks(REQS) prints one line per requirement in REQS with
%   a clickable hyperlink that opens the model and selects the block that
%   implements it. Links are printed to the output (not a table cell), where
%   the Live Editor renders them as clickable; a table shows HTML as plain text.

    for k = 1:numel(reqs)
        links = slreq.inLinks(reqs(k));
        links = links(arrayfun(@(L) L.Type == "Implement", links));
        if isempty(links)
            fprintf("%-8s (not linked)\n", reqs(k).Id);
            continue
        end
        for j = 1:numel(links)
            fprintf("%-8s <a href=""matlab:%s"">%s</a>\n", reqs(k).Id, ...
                links(j).getSourceOpenCommand(), links(j).getSourceLabel());
        end
    end
end
