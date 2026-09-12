function channelTable = inspectRayTracingLink(result,m,k,makePlot)
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
    '有効な1回回折path数: %d; 合計path数: %d\n'], ...
    string(info.hasLoS),info.numReflections,info.numDiffractions, ...
    numel(info.paths));
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
    '複素位相込みで合成した値です。\n']);
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
