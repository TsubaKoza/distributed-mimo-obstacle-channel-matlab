function obstacles = generateObstacles3D(cfg,APpos,UEpos)
%GENERATEOBSTACLES3D Generate non-overlapping yawed building cuboids.
% Assumption: material reflection is represented by a random complex Gamma.
template = struct('center',[],'width',[],'depth',[],'height',[], ...
    'yaw',[],'reflectionCoefficient',[],'active',true);
if ~cfg.enableObstacles || cfg.numObstacles == 0 || ...
        strcmpi(cfg.scenarioMode,"rayTracingPaperReference")
    obstacles = repmat(template,0,1);
    return;
end
obstacles = repmat(template,0,1);
points = [APpos;UEpos];
for i = 1:cfg.numObstacles
    accepted = false;
    for attempt = 1:cfg.maxPlacementAttempts
        w = randRange(cfg.obstacleWidthRange);
        d = randRange(cfg.obstacleDepthRange);
        h = randRange(cfg.obstacleHeightRange);
        margin = hypot(w,d)/2 + cfg.obstacleClearance;
        if cfg.region(1,2)-cfg.region(1,1) <= 2*margin || ...
                cfg.region(2,2)-cfg.region(2,1) <= 2*margin
            error('Obstacle range is too large for the configured region.');
        end
        cxy = [cfg.region(1,1)+margin + ...
               (diff(cfg.region(1,:))-2*margin)*rand, ...
               cfg.region(2,1)+margin + ...
               (diff(cfg.region(2,:))-2*margin)*rand];
        yaw = deg2rad(randRange(cfg.obstacleYawRangeDeg));
        candidate = template;
        candidate.center = [cxy h/2];
        candidate.width = w; candidate.depth = d; candidate.height = h;
        candidate.yaw = yaw;
        mag = randRange(cfg.obstacleReflectionMagnitudeRange);
        candidate.reflectionCoefficient = mag*exp(1j*2*pi*rand);
        clearPoints = true;
        for q = 1:size(points,1)
            local = transformToObstacleLocal(points(q,:),candidate);
            insideXY = abs(local(1)) <= w/2+cfg.obstacleClearance && ...
                       abs(local(2)) <= d/2+cfg.obstacleClearance;
            if insideXY && points(q,3) <= h+cfg.obstacleClearance
                clearPoints = false; break;
            end
        end
        clearBuildings = true;
        radius = hypot(w,d)/2;
        for j = 1:numel(obstacles)
            otherRadius = hypot(obstacles(j).width,obstacles(j).depth)/2;
            if norm(cxy-obstacles(j).center(1:2)) <= ...
                    radius+otherRadius+cfg.obstacleClearance
                clearBuildings = false; break;
            end
        end
        if clearPoints && clearBuildings
            obstacles(end+1,1) = candidate; %#ok<AGROW>
            accepted = true; break;
        end
    end
    if ~accepted
        error('Could not place obstacle %d within %d attempts.',i,cfg.maxPlacementAttempts);
    end
end
end

function x = randRange(bounds)
x = bounds(1)+diff(bounds)*rand;
end
