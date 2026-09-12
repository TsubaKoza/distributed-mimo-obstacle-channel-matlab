function localPoint = transformToObstacleLocal(globalPoint,obstacle)
%TRANSFORMTOOBSTACLELOCAL Rotate a global point into cuboid coordinates.
c = cos(obstacle.yaw); s = sin(obstacle.yaw);
RglobalToLocal = [c s 0; -s c 0; 0 0 1];
localPoint = (RglobalToLocal*(globalPoint-obstacle.center).').';
end
