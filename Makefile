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
# 链接 substrate —— roothide/theos 在 roothide scheme 下会自动把 -lsubstrate
# 转成 @loader_path/.jbroot/usr/lib/libsubstrate.dylib (参考已在 Relaxin 正常
# 工作的同类插件 CAiPhoneDuoStatus 的二进制依赖实证)。ellekit 在越狱环境提供
# libsubstrate.dylib (符号链接), 加载期解析 MSHookMessageEx 等符号。
# 不要改成 ellekit (roothide/theos 无 ellekit.tbd, 会报 ld: library 'ellekit' not found)。
# -----------------------------------------------------------------------------
ArcStatusBar_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
