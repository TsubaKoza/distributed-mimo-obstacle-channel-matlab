function angles = computeAoAAoD3D(fromPoint,toPoint)
%COMPUTEAOAAOD3D Bearing from fromPoint toward toPoint.
u = toPoint-fromPoint;
distance = norm(u);
if distance == 0
    error('Angle is undefined for coincident points.');
end
u = u/distance;
angles = struct('azimuth',atan2(u(2),u(1)), ...
    'elevation',atan2(u(3),hypot(u(1),u(2))),'direction',u);
end
