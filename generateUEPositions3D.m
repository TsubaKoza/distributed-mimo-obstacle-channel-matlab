function UEpos = generateUEPositions3D(cfg,APpos)
%GENERATEUEPOSITIONS3D Generate K UE positions separated from all APs.
if strcmpi(cfg.scenarioMode,"rayTracingPaperReference")
    xy = [50 150; 150 150; 150 100];
    UEpos = [xy, cfg.zUE*ones(3,1)];
    return;
end
UEpos = zeros(cfg.K,3);
for k = 1:cfg.K
    accepted = false;
    for attempt = 1:cfg.maxPlacementAttempts
        q = [cfg.region(1,1)+diff(cfg.region(1,:))*rand, ...
             cfg.region(2,1)+diff(cfg.region(2,:))*rand, cfg.zUE];
        prior = UEpos(1:k-1,:);
        if all(vecnorm(APpos-q,2,2) >= cfg.minAPUEDistance) && ...
                (isempty(prior) || all(vecnorm(prior-q,2,2) >= cfg.minAPUEDistance))
            UEpos(k,:) = q;
            accepted = true;
            break;
        end
    end
    if ~accepted
        error('Could not place UE %d within %d attempts.',k,cfg.maxPlacementAttempts);
    end
end
end
