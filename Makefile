APP_NAME = Shrimpy
APP_BUNDLE = $(APP_NAME).app
INSTALL_DIR = /Applications
SRC = Shrimpy.swift
BINARY = $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

.PHONY: all build install clean

all: build

build: $(BINARY)

$(BINARY): $(SRC)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	swiftc $(SRC) -o $(BINARY) -framework AppKit -framework UserNotifications -framework ServiceManagement
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
<plist version="1.0"><dict>\n\
    <key>CFBundleExecutable</key><string>Shrimpy</string>\n\
    <key>CFBundleIdentifier</key><string>com.shrimpy.notifier</string>\n\
    <key>CFBundleName</key><string>Shrimpy</string>\n\
    <key>CFBundleVersion</key><string>1.0</string>\n\
    <key>CFBundleIconFile</key><string>Shrimpy</string>\n\
    <key>NSPrincipalClass</key><string>NSApplication</string>\n\
    <key>LSUIElement</key><true/>\n\
</dict></plist>\n' > $(APP_BUNDLE)/Contents/Info.plist
	cp Shrimpy.icns $(APP_BUNDLE)/Contents/Resources/Shrimpy.icns
	cp ShrimpyBar.png $(APP_BUNDLE)/Contents/Resources/
	cp "ShrimpyBar@2x.png" $(APP_BUNDLE)/Contents/Resources/

install: build
	rm -rf $(INSTALL_DIR)/$(APP_BUNDLE)
	cp -r $(APP_BUNDLE) $(INSTALL_DIR)/$(APP_BUNDLE)
	codesign --force --deep --sign - $(INSTALL_DIR)/$(APP_BUNDLE)
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $(INSTALL_DIR)/$(APP_BUNDLE)
	@echo "Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"

clean:
	rm -rf $(APP_BUNDLE)
