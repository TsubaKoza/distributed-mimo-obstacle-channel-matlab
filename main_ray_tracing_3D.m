function result = main_ray_tracing_3D(cfg)
%MAIN_RAY_TRACING_3D Calculate every AP-UE channel without pilot signals.
% Processing stops after the coherent sum of LoS, single-bounce
% reflections, and optional single-edge diffraction paths. No pilot,
% received-pilot matrix, channel estimator, noise, or NMSE is generated.

if nargin < 1 || isempty(cfg)
    cfg = configRayTracing3D();
else
    cfg = configRayTracing3D(cfg);
end

rng(cfg.seed,'twister');
if ~cfg.showFigures
    previousVisibility = get(groot,'DefaultFigureVisible');
    set(groot,'DefaultFigureVisible','off');
    cleanup = onCleanup(@() ...
        set(groot,'DefaultFigureVisible',previousVisibility));
end

if cfg.saveFigures || cfg.saveResults
    if ~exist(cfg.resultsDir,'dir')
        mkdir(cfg.resultsDir);
    end
end

reportToolboxes();
scenario = generateScenario3D(cfg);
[h_true,pathInfo] = generateRayTracingChannels3D(scenario,cfg);

M = size(scenario.APpos,1);
K = size(scenario.UEpos,1);
h_LoS = complex(zeros(size(h_true)));
h_reflection = complex(zeros(size(h_true)));
h_diffraction = complex(zeros(size(h_true)));
for m = 1:M
    for k = 1:K
        paths = pathInfo(m,k).paths;
        for l = 1:numel(paths)
            switch paths(l).type
                case "LoS"
                    h_LoS(:,m,k) = h_LoS(:,m,k)+paths(l).contribution;
                case "reflection"
                    h_reflection(:,m,k) = h_reflection(:,m,k)+ ...
                        paths(l).contribution;
                case "diffraction"
                    h_diffraction(:,m,k) = h_diffraction(:,m,k)+ ...
                        paths(l).contribution;
            end
        end
    end
end
h_component_sum = h_LoS+h_reflection+h_diffraction;
componentTolerance = 100*eps(max(1,max(abs(h_true),[],'all')));
assert(max(abs(h_true-h_component_sum),[],'all') <= componentTolerance, ...
    'LoS/reflection/diffraction components do not reproduce h_true.');

linkGain = reshape(sum(abs(h_true).^2,1),M,K);
linkGainDB = 10*log10(max(linkGain,realmin));
hasLoS = false(M,K);
numReflections = zeros(M,K);
numDiffractions = zeros(M,K);
pathCount = zeros(M,K);
for m = 1:M
    for k = 1:K
        hasLoS(m,k) = pathInfo(m,k).hasLoS;
        numReflections(m,k) = pathInfo(m,k).numReflections;
        numDiffractions(m,k) = pathInfo(m,k).numDiffractions;
        pathCount(m,k) = numel(pathInfo(m,k).paths);
    end
end
outageMask = pathCount == 0;
linkGainDB(outageMask) = NaN;

result = struct('scenario',scenario,'APpos',scenario.APpos, ...
    'UEpos',scenario.UEpos,'obstacles',scenario.obstacles, ...
    'antennaPos',scenario.antennaPos,'h_true',h_true, ...
    'h_LoS',h_LoS,'h_reflection',h_reflection, ...
    'h_diffraction',h_diffraction, ...
    'pathInfo',pathInfo,'hasLoS',hasLoS, ...
    'numReflections',numReflections,'numDiffractions',numDiffractions, ...
    'pathCount',pathCount,'linkGain',linkGain, ...
    'linkGainDB',linkGainDB,'outageMask',outageMask,'cfg',cfg);

assert(size(result.h_true,1)==cfg.N_AP && ...
    size(result.h_true,2)==M && size(result.h_true,3)==K);
assert(isequal(size(result.pathCount),[M,K]));
assert(~isfield(result,'p') && ~isfield(result,'Y') && ...
    ~isfield(result,'h_hat_LS') && ~isfield(result,'NMSE'));

figs = gobjects(0);
if cfg.showFigures || cfg.saveFigures
    selectedM = min(max(1,cfg.selectedAP),M);
    selectedK = min(max(1,cfg.selectedUE),K);
    figs(end+1) = plotScenario3D(scenario,pathInfo,selectedM,selectedK,cfg);
    figs(end+1) = plotRayTracingChannelGainHeatmap(result);
    figs(end+1) = plotRayTracingPathCount(result);
end

if cfg.saveFigures
    names = {'ray_tracing_scenario','ray_tracing_channel_gain', ...
        'ray_tracing_path_count'};
    for i = 1:numel(figs)
        exportgraphics(figs(i),fullfile(cfg.resultsDir,[names{i} '.png']), ...
            'Resolution',180);
        savefig(figs(i),fullfile(cfg.resultsDir,[names{i} '.fig']));
    end
end

fprintf('\n=== 全AP-UEリンクのRay Tracing完了 ===\n');
fprintf('搬送周波数: %.6g GHz; 波長: %.6g mm; アンテナ間隔: %.6g mm\n', ...
    cfg.fc/1e9,cfg.lambda*1e3,cfg.arraySpacing*1e3);
fprintf('AP数: %d; UE数: %d; AP当たりアンテナ数: %d; 全リンク数: %d\n', ...
    M,K,cfg.N_AP,M*K);
fprintf('LoSリンク数: %d; 反射path総数: %d; 回折path総数: %d\n', ...
    nnz(hasLoS),sum(numReflections(:)),sum(numDiffractions(:)));
fprintf('伝搬pathなし: %d / %dリンク\n',nnz(outageMask),M*K);

selectedM = min(max(1,cfg.selectedAP),M);
selectedK = min(max(1,cfg.selectedUE),K);
selectedChannelTable = inspectRayTracingLink(result,selectedM,selectedK,false);
result.selectedLink = struct('APIndex',selectedM,'UEIndex',selectedK, ...
    'channelTable',selectedChannelTable);

if cfg.saveResults
    outputFile = fullfile(cfg.resultsDir,'ray_tracing_channels_3D_results.mat');
    save(outputFile,'result','cfg','-v7.3');
    fprintf('Ray Tracing結果を保存しました: %s\n',outputFile);
end
end
