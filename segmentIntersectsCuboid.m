function [hit,tEnter,tExit] = segmentIntersectsCuboid(p0,p1,obstacle,cfg)
%SEGMENTINTERSECTSCUBOID Slab test in the local frame of a yawed 3-D box.
q0 = transformToObstacleLocal(p0,obstacle);
q1 = transformToObstacleLocal(p1,obstacle);
d = q1-q0;
halfSize = [obstacle.width obstacle.depth obstacle.height]/2;
tEnter = 0; tExit = 1;
for axis = 1:3
    lo = -halfSize(axis)-cfg.epsGeom;
    hi =  halfSize(axis)+cfg.epsGeom;
    if abs(d(axis)) < cfg.epsGeom
        if q0(axis) < lo || q0(axis) > hi
            hit = false; return;
        end
    else
        ta = (lo-q0(axis))/d(axis);
        tb = (hi-q0(axis))/d(axis);
        tEnter = max(tEnter,min(ta,tb));
        tExit = min(tExit,max(ta,tb));
        if tEnter > tExit
            hit = false; return;
        end
    end
end
margin = cfg.segmentEndpointMargin;
hit = max(tEnter,margin) <= min(tExit,1-margin);
end
