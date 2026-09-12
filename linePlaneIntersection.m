function [point,t,valid] = linePlaneIntersection(p0,p1,planePoint,planeNormal,epsGeom)
%LINEPLANEINTERSECTION Intersect p(t)=p0+t(p1-p0) with a plane.
d = p1-p0;
den = dot(planeNormal,d);
if abs(den) < epsGeom
    point = [NaN NaN NaN]; t = NaN; valid = false; return;
end
t = dot(planeNormal,planePoint-p0)/den;
point = p0+t*d;
valid = t > epsGeom && t < 1-epsGeom;
end
