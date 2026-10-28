#!/bin/bash
# rivena 的 LineageOS 24.0「結構探測」：只問「樹能不能被 Soong/BoardConfig/VINTF 接受」，
# 不做完整建置。理由是 24.0 這臺沒人做過，先花一次同步的錢換一個明確分類，
# 比直接押完整建置 3～6 小時後才知道卡在哪便宜。
#
# crave 那側沒有 LOS 24.0 的預同步專案（實測 `crave list` 只到 ID 99 = LOS 23.2），
# 所以走教學「非支援 ROM」那條路：借 23.2 的快照開工作區，再把 manifest 換成
# LineageOS 自己的 lineage-24.0。
set -euxo pipefail

repo init --depth=1 --no-repo-verify \
  -u https://github.com/LineageOS/android.git -b lineage-24.0 \
  -g default,-mips,-darwin,-notdefault

rm -rf .repo/local_manifests
git clone --depth 1 -b lineage-24.0 \
  https://github.com/Capricornus007/local_manifests .repo/local_manifests

# 先合併 manifest 再同步：重複 path（例如 24.0 snippets 已自帶的
# device/lineage/sepolicy）會在 resync 前就炸，這一步讓失敗訊息一眼可讀。
echo "==== PROBE: manifest merge check ===="
repo manifest -o /tmp/probe-manifest.xml
echo "==== PROBE: manifest OK ===="

df -h . || true
free -h || true

# crave 自己的同步入口（自己跑 `repo sync` 是會被Ban的動作）
/opt/crave/resync.sh

source build/envsetup.sh
# 刻意用 lunch 而不是 brunch：Lineage 的 brunch 會順手把整包編完，那不是這次要的
lunch lineage_rivena-userdebug
m nothing
echo "==== PROBE_OK：Soong/BoardConfig/VINTF 全過 ===="
