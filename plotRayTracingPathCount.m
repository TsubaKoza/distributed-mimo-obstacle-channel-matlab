function fig = plotRayTracingPathCount(result)
%PLOTRAYTRACINGPATHCOUNT Show retained path count for every link.
fig = figure('Name','Ray Tracing: 全リンクのpruning後path数');
imagesc(result.pathCount);
axis xy;
colormap(gca,parula(max(2,max(result.pathCount(:))+1)));
cb = colorbar;
cb.Label.String = 'pruning後の保持path数';
xlabel('UE番号');
ylabel('AP番号');
title('全AP-UEリンクのpruning後path数（直接波＋1回反射＋1回回折）');
for m = 1:size(result.pathCount,1)
    for k = 1:size(result.pathCount,2)
        text(k,m,sprintf('%d',result.pathCount(m,k)), ...
            'HorizontalAlignment','center','Color','k', ...
            'FontWeight','bold');
    end
end
end
