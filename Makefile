# =============================================================================
#  ArcStatusBar — 极简点阵状态栏 Tweak
#  环境: iOS 17.0 (Relaxin / RootHide, roothide)  iPhone 14 Pro Max (arm64e)
# =============================================================================

# arm64e 必须保留: iPhone 14 Pro Max 是 A16 (arm64e), SpringBoard 是 arm64e
# 进程, 只能加载含 arm64e slice 的 tweak; 只编 arm64 会注入失败(装上没效果)。
export ARCHS = arm64 arm64e
# 平台:编译器:SDK版本:部署版本 —— SDK 版本必须与 theos/sdks 仓库中实际存在的
# iPhoneOS16.5.sdk 精确匹配 (仓库没有 16.0, 精确匹配会报错)
export TARGET = iphone:clang:16.5:14.0

# 注意: 不要在这里写死 THEOS_PACKAGE_SCHEME!
# 由构建命令传入 (workflow 会用 rootless / roothide 各编译一次):
#   THEOS_PACKAGE_SCHEME=rootless make package
#   THEOS_PACKAGE_SCHEME=roothide make package   <-- Relaxin 装这个

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ArcStatusBar

ArcStatusBar_FILES = Tweak.x ArcStatusBarViews.m
ArcStatusBar_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

# -----------------------------------------------------------------------------
# 不链接任何 hook 库 (不写 LIBRARIES):
# roothide/theos 的 lib/ 目录为空, 不提供 ellekit.tbd / libsubstrate.tbd,
# 写 -lellekit 或 -lsubstrate 都会报 ld: library not found。
# Logos %hook 生成的 MSHookMessageEx 等符号由 Relaxin 内的 ellekit 运行时
# 在设备端解析 (参考 ssl-kill-switch3 等 roothide tweak 的标准写法)。
# -----------------------------------------------------------------------------

include $(THEOS_MAKE_PATH)/tweak.mk
