# =============================================================================
#  ArcStatusBar v2.1 (覆盖层方案) — 点阵状态栏形变动画
#  环境: iOS 17.0 / Relaxin / roothide  iPhone 14 Pro Max (A16, arm64e)
# =============================================================================

# SDK 必须与 theos/sdks 仓库中实际存在的目录精确匹配 (16.5)
export TARGET := iphone:clang:16.5:16.0
# A16 = arm64e, SpringBoard 是 arm64e 进程, 只能加载 arm64e slice
export ARCHS := arm64e

# scheme 不在这里写死, 由 workflow 传入:
#   THEOS_PACKAGE_SCHEME=roothide make package   <-- Relaxin 装这个
# (原版写死 rootless, 在 roothide 环境装上去不会生效)

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := ArcStatusBar

ArcStatusBar_FILES := \
    ArcStatusBar/Tweak.xm \
    ArcStatusBar/Core/ArcNativeState.m

ArcStatusBar_CFLAGS := -fobjc-arc
ArcStatusBar_FRAMEWORKS := UIKit CoreGraphics QuartzCore

# %hook 生成的 MSHookMessageEx 符号必须链接 substrate:
# roothide/theos 在 roothide scheme 下自动转成
# @loader_path/.jbroot/usr/lib/libsubstrate.dylib (由 ellekit 提供)。
# 参考插件 CAiPhoneDuoStatus 的二进制依赖实证了这一点。
# 缺失会导致链接失败或 dylib 符号不完整 -> 装上完全没效果。
ArcStatusBar_LIBRARIES := substrate

INSTALL_TARGET_PROCESSES := SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk

# 注意: 已移除原版 SUBPROJECTS += ArcStatusBarPrefs
# (PreferenceBundle 在 roothide 下的安装路径与 install.exec 均与 Relaxin 不兼容,
#  且本 tweak 不读取任何设置, 设置页为空壳, 只会引入编译/打包风险)
