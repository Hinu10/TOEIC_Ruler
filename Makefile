PROJECT := TOEICRuler.xcodeproj
SCHEME := TOEICRuler
CONFIGURATION := Debug
SIMULATOR ?= iPhone 15
BUNDLE_ID := com.hinu10.TOEICRuler
DERIVED_DATA := .build/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)-iphonesimulator/$(SCHEME).app

.PHONY: simulator build install launch open-simulator boot-simulator check-xcode clean

simulator: check-xcode open-simulator boot-simulator build install launch

build: check-xcode
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-derivedDataPath "$(DERIVED_DATA)" \
		build

install:
	xcrun simctl install booted "$(APP_PATH)"

launch:
	xcrun simctl launch booted "$(BUNDLE_ID)"

open-simulator:
	open -a Simulator

boot-simulator:
	xcrun simctl boot "$(SIMULATOR)" || true

check-xcode:
	@if ! xcodebuild -version >/dev/null 2>&1; then \
		echo "xcodebuild が使えません。Xcode をインストールし、以下を実行してください:"; \
		echo "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"; \
		exit 1; \
	fi

clean:
	rm -rf "$(DERIVED_DATA)"
