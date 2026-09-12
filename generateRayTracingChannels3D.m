function [h_true,pathInfo] = generateRayTracingChannels3D(scenario,cfg)
%GENERATERAYTRACINGCHANNELS3D Ground-truth LoS, reflection, diffraction channels.
% h_true is the coherent sum of all valid paths for every AP-UE link.
APpos = scenario.APpos; UEpos = scenario.UEpos;
M = size(APpos,1); K = size(UEpos,1); N = cfg.N_AP;
h_true = complex(zeros(N,M,K));
pathTemplate = struct('type',"",'length',[],'reflectionPoint',[], ...
    'AoA',[],'AoD',[],'complexGain',[],'obstacleIndex',[], ...
    'faceName',"",'contribution',[],'diffractionPoint',[], ...
    'edgeName',"",'diffractionParameter',[],'diffractionLossdB',[], ...
    'pathPower',[],'pathPowerdB',[],'relativePowerdB',[], ...
    'isRetained',false);
infoTemplate = struct('hasLoS',false,'blockingObstacleIndices',[], ...
    'numReflections',0,'numDiffractions',0, ...
    'numPathsBeforePruning',0,'numPathsAfterPruning',0, ...
    'strongestPathPowerdB',-Inf,'strongestPathIndex',NaN, ...
    'strongestPathType',"", ...
    'paths',repmat(pathTemplate,0,1));
pathInfo = repmat(infoTemplate,M,K);
for m = 1:M
    % Preserve N_AP x 3 even when N_AP=1. squeeze() would turn 1x1x3
    % into 3x1 and break the physical-coordinate array response.
    ant = reshape(scenario.antennaPos(m,:,:),N,3);
    for k = 1:K
        AP = APpos(m,:); UE = UEpos(k,:);
        [hasLoS,blocking] = checkLoS3D(AP,UE,scenario.obstacles,cfg);
        paths = repmat(pathTemplate,0,1);
        if hasLoS
            length0 = norm(UE-AP);
            direction = computeAoAAoD3D(AP,UE);
            gain = computePathGain(length0,1,cfg);
            response = computeArrayResponse3D(ant,AP,direction.direction,cfg);
            losPath = pathTemplate;
            losPath.type = "LoS"; losPath.length = length0;
            losPath.reflectionPoint = [NaN NaN NaN];
            losPath.AoA = direction; losPath.AoD = direction;
            losPath.complexGain = gain; losPath.obstacleIndex = NaN;
            losPath.faceName = "direct"; losPath.contribution = gain*response;
            losPath.diffractionPoint = [NaN NaN NaN];
            losPath.edgeName = ""; losPath.diffractionParameter = NaN;
            losPath.diffractionLossdB = NaN;
            paths(end+1,1) = losPath; %#ok<AGROW>
        end
        reflected = findSingleBounceReflections3D(AP,UE,scenario.obstacles,ant,cfg);
        diffracted = repmat(pathTemplate,0,1);
        if cfg.enableDiffraction && (~cfg.diffractionOnlyWhenLoSBlocked || ~hasLoS)
            diffracted = findSingleEdgeDiffractions3D(AP,UE,scenario.obstacles, ...
                blocking,ant,cfg);
        end
        % Struct append with end+1 can produce a row or column depending on
        % how many paths were found. Normalize both lists before concatenation.
        paths = [paths(:); reflected(:); diffracted(:)];
        % Pruning is link-local and occurs only after all physical rays have
        % been generated, immediately before the coherent channel sum.
        [paths,retainMask,pruningStats] = pruneRayPaths(paths,cfg);
        for l = find(retainMask).'
            h_true(:,m,k) = h_true(:,m,k)+paths(l).contribution;
        end
        pathInfo(m,k).hasLoS = hasLoS;
        pathInfo(m,k).blockingObstacleIndices = blocking;
        pathInfo(m,k).numReflections = numel(reflected);
        pathInfo(m,k).numDiffractions = numel(diffracted);
        pathInfo(m,k).numPathsBeforePruning = ...
            pruningStats.numPathsBeforePruning;
        pathInfo(m,k).numPathsAfterPruning = ...
            pruningStats.numPathsAfterPruning;
        pathInfo(m,k).strongestPathPowerdB = ...
            pruningStats.strongestPathPowerdB;
        pathInfo(m,k).strongestPathIndex = ...
            pruningStats.strongestPathIndex;
        pathInfo(m,k).strongestPathType = ...
            pruningStats.strongestPathType;
        pathInfo(m,k).paths = paths;
    end
end
assert(size(h_true,1)==N && size(h_true,2)==M && size(h_true,3)==K);
end
