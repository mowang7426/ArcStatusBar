# =============================================================================
#  ArcStatusBar — 极简点阵状态栏 Tweak
#  环境: iOS 17.0 (Relaxin / RootHide, roothide)  iPhone 14 Pro Max (arm64e)
# =============================================================================

export ARCHS = arm64
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
# 链接 ellekit (roothide 生态的标准 hook 运行时, Relaxin/RootHide 自带)。
# 注意: roothide scheme 下链接 substrate 会报 "framework not found
# CydiaSubstrate" (theos issue #853), 因此这里必须用 ellekit。
# 若你的 theos 环境没有 ellekit.tbd, 可改回 substrate。
# -----------------------------------------------------------------------------
ArcStatusBar_LIBRARIES = ellekit

include $(THEOS_MAKE_PATH)/tweak.mk
