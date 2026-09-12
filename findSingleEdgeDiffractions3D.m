function paths = findSingleEdgeDiffractions3D(AP,UE,obstacles,blockingIndices,antennaCoordinates,cfg)
%FINDSINGLEEDGEDIFFRACTIONS3D Dominant 3-D cuboid-edge knife diffraction.
% Extension/Assumption: each blocking cuboid is locally collapsed to a
% zero-thickness knife edge. Candidate top and vertical edges are tested,
% and at most the strongest valid single-edge path per obstacle is retained.
paths=emptyPaths();
if ~cfg.enableDiffraction || isempty(blockingIndices)
    return;
end
directLength=norm(UE-AP);
for ii=1:numel(blockingIndices)
    obstacleIndex=blockingIndices(ii);
    obstacle=obstacles(obstacleIndex);
    edges=cuboidDiffractionEdges(obstacle,cfg);
    candidates=emptyPaths();
    for e=1:numel(edges)
        edge=edges(e);
        objective=@(t) norm(AP-(edge.a+t*(edge.b-edge.a))) + ...
            norm(UE-(edge.a+t*(edge.b-edge.a)));
        [tBest,totalLength]=fminbnd(objective,0,1);
        point=edge.a+tBest*(edge.b-edge.a);
        d1=norm(point-AP); d2=norm(UE-point);
        if d1<cfg.minPathLength || d2<cfg.minPathLength
            continue;
        end
        % The owning cuboid is ignored because the knife-edge approximation
        % replaces its finite thickness locally. Other cuboids must be clear.
        firstClear=checkLoS3D(AP,point,obstacles,cfg,obstacleIndex);
        secondClear=checkLoS3D(point,UE,obstacles,cfg,obstacleIndex);
        if ~(firstClear && secondClear), continue; end
        line=UE-AP;
        tLine=max(0,min(1,dot(point-AP,line)/dot(line,line)));
        closest=AP+tLine*line;
        h=norm(point-closest);
        [lossdB,v]=computeKnifeEdgeDiffractionLoss(h,d1,d2,cfg.lambda,cfg);
        diffractionMagnitude=10^(-lossdB/20);
        % ITU J(v) supplies magnitude loss. Additional diffraction phase is
        % neglected; phase comes from the total broken path length.
        amplitude=cfg.lambda/(4*pi*directLength)*diffractionMagnitude;
        gain=amplitude*exp(-1j*2*pi*totalLength/cfg.lambda);
        aod=computeAoAAoD3D(AP,point);
        aoa=computeAoAAoD3D(AP,point);
        response=computeArrayResponse3D(antennaCoordinates,AP,aod.direction,cfg);
        item=struct('type',"diffraction",'length',totalLength, ...
            'reflectionPoint',[NaN NaN NaN],'AoA',aoa,'AoD',aod, ...
            'complexGain',gain,'obstacleIndex',obstacleIndex,'faceName',"", ...
            'contribution',gain*response,'diffractionPoint',point, ...
            'edgeName',edge.name,'diffractionParameter',v, ...
            'diffractionLossdB',lossdB);
        candidates(end+1,1)=item; %#ok<AGROW>
    end
    if isempty(candidates), continue; end
    [~,order]=sort([candidates.diffractionLossdB],'ascend');
    keep=order(1:min(cfg.maxDiffractionsPerObstacle,numel(order)));
    paths=[paths;candidates(keep(:))]; %#ok<AGROW>
end
end

function edges=cuboidDiffractionEdges(o,cfg)
% Eight candidates: four roof perimeter edges and four vertical edges.
local=[-o.width/2 -o.depth/2 -o.height/2; ... % 1 bottom corners
        o.width/2 -o.depth/2 -o.height/2; ... % 2
        o.width/2  o.depth/2 -o.height/2; ... % 3
       -o.width/2  o.depth/2 -o.height/2; ... % 4
       -o.width/2 -o.depth/2  o.height/2; ... % 5 top corners
        o.width/2 -o.depth/2  o.height/2; ... % 6
        o.width/2  o.depth/2  o.height/2; ... % 7
       -o.width/2  o.depth/2  o.height/2];    % 8
c=cos(o.yaw); s=sin(o.yaw); R=[c -s 0;s c 0;0 0 1];
globalPoints=(R*local.').'+o.center;
pairs=[5 6;6 7;7 8;8 5;1 5;2 6;3 7;4 8];
names=["roof -y","roof +x","roof +y","roof -x", ...
       "vertical --","vertical +-","vertical ++","vertical -+"];
if strcmpi(cfg.diffractionEdges,"topOnly")
    pairs=pairs(1:4,:); names=names(1:4);
elseif ~strcmpi(cfg.diffractionEdges,"topAndVertical")
    error('Unknown diffractionEdges: %s',cfg.diffractionEdges);
end
edges=repmat(struct('name',"",'a',[],'b',[]),size(pairs,1),1);
for i=1:size(pairs,1)
    edges(i)=struct('name',names(i),'a',globalPoints(pairs(i,1),:), ...
        'b',globalPoints(pairs(i,2),:));
end
end

function p=emptyPaths()
p=repmat(struct('type',"",'length',[],'reflectionPoint',[], ...
    'AoA',[],'AoD',[],'complexGain',[],'obstacleIndex',[], ...
    'faceName',"",'contribution',[],'diffractionPoint',[], ...
    'edgeName',"",'diffractionParameter',[],'diffractionLossdB',[]),0,1);
end
