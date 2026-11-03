# rivena (RMX3366) · LineageOS 24.0 构建 —— 状态：暂时搁置

> 更新：2026-11-04
> 状态：**暂停 / BLOCKED —— 资源不可达，非技术问题。**
> 2026-11-04 用 GitHub Actions 的结构探测 workflow 把「免费云机这条路能不能走」量成了**实测结论**
> （见第六节），不再是引用群友说法。

## 一、为什么停

1. **crave.io 免费服务 2026-11-05 关停**
   - ROM-builders 群公告原文：「The free availability of Crave on foss.crave.io will end on November 5th, 2026. Signups have already been frozen. Tokens purchase will be disabled in one day. Tokens need to be used up by the 10th of November.」
   - 实测：`crave list` 还能通，但 `crave devspace` / `fullbuild` 已 503 / 排队卡死（进 devspace 2 分钟无任何输出）。
   - crave 是这台机器唯一能用的免费大机器来源。

2. **没有免费替代**
   - GitHub Actions：标准 runner 仅 70–80GB 存储，装不下 Android 16 源码（群友原话：`github action will no work cuz they have like 80GB storage`）。
     **2026-11-04 已由本倉 workflow 實測證實，見第六節。**
   - Oracle Always Free（4 ARM / 24G / 200G）：账号注册不了。
   - ServerHive：最便宜的付费替代，约 **$1.5/次构建** 或 **$3/3 天**（medium 编 A16 约 40 分钟）；**无预算**。

3. **本地构建不可行**
   - 本机：Ryzen 5 5600U（6C/12T）、14GB RAM、20GB swap —— CPU/内存够慢编（约 8–12 小时）。
   - **磁盘仅 ~121GB 空闲**（`/` 45G + `/home` 76G）；LOS 24.0 源码 ~150–200GB + 产物 ~50GB，需 **~250GB–1TB**。
   - 用户明确：**没有 1TB 起步空间，不考虑本地编系统。**

## 二、已就绪（资源到位即可继续）

- `PORT-24.0-checklist.md` —— 完整移植地图（10 项 + 3 大难点：hardware/dolby、AIDL/.hash、extract-files.py）。manifest 8 个项目已 ls-remote 复核（2026-11-01），revision 均真实存在。
- `build-rivena-los24.0-probe.sh` —— 结构探测脚本（`repo init` lineage-24.0 → `resync.sh` → `lunch` → `m nothing`）。
- `build-rivena-los23.2.sh` —— 可用的完整构建参考。
- 关键规则：**`repo sync` 是违规操作（会被 Ban），必须用 crave 的 `/opt/crave/resync.sh`；`repo init` 允许**（但 23.2 快照别重 init）。

## 三、恢复条件（任一满足即可重启）

- 本地腾出 **≥250GB**（外接硬盘 / 清盘）→ 本地过夜编；
- 有 **~$1.5** 用 ServerHive（或抽到其 giveaway）；
- 出现新的免费 Android 构建服务。

## 四、crave 现状备忘（供以后参考）

- 账号：`sihaogang@gmail.com`；token 在 `~/Downloads/crave.conf`。
- 项目：**ID 99 = LOS 23.2**（预同步）；devspace 平台 `n2d-custom-4-65536-ext`（4 vCPU / 64GB）。
- 关停：`foss.crave.io` 免费版 **2026-11-05** 结束，token 11-10 前用完。

## 五、可先做的（不耗资源）

移植本身是**读代码 / diff / 改 device 树**的活，不占磁盘与算力，现在就能推进——按 `PORT-24.0-checklist.md` 逐项改，等有机器时一次性验证。

## 六、2026-11-04 GitHub Actions 结构探測實測結果（結論：磁碟不夠，路死）

workflow：`.github/workflows/los24-structure-probe.yml`（只手動觸發）。run `41690289419`。

先把座標查清楚（前三次紅都是我自己編倉名，沒去查倉在不在）：

- 平台 manifest 倉＝**`LineageOS/android`**，根目錄只有 `README.mkdn` / `default.xml` / `snippets/`，
  官方指令是 `repo init -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs`。
- `LineageOS/manifest` 這倉**不存在**（`gh api` 回 404）。GitHub 對匿名 HTTPS 拉不存在的倉回的是
  「git requires authentication」而不是 404，所以那三次紅的錯誤訊息一直在把人往 git 設定上帶。
  `snippets/lineage.xml` 只是 `<include>` 用的片段，不是 top-level manifest，拿它當 `-m` 一定找不到。
- rivena **不是 LineageOS 官方支援裝置**（`LineageOS/android_device_realme_rivena` 也 404），
  `default.xml`（1067 個 project）與 `snippets/lineage.xml` 都不含 `device/realme/rivena`；
  裝置 tree 全部來自 **`Capricornus007/local_manifests` 的 `lineage-24.0` 分支**（8 塊）。
  workflow 因此多了「掛 local_manifests」這步，並在 sync 前用 `repo manifest -o` 驗 8 塊齊不齊。

實測走到哪：裝 repo/git-lfs ✓ → 清掉 runner 預裝的 dotnet / Android SDK / hostedtoolcache ✓ →
`repo init`（`--depth=1 --partial-clone --clone-filter=blob:limit=10M --git-lfs`）✓ →
local_manifests 合併檢查 ✓（8 塊全在）→ **`repo sync` 中途把磁碟寫爆**，job 註解是
`System.IO.IOException: No space left on device`，連 runner 自己的 `_diag/Worker_*.log` 都寫不進去。

結論：**就算 shallow + partial clone + 清掉影像裡約 25GB，免費 runner 的 ~84GB 根分區仍然裝不下
LOS 24.0 源码**。這不是調參數能救的——`m nothing` 需要整個平台樹，不能只同步一半。
所以第一節第 2 點那條「GitHub Actions 不行」從群友說法升級成實測數據；剩下的路只有第三節那兩條
（本機騰 ≥250GB，或花錢）。
