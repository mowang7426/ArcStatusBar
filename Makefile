TARGET := iphone:clang:latest:17.0
ARCHS := arm64e
THEOS_PACKAGE_SCHEME := rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := ArcStatusBar

ArcStatusBar_FILES := \
	ArcStatusBar/Tweak.xm \
	ArcStatusBar/UI/ArcMorphView.m \
	ArcStatusBar/UI/ArcStatusController.m \
	ArcStatusBar/State/ArcNetworkState.m \
	ArcStatusBar/State/ArcBatteryState.m

ArcStatusBar_CFLAGS := -fobjc-arc
ArcStatusBar_FRAMEWORKS := UIKit CoreGraphics QuartzCore CoreTelephony

INSTALL_TARGET_PROCESSES := SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk
