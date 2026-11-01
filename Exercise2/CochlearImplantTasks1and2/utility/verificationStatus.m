function status = verificationStatus(reqs, results)
%verificationStatus  Map test results back to requirements.
%   STATUS = verificationStatus(REQS, RESULTS) returns a string array with one
%   entry per requirement in REQS: "Passed" or "Failed" from the matching test,
%   or "No test" if no test name carries that requirement ID. The requirement ID
%   is parsed from each test name (for example, tST02_... verifies ST-02).

    testCode = extractBetween(string({results.Name}'), "/t", "_");   % e.g. "SP01"
    testIds  = regexprep(testCode, "([A-Z]+)(\d+)", "$1-$2");        % -> "SP-01"

    status = strings(numel(reqs), 1);
    for k = 1:numel(reqs)
        idx = testIds == string(reqs(k).Id);
        if ~any(idx)
            status(k) = "No test";
        elseif results(idx).Passed
            status(k) = "Passed";
        else
            status(k) = "Failed";
        end
    end
end
