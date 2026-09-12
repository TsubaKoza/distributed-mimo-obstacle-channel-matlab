function [channelTable,pruningTable] = inspectRayTracingLink(result,m,k,makePlot)
%INSPECTRAYTRACINGLINK Display and return one link's channel components.
if nargin < 4
    makePlot = true;
end
validateattributes(m,{'numeric'},{'scalar','integer','>=',1, ...
    '<=',size(result.APpos,1)});
validateattributes(k,{'numeric'},{'scalar','integer','>=',1, ...
    '<=',size(result.UEpos,1)});

fprintf('\n=== Ray Tracingリンク詳細: AP %d - UE %d ===\n',m,k);
fprintf('AP位置: [%g %g %g] m\n',result.APpos(m,:));
fprintf('UE位置: [%g %g %g] m\n',result.UEpos(k,:));
info = result.pathInfo(m,k);
fprintf(['LoS（直接波）: %s; 有効な1回反射path数: %d; ' ...
    '有効な1回回折path数: %d; 生成path数: %d; 保持path数: %d\n'], ...
    string(info.hasLoS),info.numReflections,info.numDiffractions, ...
    info.numPathsBeforePruning,info.numPathsAfterPruning);
if ~info.hasLoS
    fprintf('LoSを遮断した遮蔽物番号: %s\n', ...
        mat2str(info.blockingObstacleIndices));
end

for l = 1:numel(info.paths)
    q = info.paths(l);
    fprintf('Path %d: %s, 経路長=%.6g m, 複素利得=%+.4e%+.4ej\n', ...
        l,q.type,q.length,real(q.complexGain),imag(q.complexGain));
    if q.type == "reflection"
        fprintf('  反射点=[%.4g %.4g %.4g], 遮蔽物=%d, 反射面=%s\n', ...
            q.reflectionPoint,q.obstacleIndex,q.faceName);
    elseif q.type == "diffraction"
        fprintf(['  回折点=[%.4g %.4g %.4g], 遮蔽物=%d, edge=%s, ' ...
            'v=%.4g, 回折損失=%.3f dB\n'],q.diffractionPoint, ...
            q.obstacleIndex,q.edgeName,q.diffractionParameter, ...
            q.diffractionLossdB);
    end
    fprintf('  方位角=%.4g rad, 仰角=%.4g rad\n', ...
        q.AoD.azimuth,q.AoD.elevation);
end

numPaths = numel(info.paths);
pathIndex = (1:numPaths).';
pathType = strings(numPaths,1);
pathPowerdB = zeros(numPaths,1);
relativePowerdB = zeros(numPaths,1);
pruningResult = strings(numPaths,1);
for l = 1:numPaths
    pathType(l) = info.paths(l).type;
    pathPowerdB(l) = info.paths(l).pathPowerdB;
    relativePowerdB(l) = info.paths(l).relativePowerdB;
    if info.paths(l).isRetained
        pruningResult(l) = "retained";
    else
        pruningResult(l) = "removed";
    end
end
pruningTable = table(pathIndex,pathType,pathPowerdB,relativePowerdB, ...
    pruningResult,'VariableNames', ...
    {'Path','Type','Power_dB','Relative_dB','Result'});
fprintf('\n=== AP %d - UE %d Ray pruning ===\n',m,k);
if numPaths == 0
    fprintf('生成されたRayはありません。\n');
else
    disp(pruningTable);
    fprintf('最強Ray: Path %d (%s), %.6g dB\n', ...
        info.strongestPathIndex,info.strongestPathType, ...
        info.strongestPathPowerdB);
end
if result.cfg.enablePathPruning
    fprintf('閾値: %.6g dB（相対値 <= -%.6g dBを除外）\n', ...
        result.cfg.pathPruningThresholddB, ...
        result.cfg.pathPruningThresholddB);
else
    fprintf('Pruning: 無効（全Rayを保持）\n');
end
fprintf('Pruning前のpath数: %d\n',info.numPathsBeforePruning);
fprintf('Pruning後のpath数: %d\n',info.numPathsAfterPruning);

antennaIndex = (1:size(result.h_true,1)).';
channelTable = table(antennaIndex,'VariableNames',{'AP_Antenna_Index'});
if info.hasLoS
    channelTable.h_LoS = result.h_LoS(:,m,k);
end
if info.numReflections > 0
    channelTable.h_reflection = result.h_reflection(:,m,k);
end
if info.numDiffractions > 0
    channelTable.h_diffraction = result.h_diffraction(:,m,k);
end
channelTable.h_true = result.h_true(:,m,k);

fprintf('\n=== APアンテナ素子別チャネル成分（AP %d - UE %d）===\n',m,k);
fprintf(['h_reflectionとh_diffractionは、それぞれ該当する全pathを' ...
    'pruning後に複素位相込みで合成した値です。\n']);
disp(channelTable);
if result.outageMask(m,k)
    fprintf('チャネル利得: 伝搬pathなし\n');
else
    fprintf('合成チャネル利得: %.6g (%.3f dB)\n', ...
        result.linkGain(m,k),result.linkGainDB(m,k));
end

if makePlot
    plotScenario3D(result.scenario,result.pathInfo,m,k,result.cfg);
end
end
