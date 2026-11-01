function reqs = functionalRequirements(rs)
%functionalRequirements  Return the functional requirements in editor order.
%   REQS = functionalRequirements(RS) returns the individual functional
%   requirements in requirement set RS, dropping the "SP" and "ST" group
%   headings that only organize them into categories. The requirements are
%   returned in the same outline order shown in the Requirements Editor (by
%   each requirement's hierarchical Index, e.g. 1.1, 1.2, 1.2.1), which is not
%   the order rs.find returns.

    all = rs.find(Type="Requirement");
    isGroup = ismember(string({all.Id}), ["SP" "ST"]);
    reqs = all(~isGroup);

    % Sort by the hierarchical Index so the order matches the editor outline.
    parts = arrayfun(@(r) sscanf(r.Index, "%d.").', reqs, UniformOutput=false);
    width = max(cellfun(@numel, parts));
    keys  = cellfun(@(p) [p, zeros(1, width - numel(p))], parts, UniformOutput=false);
    [~, order] = sortrows(vertcat(keys{:}));
    reqs = reqs(order);
end
