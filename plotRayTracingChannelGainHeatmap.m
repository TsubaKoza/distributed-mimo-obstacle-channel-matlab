function fig = plotRayTracingChannelGainHeatmap(result)
%PLOTRAYTRACINGCHANNELGAINHEATMAP Show true gain for every AP-UE link.
gainDB = result.linkGainDB;
fig = figure('Name','Ray Tracing: 全リンクの真のチャネル利得');
imagesc(gainDB,'AlphaData',~isnan(gainDB));
set(gca,'Color',[0.75 0.75 0.75]);
axis xy;
cb = colorbar;
cb.Label.String = '合成チャネル利得 [dB]';
xlabel('UE番号');
ylabel('AP番号');
title(['Ray Tracingによる全AP-UEリンクの真のチャネル利得' ...
    '（灰色 = 伝搬pathなし）']);
end
