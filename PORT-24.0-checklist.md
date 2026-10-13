# rivena → LineageOS 24.0 移植檢查清單

藍本來源：`LineageOS/android_device_oneplus_sm8250-common` 的 `lineage-23.2...lineage-24.0`
（10 筆）與 `android_device_xiaomi_sm8250-common`（12 筆）逐筆 diff，外加
`android_hardware_oplus`（55 筆 / 116 檔）的主題歸納。**官方沒有 23.2→24.0 的維護者遷移文件**
（`lineage_wiki` 只剩機型頁、`LineageOS/android` 只有 manifest），所以本檔就是地圖。
排序依「會不會炸編譯」，不是依好看程度。

## 要做（附官方 SHA 與 rivena 對應檔案）

1. **libion legacy**（77fac2d4b oneplus / 9ae6e7511 xiaomi）
   - `BoardConfigCommon.mk` 加 `include device/lineage/sepolicy/libion/sepolicy.mk`
   - `common.mk` 加 `$(call soong_config_set_bool,libion,legacy_impl,true)`
   - **local_manifests 要另外掛 `LineageOS/android_device_lineage_sepolicy`（實測 24.0 有 `libion/`）**
   - rivena：`android_device_oppo_sm8250-common` 的 `BoardConfigCommon.mk` / `common.mk`
2. **recovery rc 拆成獨立 prebuilt_etc**（6cb0723b5）
   - `init/Android.bp` 把 `recovery_available: true` 改成 `prebuilt_etc { name: "init.oplus.hw.recovery.rc", src: "init.oplus.hw.rc", recovery: true }`，PRODUCT_PACKAGES 跟著改名
   - rivena：`common.mk:179-180` 仍是舊的 `init.oplus.hw.rc.recovery`；`android_device_realme_rivena/init/Android.bp` 同改
3. **刪 `PRODUCT_ENABLE_UFFD_GC := true`**（6fb6b622c / 853b9e32f）→ rivena `common.mk:197`
4. **刪 `TARGET_KERNEL_NO_GCC := true`**（daa616d0d / a076bb5df）→ rivena `BoardConfigCommon.mk:95`
   - ⚠️ 別跟著改 Clang：oneplus 那筆 Clang r563880c（b1be33565）**已被 5699b427d 還原**
5. **configstore / fastbootd / 重開機選單**：拿掉 `disable_configstore`（96de2afd8）、fastbootd 預設開（0e4a5b4fd）、刪 `overlay-lineage/lineage-sdk/.../config.xml` 的 `config_restartActionsList`（24ac51b48）
6. **WFD 三連動**（見下方「A14 blob 不能照抄」）：2e4b339e7 + 987cad798 + `extract-files.py:105-106`
7. **sepolicy**：`devicesettings_app` 加 `coredomain`（e695de6d7）。rivena 的 device 樹**沒有 sepolicy 目錄**，策略在 `hardware/oplus/sepolicy/qti` → 直接吃官方 `hardware_oplus:lineage-24.0`（manifest 已指官方，正確）
8. **display TP10 UBWC**：`common.mk` 加 `$(call soong_config_set,qtidisplay,target_uses_tp10_ubwc_for_10bit,true)`（97cc87013）
9. **soong namespace 收窄**：`hardware/google/pixel` → `.../power-libperfmgr`（68910d87f）
10. 選做：`PRODUCT_PACKAGES` 整理／顯示服務分組（9f0a4194e）、`vendor.prop` 的 `spkr_prot=true`（b84fe80a5）

## A14 blob 讓這幾項「不能照抄」（rivena 的 blob 是 `RMX3366_14.0.0.2100(CN01)`）

- **WFD 那組（987cad798 / 4210c9bf5）假定 A16/A17 抽出的 blob**：`WfdCommon.jar apktool_patch`、
  `libwfdservice.so` 的 `android.media.audio.common.types-V4-cpp → V5-cpp`、移除
  `libwfdnative.so + libinput_shim.so`。rivena 的 `WfdCommon.jar|76fab5ed…` 與
  `libwfdservice.so|af0e31f1…` 是 A14，patch 極可能 signature 不符
  → **先只做「砍 system 那批」（2e4b339e7），保留現有 fixup，等編譯報錯再逐條調**
- **xiaomi 的 property 改名（d19506529，`audio.offload.` → `vendor.audio.offload.`）是它自己的清單，rivena 照抄會讓 A14 HAL 讀不到屬性**
- VINTF 抬版（6e6f3dd8d `stability.oplus_project` → V3、35a907fbe 加 `vendor.dolby.dvs`）假定新 vendor manifest；rivena 若 FCM level 不夠，要在 device 端 matrix fragment 降版
- 反過來說 **08d96d73c（CP2A 相容映射）正是「舊 vendor＋新 framework」需要的**，rivena 直接受益
- 官方 24.0 仍保留 `PRODUCT_USE_PRODUCT_VNDK_OVERRIDE := true`，所以 device 樹那行**不是**炸點

## 三塊最難的（realme 限定）

1. **`hardware/dolby`**：`16` 分支有 10 處硬 link `libstagefright_foundation-v33` 與 `libcodec2_vndk`，
   A17 砍掉 VNDK 版本化存根 → 整包掛。該倉只有 `16` / `lineage-23.2` / `lunairs/lineage-23.1`，
   **沒有 24.0**，而 `LineageOS/android_hardware_dolby` 實測 404 —— **無官方範本可抄，這塊要自己寫**
2. **AIDL 版本與 `.hash`**：OnePlus 的修法是改 interfaces 去就新 blob；rivena 的 touch/oplusSensor HAL
   來自 A14 的 `proprietary_vendor_oppo_sm8250-common`，很可能要回退成 `current` 或補 local 版本，
   否則 `check_elf_files` / VINTF 直接紅
3. **`extract-files.py` 的版本重貼＋`blob-patches/WfdCommon.patch`**：patch 是照 A17 版 jar 做的

## hardware_oplus 55 筆的主題（只要指官方分支就自動拿到，記錄用）

sepolicy/qti 大量新增＋CP2A 相容映射（08d96d73c）、PowerOffAlarm 型轉 private（8dd356e14）、
touch AIDL 凍結 `.hash`＋新增 `IOplusTouchEventCallback`/`OplusTouchStatus`＋修 V1 `initialize()`
回傳型別（a46ef8ef6）與 V2 方法（96a1e3795）、新增 `vendor.oplus.hardware.oplusSensor` V1（888d557fe）、
VINTF 抬版（6e6f3dd8d / 35a907fbe / 1a56aa443）、soong select HTPR（709b52552）、
新增 `extract-utils-ext`（359f121b1）、**`folio-daemon: RIP`（e6995709c）**、sensors 搬子目錄（acee837e9）。
