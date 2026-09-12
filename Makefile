# =============================================================================
#  ArcStatusBar — 极简点阵状态栏 Tweak
#  环境: iOS 17.0 (Relaxin / RootHide, rootless)  iPhone 14 Pro Max (arm64e)
# =============================================================================

export ARCHS = arm64
export TARGET = iphone:clang:16.0:14.0

# rootless (roothide) 打包方案: 安装到 /var/jb, 不碰系统分区
export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ArcStatusBar

ArcStatusBar_FILES = Tweak.x ArcStatusBarViews.m
ArcStatusBar_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

# -----------------------------------------------------------------------------
# 链接运行时: Relaxin/Dopamine(roothide) 环境内置 ellekit,
#  它兼容 substrate 符号 (MSHookMessageEx / MSHookFunction), 因此:
#    - 默认用 -lsubstrate, 在 relaxin 上可直接运行;
#    - 若你的 theos 环境没有 libsubstrate.tbd, 改为 -lellekit 即可
#      (需先安装 theos 的 ellekit: git clone https://github.com/theos/libellekit)
# -----------------------------------------------------------------------------
ArcStatusBar_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
