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

distance = norm(result.UEpos(1,:)-result.APpos(1,:));
expectedMagnitude = cfg.lambda/(4*pi*distance);
relativeError = max(abs(abs(result.h_true(:,1,1))-expectedMagnitude)) / ...
    expectedMagnitude;
assert(relativeError < 1e-12);

report = struct('passed',true,'numChecks',13, ...
    'relativeMagnitudeError',relativeError);
fprintf('全%d項目のRay Tracing専用sanity checksに合格しました。\n', ...
    report.numChecks);
end
