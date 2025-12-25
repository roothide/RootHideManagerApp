ARCHS = arm64 arm64e
TARGET = iphone:latest:15.0
DEB_ARCH = iphoneos-arm64e
IPHONEOS_DEPLOYMENT_TARGET = 15.0

INSTALL_TARGET_PROCESSES = RootHide

THEOS_PACKAGE_SCHEME = roothide

FINALPACKAGE ?= 1
DEBUG ?= 0

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

before-all::
	echo "#define VARCLEANRULESHASH" $$(cksum -o 3 RootHide/VarCleanRules.json | awk '{print $$1}') > RootHide/VarCleanRules.h

clean::
	rm -rf ./packages/*

before-package::
	ldid -M -S./nickchan.entitlements $(THEOS_STAGING_DIR)/Applications/RootHide.app/RootHide

after-install::
	install.exec 'uiopen -b com.roothide.manager'
