function APpos = generateAPPositions3D(cfg)
%GENERATEAPPOSITIONS3D Generate M AP centers in Cartesian coordinates.
if strcmpi(cfg.scenarioMode,"rayTracingPaperReference")
    xy = [0 0; 200 200; 0 200; 200 0; 100 200];
    APpos = [xy, cfg.zAP*ones(5,1)];
    return;
end
xy = [randomInRange(cfg.region(1,:),'M',cfg.M), ...
      randomInRange(cfg.region(2,:),'M',cfg.M)];
APpos = [xy, cfg.zAP*ones(cfg.M,1)];
end

function x = randomInRange(bounds,~,n)
x = bounds(1) + diff(bounds)*rand(n,1);
end
