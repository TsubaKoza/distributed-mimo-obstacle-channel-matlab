function report = runRayTracingSanityChecks()
%RUNRAYTRACINGSANITYCHECKS Verify the pilot-free ray-tracing entry point.
fprintf('Ray Tracing専用処理のsanity checksを実行します...\n');
cfg = configRayTracing3D(struct( ...
    'M',1,'K',1,'N_AP',4,'numObstacles',0, ...
    'enableObstacles',false,'enableSideReflection',false, ...
    'enableRoofReflection',false,'enableDiffraction',false, ...
    'showFigures',false,'saveFigures',false,'saveResults',false));
result = main_ray_tracing_3D(cfg);

assert(size(result.h_true,1)==cfg.N_AP);
assert(size(result.h_true,2)==1 && size(result.h_true,3)==1);
assert(result.hasLoS(1,1));
assert(result.pathCount(1,1)==1);
assert(result.numReflections(1,1)==0);
assert(result.numDiffractions(1,1)==0);
assert(~result.outageMask(1,1));
assert(~isfield(result,'p') && ~isfield(result,'Y'));
assert(~isfield(result,'h_hat_LS') && ~isfield(result,'NMSE'));
assert(max(abs(result.h_true-(result.h_LoS+result.h_reflection+ ...
    result.h_diffraction)),[],'all') < 1e-14);
assert(max(abs(result.h_true-result.h_LoS),[],'all') < 1e-14);
assert(isequal(result.selectedLink.channelTable.h_true,result.h_true(:,1,1)));
assert(result.cfg.enablePathPruning);
assert(result.pathInfo(1,1).numPathsBeforePruning==1 && ...
    result.pathInfo(1,1).numPathsAfterPruning==1);
assert(result.pathInfo(1,1).paths(1).isRetained);
assert(abs(result.pathInfo(1,1).paths(1).pathPower- ...
    sum(abs(result.h_true(:,1,1)).^2)) < 1e-20);

distance = norm(result.UEpos(1,:)-result.APpos(1,:));
expectedMagnitude = cfg.lambda/(4*pi*distance);
relativeError = max(abs(abs(result.h_true(:,1,1))-expectedMagnitude)) / ...
    expectedMagnitude;
assert(relativeError < 1e-12);

% One-link pruning example. The exact-threshold -40 dB ray must be removed.
relativeTargetdB = [0;-8;-25;-40;-45];
pathTypes = ["LoS";"reflection";"diffraction"; ...
    "reflection";"reflection"];
numExamplePaths = numel(relativeTargetdB);
examplePaths = repmat(struct('type',"",'contribution',[]), ...
    numExamplePaths,1);
for l = 1:numExamplePaths
    targetPower = 10^(relativeTargetdB(l)/10);
    phase = exp(1j*(0:cfg.N_AP-1).'*0.2*l);
    examplePaths(l).type = pathTypes(l);
    examplePaths(l).contribution = ...
        sqrt(targetPower/cfg.N_AP)*phase;
end
[prunedPaths,retainMask,pruningStats] = pruneRayPaths(examplePaths,cfg);
assert(isequal(retainMask,[true;true;true;false;false]));
measuredRelative = [prunedPaths.relativePowerdB].';
assert(max(abs(measuredRelative-relativeTargetdB)) < 1e-10);
assert(pruningStats.numPathsBeforePruning==5 && ...
    pruningStats.numPathsAfterPruning==3);
hBeforePruning = sum(cat(2,examplePaths.contribution),2);
hAfterPruning = sum(cat(2,prunedPaths(retainMask).contribution),2);
assert(norm(hBeforePruning-hAfterPruning) > 0);

cfgNoPruning = cfg;
cfgNoPruning.enablePathPruning = false;
[unprunedPaths,unprunedMask,unprunedStats] = ...
    pruneRayPaths(examplePaths,cfgNoPruning);
assert(all(unprunedMask));
hCompatibility = sum(cat(2,unprunedPaths(unprunedMask).contribution),2);
assert(isequal(hCompatibility,hBeforePruning));

zeroPaths = examplePaths(1:2);
[zeroPaths.contribution] = deal(complex(zeros(cfg.N_AP,1)));
[zeroPaths,zeroMask] = pruneRayPaths(zeroPaths,cfg);
assert(~any(isnan([zeroPaths.pathPowerdB])) && ...
    ~any(isnan([zeroPaths.relativePowerdB])));
assert(all(zeroMask));
[~,singleMask] = pruneRayPaths(examplePaths(1),cfg);
assert(singleMask);
[~,emptyMask,emptyStats] = pruneRayPaths(examplePaths([]),cfg);
assert(isempty(emptyMask) && emptyStats.numPathsBeforePruning==0 && ...
    emptyStats.numPathsAfterPruning==0);

% Deterministic geometric AP-wall-UE test: the image-method reflection is
% more than 40 dB below LoS and must be retained only when pruning is off.
manualCfg = configRayTracing3D(struct('M',1,'K',1,'N_AP',4, ...
    'enableObstacles',true,'numObstacles',1, ...
    'enableSideReflection',true,'enableRoofReflection',false, ...
    'enableGroundReflection',false,'enableDiffraction',false, ...
    'enablePathPruning',true,'pathPruningThresholddB',40, ...
    'showFigures',false,'saveFigures',false,'saveResults',false));
manualAP = [0 0 1];
manualUE = [10 0 1];
manualObstacle = struct('center',[5 5 1],'width',4,'depth',2, ...
    'height',2,'yaw',0, ...
    'reflectionCoefficient',1e-3*exp(1j*0.4),'active',true);
manualScenario = struct('APpos',manualAP,'UEpos',manualUE, ...
    'obstacles',manualObstacle, ...
    'antennaPos',generateAPArrayPositions(manualAP,manualCfg), ...
    'mode',"pathPruningTest",'region',manualCfg.region);
[manualPrunedChannel,manualInfo] = ...
    generateRayTracingChannels3D(manualScenario,manualCfg);
manualPaths = manualInfo(1,1).paths;
manualTypes = strings(numel(manualPaths),1);
for l = 1:numel(manualPaths)
    manualTypes(l) = manualPaths(l).type;
end
manualLoSIndex = find(manualTypes=="LoS",1);
manualReflectionIndex = find(manualTypes=="reflection",1);
assert(~isempty(manualLoSIndex) && ~isempty(manualReflectionIndex));
assert(manualInfo.numPathsBeforePruning==2 && ...
    manualInfo.numPathsAfterPruning==1);
assert(manualPaths(manualLoSIndex).isRetained && ...
    ~manualPaths(manualReflectionIndex).isRetained);
assert(manualPaths(manualReflectionIndex).relativePowerdB < -40);
manualChannelBefore = sum(cat(2,manualPaths.contribution),2);
assert(norm(manualPrunedChannel(:,1,1)- ...
    manualPaths(manualLoSIndex).contribution) < 1e-14);

manualCfg.enablePathPruning = false;
[manualUnprunedChannel,manualUnprunedInfo] = ...
    generateRayTracingChannels3D(manualScenario,manualCfg);
assert(all([manualUnprunedInfo.paths.isRetained]));
assert(norm(manualUnprunedChannel(:,1,1)-manualChannelBefore) < 1e-14);

manualTable = table((1:numel(manualPaths)).',manualTypes, ...
    [manualPaths.pathPowerdB].',[manualPaths.relativePowerdB].', ...
    [manualPaths.isRetained].','VariableNames', ...
    {'Path','Type','Power_dB','Relative_dB','Retained'});
fprintf('\n=== Sanity check: 実Ray Tracingリンクの40 dB pruning ===\n');
disp(manualTable);
disp('pruning前のh_true相当 ='); disp(manualChannelBefore);
disp('pruning後のh_true ='); disp(manualPrunedChannel(:,1,1));

exampleTable = table((1:numExamplePaths).',pathTypes, ...
    [prunedPaths.pathPowerdB].',measuredRelative, ...
    [prunedPaths.isRetained].', ...
    'VariableNames',{'Path','Type','Power_dB','Relative_dB','Retained'});
fprintf('\n=== Sanity check: 1リンクの40 dB pruning例 ===\n');
disp(exampleTable);
disp('pruning前の合成チャネル ='); disp(hBeforePruning);
disp('pruning後の合成チャネル ='); disp(hAfterPruning);

report = struct('passed',true,'numChecks',34, ...
    'relativeMagnitudeError',relativeError, ...
    'pruningExample',struct('table',exampleTable, ...
    'hBeforePruning',hBeforePruning,'hAfterPruning',hAfterPruning, ...
    'stats',pruningStats,'disabledStats',unprunedStats), ...
    'geometricPruningExample',struct('table',manualTable, ...
    'hBeforePruning',manualChannelBefore, ...
    'hAfterPruning',manualPrunedChannel(:,1,1), ...
    'hPruningDisabled',manualUnprunedChannel(:,1,1)));
fprintf('全%d項目のRay Tracing専用sanity checksに合格しました。\n', ...
    report.numChecks);
end
