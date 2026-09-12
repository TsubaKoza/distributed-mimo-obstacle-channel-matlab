function inside = pointInsideRectangle3D(point,center,uAxis,vAxis,halfU,halfV,epsGeom)
%POINTINSIDERECTANGLE3D Test finite plane-face bounds.
delta = point-center;
inside = abs(dot(delta,uAxis)) <= halfU+epsGeom && ...
         abs(dot(delta,vAxis)) <= halfV+epsGeom;
end
