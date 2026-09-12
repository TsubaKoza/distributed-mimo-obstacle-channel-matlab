function [paths,retainMask,stats] = pruneRayPaths(paths,cfg)
%PRUNERAYPATHS Annotate and prune rays relative to one link's strongest ray.
% Every generated ray remains in paths. retainMask and isRetained determine
% which contributions are coherently summed into h_true.

numPaths = numel(paths);
retainMask = false(numPaths,1);
stats = struct('numPathsBeforePruning',numPaths, ...
    'numPathsAfterPruning',0,'strongestPathPowerdB',-Inf, ...
    'strongestPathIndex',NaN,'strongestPathType',"");
if numPaths == 0
    return;
end

pathPower = zeros(numPaths,1);
for l = 1:numPaths
    pathPower(l) = sum(abs(paths(l).contribution).^2);
end
[strongestPower,strongestIndex] = max(pathPower);

pathPowerdB = -Inf(numPaths,1);
positivePower = pathPower > 0;
pathPowerdB(positivePower) = 10*log10(pathPower(positivePower));
if strongestPower > 0
    relativePowerdB = -Inf(numPaths,1);
    relativePowerdB(positivePower) = 10*log10( ...
        pathPower(positivePower)/strongestPower);
else
    % All rays have zero power. They are tied, so no ray is weaker than
    % another and no NaN-producing 0/0 ratio is evaluated.
    relativePowerdB = zeros(numPaths,1);
end

if cfg.enablePathPruning
    % A ray exactly threshold dB below the maximum is removed.
    retainMask = relativePowerdB > -cfg.pathPruningThresholddB;
    retainMask(strongestIndex) = true;
else
    retainMask(:) = true;
end

for l = 1:numPaths
    paths(l).pathPower = pathPower(l);
    paths(l).pathPowerdB = pathPowerdB(l);
    paths(l).relativePowerdB = relativePowerdB(l);
    paths(l).isRetained = retainMask(l);
end

stats.numPathsAfterPruning = nnz(retainMask);
stats.strongestPathPowerdB = pathPowerdB(strongestIndex);
stats.strongestPathIndex = strongestIndex;
stats.strongestPathType = string(paths(strongestIndex).type);
end
