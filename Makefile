APP_NAME = Shrimpy
APP_BUNDLE = $(APP_NAME).app
INSTALL_DIR = /Applications
SRC = $(wildcard Sources/*.swift)
BINARY = $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
VERSION = 1.0.0
DEVELOPER_ID ?= Developer ID Application: Liam Hitchcock (C88QPDDXK4)
APPLE_ID ?= your@email.com
APPLE_TEAM_ID ?= C88QPDDXK4
XCODE_DEV_DIR = /Applications/Xcode.app/Contents/Developer
SWIFTC = xcrun swiftc
BUILD_DIR = .build
BUILD_TMP = $(BUILD_DIR)/tmp
BUILD_MODULE_CACHE = $(BUILD_DIR)/module-cache

ifneq ("$(wildcard $(XCODE_DEV_DIR))","")
export DEVELOPER_DIR ?= $(XCODE_DEV_DIR)
endif

export CLANG_MODULE_CACHE_PATH ?= $(CURDIR)/$(BUILD_MODULE_CACHE)
export TMPDIR ?= $(CURDIR)/$(BUILD_TMP)/

.PHONY: all build install sign notarize release clean codex codex-notify-test dev-restart

all: build

build: $(BINARY)

$(BINARY): $(SRC)
	mkdir -p $(BUILD_TMP)
	mkdir -p $(BUILD_MODULE_CACHE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	$(SWIFTC) $(SRC) -o $(BINARY) -framework AppKit -framework UserNotifications -framework ServiceManagement
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
<plist version="1.0"><dict>\n\
    <key>CFBundleExecutable</key><string>Shrimpy</string>\n\
    <key>CFBundleIdentifier</key><string>com.shrimpy.notifier</string>\n\
    <key>CFBundleName</key><string>Shrimpy</string>\n\
    <key>CFBundleVersion</key><string>$(VERSION)</string>\n\
    <key>CFBundleShortVersionString</key><string>$(VERSION)</string>\n\
    <key>CFBundleIconFile</key><string>Shrimpy</string>\n\
    <key>NSPrincipalClass</key><string>NSApplication</string>\n\
    <key>LSUIElement</key><true/>\n\
</dict></plist>\n' > $(APP_BUNDLE)/Contents/Info.plist
	cp Shrimpy.icns $(APP_BUNDLE)/Contents/Resources/Shrimpy.icns
	cp ShrimpyBar.png $(APP_BUNDLE)/Contents/Resources/
	cp "ShrimpyBar@2x.png" $(APP_BUNDLE)/Contents/Resources/

sign: build
	codesign --force --deep --options runtime \
	  --sign "$(DEVELOPER_ID)" \
	  $(APP_BUNDLE)

notarize: sign
	ditto -c -k --sequesterRsrc --keepParent $(APP_BUNDLE) Shrimpy-$(VERSION).zip
	xcrun notarytool submit Shrimpy-$(VERSION).zip \
	  --apple-id "$(APPLE_ID)" \
	  --team-id "$(APPLE_TEAM_ID)" \
	  --password "@keychain:AC_PASSWORD" \
	  --wait
	xcrun stapler staple $(APP_BUNDLE)

release: notarize
	ditto -c -k --sequesterRsrc --keepParent $(APP_BUNDLE) Shrimpy-$(VERSION).zip
	@echo "SHA256:"
	shasum -a 256 Shrimpy-$(VERSION).zip

install: sign
	rm -rf $(INSTALL_DIR)/$(APP_BUNDLE)
	cp -r $(APP_BUNDLE) $(INSTALL_DIR)/$(APP_BUNDLE)
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $(INSTALL_DIR)/$(APP_BUNDLE)
	@echo "Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"

clean:
	rm -rf $(APP_BUNDLE)

codex:
	./scripts/codex-notify.sh $(ARGS)

codex-notify-test:
	./scripts/codex-notify.sh --test

dev-restart: build
	rm -rf $(INSTALL_DIR)/$(APP_BUNDLE)
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/$(APP_BUNDLE)
	codesign --force --deep --sign - $(INSTALL_DIR)/$(APP_BUNDLE)
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $(INSTALL_DIR)/$(APP_BUNDLE)
	killall Shrimpy || true
	open -gj $(INSTALL_DIR)/$(APP_BUNDLE)
