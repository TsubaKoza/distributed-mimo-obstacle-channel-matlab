# 分散MIMO＋遮蔽物における各AP-UEのチャネル推定（MATLAB）

3D Cell-Free / Distributed MIMO Ray Tracing Simulator

このフォルダは、パイロット信号やチャネル推定を使わず、次の処理だけを実行するMATLABシミュレータである。

`3次元環境生成 → LoS・1回反射・1回knife-edge回折の探索 → 全AP–UEリンクの真のチャネル h_true`

## 実行方法

MATLABでこのフォルダをcurrent folderにして実行する。

```matlab
runRayTracingSanityChecks
rtResult = main_ray_tracing_3D();
```

既定条件は搬送周波数`100 GHz`、波長`3 mm`、アンテナ素子間隔`1.5 mm（lambda/2）`である。

設定を変更する例:

```matlab
cfgRT = configRayTracing3D(struct( ...
    'M',5, ...
    'K',10, ...
    'N_AP',4, ...
    'numObstacles',5, ...
    'fc',100e9, ...
    'enablePathPruning',true, ...
    'pathPruningThresholddB',40, ...
    'showFigures',true, ...
    'saveFigures',true, ...
    'saveResults',true));
rtResult = main_ray_tracing_3D(cfgRT);
```

## 主な出力

| 変数 | dimension | 意味 |
|---|---:|---|
| `rtResult.APpos` | `M x 3` | AP中心の3次元座標 `[x,y,z]` |
| `rtResult.UEpos` | `K x 3` | UEの3次元座標 `[x,y,z]` |
| `rtResult.antennaPos` | `M x N_AP x 3` | APアンテナ素子の実座標 |
| `rtResult.h_true` | `N_AP x M x K` | 全AP–UEリンクの合成複素チャネル |
| `rtResult.h_LoS` | `N_AP x M x K` | LoS直接波による複素チャネル |
| `rtResult.h_reflection` | `N_AP x M x K` | 全1回反射pathを合成した複素チャネル |
| `rtResult.h_diffraction` | `N_AP x M x K` | 全1回回折pathを合成した複素チャネル |
| `rtResult.pathInfo` | `M x K` | 各リンクの直接・反射・回折path詳細 |
| `rtResult.pathCount` | `M x K` | 各リンクのpruning後の保持path数 |
| `rtResult.pathCountBeforePruning` | `M x K` | pruning前の生成path数 |
| `rtResult.pathCountAfterPruning` | `M x K` | pruning後の保持path数 |
| `rtResult.strongestPathPowerdB` | `M x K` | 各リンクの最強Ray電力 `[dB]` |
| `rtResult.linkGainDB` | `M x K` | 合成後チャネル利得 `[dB]` |
| `rtResult.outageMask` | `M x K` | 有効な伝搬pathが存在しないリンク |

`rtResult.h_true(:,m,k)`が、UE `k`からAP `m`への、APアンテナ全素子分の真のチャネルである。

特定リンクの詳細表示:

```matlab
channelTable = inspectRayTracingLink(rtResult,1,1);
```

この表はAPアンテナ素子ごとに、選択リンクに存在する`h_LoS`、
`h_reflection`、`h_diffraction`と、その合成値`h_true`を表示する。
存在しない伝搬種類の列は省略される。Figure 1と同じリンクは、設定値
`cfgRT.selectedAP`と`cfgRT.selectedUE`で選択できる。通常実行時にはこの
選択リンクの表が自動表示され、`rtResult.selectedLink.channelTable`にも保存される。

## Ray pruning

既定では、各AP-UEリンク内で最強Rayより40 dB以上弱いRayを、`h_true`への
複素合成から除外する。リンク間では比較せず、各リンクで独立に最強Rayを決める。

```matlab
cfgRT.enablePathPruning = true;
cfgRT.pathPruningThresholddB = 40;
```

Ray `l`の電力と相対電力は次式で計算する。

```matlab
pathPower = sum(abs(paths(l).contribution).^2);
pathPowerdB = 10*log10(pathPower);
relativePowerdB = 10*log10(pathPower/strongestPathPower);
```

`relativePowerdB <= -40`のRayを除外し、それより強いRayを合成する。LoS、反射、
回折の特別扱いは行わない。生成された全Rayは`pathInfo(m,k).paths`に残り、各Rayで
以下を確認できる。

- `pathPower`
- `pathPowerdB`
- `relativePowerdB`
- `isRetained`

リンク単位の`numPathsBeforePruning`、`numPathsAfterPruning`、
`strongestPathPowerdB`、`strongestPathIndex`、`strongestPathType`も`pathInfo`に保存する。
`enablePathPruning=false`では、全Rayを従来どおり複素合成する。

選択リンクのRay一覧表は自動表示され、次にも保存される。

```matlab
rtResult.selectedLink.pruningTable
```

## 伝搬モデル

- LoS直接波
- 各建物の側面および屋根を使った鏡像法による1回反射
- LoS遮断時のITU-R P.526型single knife-edge回折
- 各pathの複素位相を保持したcoherent sum
- APごとの物理座標ULA array response

各リンクは複数の異なる1回反射pathを持つことがある。ただし、1本のpath内での2回以上の反射、2回以上の回折、反射と回折の組合せは扱わない。

## 保存結果

既定では`ray_tracing_results_100GHz`に以下を保存する。

- `ray_tracing_channels_3D_results.mat`
- `ray_tracing_scenario.fig/.png`
- `ray_tracing_channel_gain.fig/.png`
- `ray_tracing_path_count.fig/.png`

## MATLABファイル構成

- entry/config: `main_ray_tracing_3D`, `configRayTracing3D`
- scenario: `generateScenario3D`, `generateAPPositions3D`, `generateUEPositions3D`, `generateObstacles3D`, `generateAPArrayPositions`
- geometry: `checkLoS3D`, `isBlocked3D`, `segmentIntersectsCuboid`, `transformToObstacleLocal`, `mirrorPointAcrossPlane`, `linePlaneIntersection`, `pointInsideRectangle3D`
- propagation: `generateRayTracingChannels3D`, `pruneRayPaths`, `findSingleBounceReflections3D`, `findSingleEdgeDiffractions3D`, `computeKnifeEdgeDiffractionLoss`, `computePathGain`, `computeAoAAoD3D`, `computeArrayResponse3D`
- inspection/plot: `inspectRayTracingLink`, `plotScenario3D`, `plotRayTracingChannelGainHeatmap`, `plotRayTracingPathCount`
- verification: `runRayTracingSanityChecks`, `reportToolboxes`

パイロット生成、パイロット受信、雑音生成、LS/LMMSE推定、NMSE、Monte Carloチャネル推定比較は含まない。

## 制限事項

- narrowband flat-fading channelであり、OFDM delay tapやDopplerは扱わない。
- reflection coefficientは簡略化した複素係数であり、材質・偏波・入射角の詳細モデルではない。
- diffractionはsingle knife-edge近似であり、厳密UTDや複数edge回折ではない。
- diffuse scattering、ground reflection、多重反射は未実装である。
