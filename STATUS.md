# rivena (RMX3366) · LineageOS 24.0 构建 —— 状态：暂时搁置

> 更新：2026-11-01
> 状态：**暂停 / BLOCKED —— 资源不可达，非技术问题。**

## 一、为什么停

1. **crave.io 免费服务 2026-11-05 关停**
   - ROM-builders 群公告原文：「The free availability of Crave on foss.crave.io will end on November 5th, 2026. Signups have already been frozen. Tokens purchase will be disabled in one day. Tokens need to be used up by the 10th of November.」
   - 实测：`crave list` 还能通，但 `crave devspace` / `fullbuild` 已 503 / 排队卡死（进 devspace 2 分钟无任何输出）。
   - crave 是这台机器唯一能用的免费大机器来源。

2. **没有免费替代**
   - GitHub Actions：标准 runner 仅 70–80GB 存储，装不下 Android 16 源码（群友原话：`github action will no work cuz they have like 80GB storage`）。
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
