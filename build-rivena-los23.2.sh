#!/bin/bash
# realme RMX3366 (rivena) 的 LineageOS 23.2 建置腳本，給 foss.crave.io 的雲端工作區跑。
#
# 本機只需要一行（腳本自己拉自己，避免在命令列裡逃字符）：
#   crave fullbuild --projectID 99 --keep-workspace -- \
#     "curl -fsSL https://raw.githubusercontent.com/Capricornus007/rivena-lineage-build/main/build-rivena-los23.2.sh | bash"
#
# 前提：專案 99（LOS 23.2）的快照已經在雲端展開，工作區根目錄就是 repo 的根
# （日誌實測 `repo: reusing existing repo client checkout in /tmp/src/android`），
# 所以這裡**不做** repo init——換 manifest 是「非支援 ROM」那條路才需要的，
# 用 LOS 自己的基底卻重 init 只會把快照弄髒。
set -euxo pipefail

MANIFEST_REPO="${MANIFEST_REPO:-https://github.com/RMX3366-Development/local_manifests}"
MANIFEST_BRANCH="${MANIFEST_BRANCH:-lineage-23.2}"
DEVICE="${DEVICE:-rivena}"

# local_manifests 帶進 device/kernel/vendor/hardware 的全部指向（九條 project，
# 見該倉 default.xml）；先清掉是防上一輪留的殘檔
rm -rf .repo/local_manifests
git clone --depth 1 -b "$MANIFEST_BRANCH" "$MANIFEST_REPO" .repo/local_manifests

# crave 自己的同步入口（比 raw `repo sync` 合規；後者是會被Ban的動作）
/opt/crave/resync.sh

source build/envsetup.sh
brunch "$DEVICE" userdebug
mka bacon

# 產物**不往任何外站傳**（不 pixeldrain、不 GitHub PAT、不 telegram session），
# 只列出來，取回用本機 `crave pull <路徑> -d .`
echo "==== artifacts ===="
ls -lh "out/target/product/$DEVICE"/*.zip 2>/dev/null || echo "NO_ZIP"
