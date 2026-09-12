function cfg = configRayTracing3D(varargin)
%CONFIGRAYTRACING3D Configuration for the pilot-free 3-D ray tracer.
% The default carrier frequency is 100 GHz. Only geometry, propagation,
% plotting, and result-saving parameters are defined here.

cfg.seed = 20260901;
cfg.c = 3e8;
cfg.fc = 100e9;
cfg.lambda = cfg.c/cfg.fc;
cfg.region = [0 200; 0 200; 0 30];
cfg.scenarioMode = "random3D"; % or "rayTracingPaperReference"

cfg.M = 5;
cfg.K = 10;
cfg.N_AP = 4;
cfg.zAP = 10;
cfg.zUE = 1.5;
cfg.minAPUEDistance = 2;
cfg.arraySpacing = cfg.lambda/2;
cfg.ulaDirection = [1 0 0];

cfg.numObstacles = 5;
cfg.obstacleWidthRange = [10 40];
cfg.obstacleDepthRange = [10 40];
cfg.obstacleHeightRange = [5 25];
cfg.obstacleYawRangeDeg = [0 360];
cfg.obstacleReflectionMagnitudeRange = [0.4 0.8];
cfg.obstacleClearance = 1;
cfg.maxPlacementAttempts = 5000;
cfg.enableObstacles = true;
cfg.enableSideReflection = true;
cfg.enableRoofReflection = true;
cfg.enableGroundReflection = false;
cfg.enableDiffraction = true;
cfg.diffractionModel = "singleKnifeEdgeITU";
cfg.diffractionEdges = "topAndVertical";
cfg.maxDiffractionsPerObstacle = 1;
cfg.diffractionOnlyWhenLoSBlocked = true;
cfg.diffractionLossCapdB = 200;

cfg.pathGainModel = "friisField";
cfg.enablePathPruning = true;
cfg.pathPruningThresholddB = 40;
cfg.minPathLength = 1e-3;
cfg.epsGeom = 1e-9;
cfg.segmentEndpointMargin = 1e-7;

cfg.selectedAP = 1;
cfg.selectedUE = 1;
cfg.showFigures = true;
cfg.saveFigures = true;
cfg.saveResults = true;
cfg.resultsDir = fullfile(fileparts(mfilename('fullpath')), ...
    'ray_tracing_results_100GHz');

arraySpacingWasOverridden = false;
if nargin == 1 && isstruct(varargin{1})
    updates = varargin{1};
    arraySpacingWasOverridden = isfield(updates,'arraySpacing');
    names = fieldnames(updates);
    for i = 1:numel(names)
        cfg.(names{i}) = updates.(names{i});
    end
elseif mod(nargin,2) == 0
    for i = 1:2:nargin
        name = char(varargin{i});
        if strcmpi(name,'arraySpacing')
            arraySpacingWasOverridden = true;
        end
        cfg.(name) = varargin{i+1};
    end
elseif nargin ~= 0
    error('Overrides must be a struct or name/value pairs.');
end

validateattributes(cfg.fc,{'numeric'},{'scalar','real','positive','finite'});
validateattributes(cfg.M,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.K,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.N_AP,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.enablePathPruning,{'logical','numeric'},{'scalar'});
if ~any(cfg.enablePathPruning == [0 1])
    error('enablePathPruning must be true/false or 1/0.');
end
validateattributes(cfg.pathPruningThresholddB,{'numeric'}, ...
    {'scalar','real','nonnegative','finite'});
validateattributes(cfg.ulaDirection,{'numeric'},{'vector','numel',3,'real','finite'});
if norm(cfg.ulaDirection) <= eps
    error('ulaDirection must be a nonzero 3-D vector.');
end

cfg.lambda = cfg.c/cfg.fc;
cfg.enablePathPruning = logical(cfg.enablePathPruning);
if ~arraySpacingWasOverridden || isempty(cfg.arraySpacing)
    cfg.arraySpacing = cfg.lambda/2;
end
validateattributes(cfg.arraySpacing,{'numeric'}, ...
    {'scalar','real','positive','finite'});
cfg.ulaDirection = reshape(cfg.ulaDirection,1,3)/norm(cfg.ulaDirection);
end
