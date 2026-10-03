ARCHS = arm64
TARGET = iphone:clang::14.0
INSTALL_TARGET_PROCESSES = TikTok

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TikTokMediaDownloader

TikTokMediaDownloader_FILES = $(wildcard Sources/*.m Sources/*.xm)
TikTokMediaDownloader_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-error -Wno-incompatible-pointer-types
TikTokMediaDownloader_FRAMEWORKS = UIKit Foundation Photos AVFoundation AssetsLibrary

include $(THEOS_MAKE_PATH)/tweak.mk
