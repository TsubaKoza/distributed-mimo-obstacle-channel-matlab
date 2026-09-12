function [available,blockingIndices] = checkLoS3D(p0,p1,obstacles,cfg,ignoreIndices)
%CHECKLOS3D True only when the open 3-D segment misses every active cuboid.
if nargin<5, ignoreIndices=[]; end
blockingIndices = [];
for i = 1:numel(obstacles)
    if any(i==ignoreIndices), continue; end
    if isfield(obstacles(i),'active') && ~obstacles(i).active
        continue;
    end
    if segmentIntersectsCuboid(p0,p1,obstacles(i),cfg)
        blockingIndices(end+1) = i; %#ok<AGROW>
    end
end
available = isempty(blockingIndices);
end
