function paths = findSingleBounceReflections3D(AP,UE,obstacles,antennaCoordinates,cfg)
%FINDSINGLEBOUNCEREFLECTIONS3D Image-method reflections from cuboid faces.
% This is a paper-inspired simplified 3-D reflection model, not Eq. (20)
% copied from the sensing-assisted paper.
paths = emptyPaths();
for obstacleIndex = 1:numel(obstacles)
    obstacle = obstacles(obstacleIndex);
    if isfield(obstacle,'active') && ~obstacle.active
        continue;
    end
    faces = cuboidFaces(obstacle,cfg);
    for f = 1:numel(faces)
        face = faces(f);
        mirrorUE = mirrorPointAcrossPlane(UE,face.center,face.normal);
        [reflectionPoint,~,valid] = linePlaneIntersection( ...
            AP,mirrorUE,face.center,face.normal,cfg.epsGeom);
        if ~valid || ~pointInsideRectangle3D(reflectionPoint,face.center, ...
                face.uAxis,face.vAxis,face.halfU,face.halfV,cfg.epsGeom)
            continue;
        end
        if norm(reflectionPoint-AP) < cfg.minPathLength || ...
                norm(UE-reflectionPoint) < cfg.minPathLength
            continue;
        end
        [firstClear,~] = checkLoS3D(AP,reflectionPoint,obstacles,cfg);
        [secondClear,~] = checkLoS3D(reflectionPoint,UE,obstacles,cfg);
        if ~(firstClear && secondClear)
            continue;
        end
        d1 = norm(reflectionPoint-AP);
        d2 = norm(UE-reflectionPoint);
        totalLength = d1+d2;
        aod = computeAoAAoD3D(AP,reflectionPoint);
        aoa = computeAoAAoD3D(AP,reflectionPoint); % AP bearing of arriving ray
        gain = computePathGain(totalLength,obstacle.reflectionCoefficient,cfg);
        arrayResponse = computeArrayResponse3D(antennaCoordinates,AP, ...
            aod.direction,cfg);
        item = struct('type',"reflection",'length',totalLength, ...
            'reflectionPoint',reflectionPoint,'AoA',aoa,'AoD',aod, ...
            'complexGain',gain,'obstacleIndex',obstacleIndex, ...
            'faceName',face.name,'contribution',gain*arrayResponse, ...
            'diffractionPoint',[NaN NaN NaN],'edgeName',"", ...
            'diffractionParameter',NaN,'diffractionLossdB',NaN);
        paths(end+1,1) = item; %#ok<AGROW>
    end
end
end

function faces = cuboidFaces(o,cfg)
c = cos(o.yaw); s = sin(o.yaw);
ex = [c s 0]; ey = [-s c 0]; ez = [0 0 1];
faces = repmat(struct('name',"",'center',[],'normal',[], ...
    'uAxis',[],'vAxis',[],'halfU',[],'halfV',[]),0,1);
if cfg.enableSideReflection
    faces(end+1) = makeFace("+x",o.center+(o.width/2)*ex,ex,ey,ez,o.depth/2,o.height/2);
    faces(end+1) = makeFace("-x",o.center-(o.width/2)*ex,-ex,ey,ez,o.depth/2,o.height/2);
    faces(end+1) = makeFace("+y",o.center+(o.depth/2)*ey,ey,ex,ez,o.width/2,o.height/2);
    faces(end+1) = makeFace("-y",o.center-(o.depth/2)*ey,-ey,ex,ez,o.width/2,o.height/2);
end
if cfg.enableRoofReflection
    faces(end+1) = makeFace("roof",o.center+(o.height/2)*ez,ez,ex,ey,o.width/2,o.depth/2);
end
if cfg.enableGroundReflection
    faces(end+1) = makeFace("bottom",o.center-(o.height/2)*ez,-ez,ex,ey,o.width/2,o.depth/2);
end
end

function face = makeFace(name,center,normal,uAxis,vAxis,halfU,halfV)
face = struct('name',name,'center',center,'normal',normal, ...
    'uAxis',uAxis,'vAxis',vAxis,'halfU',halfU,'halfV',halfV);
end

function p = emptyPaths()
p = repmat(struct('type',"",'length',[],'reflectionPoint',[], ...
    'AoA',[],'AoD',[],'complexGain',[],'obstacleIndex',[], ...
    'faceName',"",'contribution',[],'diffractionPoint',[], ...
    'edgeName',"",'diffractionParameter',[],'diffractionLossdB',[]),0,1);
end
