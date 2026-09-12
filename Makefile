TARGET := iphone:clang:latest:17.0
ARCHS := arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := CustomStatusBar

CustomStatusBar_FILES := Tweak.xm
CustomStatusBar_CFLAGS := -fobjc-arc
CustomStatusBar_FRAMEWORKS := UIKit CoreGraphics QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
