function mirrored = mirrorPointAcrossPlane(point,planePoint,planeNormal)
%MIRRORPOINTACROSSPLANE Reflect a point across an infinite 3-D plane.
n = planeNormal/norm(planeNormal);
mirrored = point - 2*dot(point-planePoint,n)*n;
end
