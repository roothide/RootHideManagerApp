export ARCHS = arm64
export TARGET = iphone:latest:15.0
export DEB_ARCH = iphoneos-arm64
export IPHONEOS_DEPLOYMENT_TARGET = 15.0

THEOS_DEVICE_IP = iphone11.local

INSTALL_TARGET_PROCESSES = RootHide

include $(THEOS)/makefiles/common.mk

XCODE_SCHEME = RootHide

XCODEPROJ_NAME = RootHide

RootHide_XCODEFLAGS = MARKETING_VERSION=$(THEOS_PACKAGE_BASE_VERSION) \
	IPHONEOS_DEPLOYMENT_TARGET="$(IPHONEOS_DEPLOYMENT_TARGET)" \
	CODE_SIGN_IDENTITY="" \
	AD_HOC_CODE_SIGNING_ALLOWED=YES
RootHide_XCODE_SCHEME = $(XCODE_SCHEME)
RootHide_CODESIGN_FLAGS = -Sentitlements.plist
RootHide_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/xcodeproj.mk

clean::
	rm -rf ./packages/*

