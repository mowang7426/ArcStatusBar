include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := ArcStatusBarPrefs
ArcStatusBarPrefs_FILES := ArcStatusBarPrefs/ArcStatusBarPrefs.m
ArcStatusBarPrefs_FRAMEWORKS := UIKit
ArcStatusBarPrefs_PRIVATE_FRAMEWORKS := Preferences
ArcStatusBarPrefs_INSTALL_PATH := /Library/PreferenceBundles
ArcStatusBarPrefs_CFLAGS := -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 Preferences || true"
