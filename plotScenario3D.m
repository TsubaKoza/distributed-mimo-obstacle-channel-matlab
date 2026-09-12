function fig = plotScenario3D(scenario,pathInfo,m,k,cfg)
%PLOTSCENARIO3D Figure 1: APs, UEs, yawed cuboids, and selected paths.
fig=figure('Name','図1: 3次元シナリオ'); hold on;
for i=1:numel(scenario.obstacles)
    drawCuboid(scenario.obstacles(i),i==1);
end
scatter3(scenario.APpos(:,1),scenario.APpos(:,2),scenario.APpos(:,3), ...
    70,'^','filled','DisplayName','AP（アクセスポイント）');
scatter3(scenario.UEpos(:,1),scenario.UEpos(:,2),scenario.UEpos(:,3), ...
    55,'o','filled','DisplayName','UE（ユーザー端末）');
AP=scenario.APpos(m,:); UE=scenario.UEpos(k,:);
plot3([AP(1) UE(1)],[AP(2) UE(2)],[AP(3) UE(3)],'k--', ...
    'LineWidth',1,'DisplayName','AP-UE間の直線');
paths=pathInfo(m,k).paths;
for l=1:numel(paths)
    if paths(l).type=="LoS"
        plot3([AP(1) UE(1)],[AP(2) UE(2)],[AP(3) UE(3)], ...
            'g-','LineWidth',2,'DisplayName','LoS（直接波）');
    elseif paths(l).type=="reflection"
        r=paths(l).reflectionPoint;
        plot3([AP(1) r(1) UE(1)],[AP(2) r(2) UE(2)], ...
            [AP(3) r(3) UE(3)],'m-','LineWidth',1.5, ...
            'DisplayName','1回反射波');
        scatter3(r(1),r(2),r(3),30,'m','filled','HandleVisibility','off');
    elseif paths(l).type=="diffraction"
        d=paths(l).diffractionPoint;
        plot3([AP(1) d(1) UE(1)],[AP(2) d(2) UE(2)], ...
            [AP(3) d(3) UE(3)],'c-','LineWidth',1.8, ...
            'DisplayName','1回knife-edge回折波');
        scatter3(d(1),d(2),d(3),35,'c','filled','HandleVisibility','off');
    end
end
xlabel('x座標 [m]'); ylabel('y座標 [m]'); zlabel('z座標（高さ）[m]');
grid on; axis equal; view(3); xlim(cfg.region(1,:)); ylim(cfg.region(2,:));
zlim(cfg.region(3,:));
title(sprintf('図1: 3次元配置と選択リンク（AP %d - UE %d）',m,k));
legend('Location','bestoutside','Interpreter','none'); hold off;
end

function drawCuboid(o,showLegend)
local=[-1 -1 -1;1 -1 -1;1 1 -1;-1 1 -1; ...
       -1 -1 1;1 -1 1;1 1 1;-1 1 1].*[o.width o.depth o.height]/2;
c=cos(o.yaw); s=sin(o.yaw); R=[c -s 0;s c 0;0 0 1];
v=(R*local.').'+o.center;
f=[1 2 3 4;5 6 7 8;1 2 6 5;2 3 7 6;3 4 8 7;4 1 5 8];
if showLegend
    visibility='on'; displayName='遮蔽物（建物）';
else
    visibility='off'; displayName='';
end
patch('Vertices',v,'Faces',f,'FaceColor',[0.4 0.5 0.7], ...
    'FaceAlpha',0.25,'EdgeColor',[0.2 0.2 0.3], ...
    'HandleVisibility',visibility,'DisplayName',displayName);
end
