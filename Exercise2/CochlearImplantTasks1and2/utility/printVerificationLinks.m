function printVerificationLinks(reqs)
%printVerificationLinks  Print a clickable link to each verifying test.
%   printVerificationLinks(REQS) prints one line per requirement in REQS with a
%   clickable hyperlink that opens the test file at the method that verifies it.
%   It reads the requirement's stored "Verify" links (test -> requirement), so
%   it mirrors printImplementationLinks. Links are printed to the output (not a
%   table cell), where the Live Editor renders them as clickable.

    for k = 1:numel(reqs)
        links = slreq.inLinks(reqs(k));
        links = links(arrayfun(@(L) L.Type == "Verify", links));
        if isempty(links)
            fprintf("%-8s (no test)\n", reqs(k).Id);
            continue
        end
        for j = 1:numel(links)
            fprintf("%-8s <a href=""matlab:%s"">%s</a>\n", reqs(k).Id, ...
                links(j).getSourceOpenCommand(), testName(links(j)));
        end
    end
end

function name = testName(link)
%testName  Recover the test method's name from the link's character range.
    src = link.source;
    snippet = extractBetween(fileread(src.artifact), src.range(1), src.range(2));
    token = regexp(snippet, "function\s+(\w+)", "tokens", "once");
    if isempty(token)
        name = string(link.getSourceLabel());   % fall back to the raw anchor label
    else
        name = string(token{1});
    end
end
