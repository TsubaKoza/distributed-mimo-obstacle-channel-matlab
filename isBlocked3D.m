function [blocked,blockingIndices] = isBlocked3D(p0,p1,obstacles,cfg)
%ISBLOCKED3D Convenience inverse of checkLoS3D.
[available,blockingIndices] = checkLoS3D(p0,p1,obstacles,cfg);
blocked = ~available;
end
