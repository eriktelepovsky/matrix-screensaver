BUNDLE_NAME = MatrixSaver
BUNDLE      = $(BUNDLE_NAME).saver
SDK         = $(shell xcrun --sdk macosx --show-sdk-path)
ARCH        = $(shell uname -m)
TARGET      = $(ARCH)-apple-macosx13.0

SWIFTFLAGS  = \
    -sdk $(SDK) \
    -target $(TARGET) \
    -module-name MatrixScreenSaver \
    -framework ScreenSaver \
    -framework AppKit

.PHONY: all install uninstall clean package

all: $(BUNDLE)

$(BUNDLE): MatrixScreenSaver.swift Info.plist
	mkdir -p $(BUNDLE)/Contents/MacOS
	mkdir -p $(BUNDLE)/Contents/Resources
	swiftc MatrixScreenSaver.swift $(SWIFTFLAGS) -Xlinker -bundle -o $(BUNDLE)/Contents/MacOS/$(BUNDLE_NAME)
	cp Info.plist $(BUNDLE)/Contents/Info.plist

install: all
	rm -rf ~/Library/Screen\ Savers/$(BUNDLE)
	cp -R $(BUNDLE) ~/Library/Screen\ Savers/
	rm -rf $(BUNDLE)
	-pkill -x "legacyScreenSaver" 2>/dev/null; true
	@echo "Installed and reloaded."

package:
	$(MAKE) $(BUNDLE)
	zip -r $(BUNDLE_NAME).zip $(BUNDLE)
	@echo "Created $(BUNDLE_NAME).zip — distribute this file to users."

uninstall:
	rm -rf ~/Library/Screen\ Savers/$(BUNDLE)

clean:
	rm -rf $(BUNDLE) $(BUNDLE_NAME).zip
