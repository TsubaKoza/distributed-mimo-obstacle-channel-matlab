function scenario = generateScenario3D(cfg)
%GENERATESCENARIO3D Generate ground-truth AP, UE, and building geometry.
APpos = generateAPPositions3D(cfg);
UEpos = generateUEPositions3D(cfg,APpos);
obstacles = generateObstacles3D(cfg,APpos,UEpos);
antennaPos = generateAPArrayPositions(APpos,cfg);
scenario = struct('APpos',APpos,'UEpos',UEpos,'obstacles',obstacles, ...
    'antennaPos',antennaPos,'mode',cfg.scenarioMode,'region',cfg.region);
assert(size(APpos,2)==3 && size(UEpos,2)==3);
assert(isequal(size(antennaPos),[size(APpos,1),cfg.N_AP,3]));
end
