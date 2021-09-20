# alpha更新日志

## Magisk (0f71edee-alpha)
- [App] 支持SharedUserId
- [App] 还原boot镜像后删除备份文件
- [App] 内置当前版本更新日志
- [App] 当无法下载stub时使用本地版本
- [App] 切换到Java 8的现代时间API
- [General] 不再自动解锁设备块
- [General] Zygisk关闭时使用MagiskHide实现隐藏
- [App] 删除markdown渲染
- [General] 不执行已忽略加载模块的脚本
- [App] 修复无法从通知更新Magisk
- [App] 修复第二次点按隐藏app按钮可能无反应
- [App] 修复签名证书生效时间
- [App] 开启网络请求缓存
- [App] 重写安装应用功能
- [App] 增强修复环境功能功能
- [App] 修复排除列表部分进程可能不显示
- [App] 支持设置KEEPVBMETAFLAG标志，以跳过处理boot镜像中的vbmeta
- [Zygisk] 修复Xhook

### 如何安装？
通过Magisk应用来安装和卸载Magisk，一般情况应直接在应用内完成，第一次安装等特殊情况应修补镜像后使用fastboot/odin工具刷入。
通过自定义Recovery不是受支持的方式。

# 上游更新日志

## Magisk (5d6d2417) (23015)

- Cleanup unclosed fds leftover from Zygisk modules
- Fix parallel app info fetching in DenyList UI to speed things up
- Export `ZYGISK_ENABLED` to boot scripts if Zygisk is enabled
- Fix v4 vendor boot unpacking/repacking
- Add new env variable `KEEPVBMETAFLAG` to toggle configure vbmeta flags should be preserved
- Update BusyBox to 1.34.1

## Diffs to v23.0

- [General] MagiskHide is removed from Magisk
- [General] Support 64-bit only systems
- [General] Support Android 12
- [General] Update BusyBox to 1.34.1
- [Zygisk] Introduce new feature: Zygisk
- [Zygisk] Introduce DenyList feature to revert Magisk features in user selected processes
- [MagiskBoot] Support patching 32-bit kernel zImages
- [MagiskBoot] Support boot image header v4
- [MagiskBoot] Support patching out `skip_initramfs` from dtb bootargs
- [MagiskBoot] Add new env variable `KEEPVBMETAFLAG` to configure whether vbmeta flags should be preserved
- [MagiskInit] Support `/proc/bootconfig` for loading boot configurations
- [MagiskInit] Better support for some Meizu devices
- [MagiskInit] Better support for some Oppo/Realme devices
- [MagiskInit] Support `init.real` on some Sony devices
- [MagiskPolicy] Load `*_compat_cil_file` from system_ext
- [MagiskSU] Use isolated devpts if the kernel supports it
- [MagiskSU] Fix root shell if isolated mount namespace is set
- [resetprop] Deleted properties are now wiped from memory instead of just unlinking
- [App] Build a single APK for all ABIs
- [App] Switch to use standard bottom navigation bar
- [App] Downloading modules within the Magisk app is removed
