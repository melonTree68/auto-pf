.PHONY: all rebuild update-app-icon build-release package-release
.DEFAULT_GOAL := all

DERIVED_DATA := /Users/zhijiechen/Documents/auto-rpf/.build/DerivedData
RELEASE_DIR := /Users/zhijiechen/Documents/auto-rpf/.build/release
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/AutoRPF.app
VERSION ?= $(shell tag=$$(git describe --tags --exact-match 2>/dev/null); if [ -n "$$tag" ]; then printf "%s" "$${tag\#v}"; else printf "dev"; fi)
PACKAGE := $(RELEASE_DIR)/AutoRPF-v$(VERSION)-macos.zip
ICON ?=
ICON_PATH := $(if $(ICON),$(abspath $(ICON)),)

all: update-app-icon rebuild

rebuild:
	rm -rf "$(DERIVED_DATA)"
	xcodebuild -project AutoRPF.xcodeproj -scheme AutoRPF -configuration Debug -derivedDataPath .build/DerivedData build

update-app-icon:
	@test -n "$(ICON_PATH)" || { echo "Usage: make update-app-icon ICON=/path/to/source-image.png" >&2; exit 1; }
	./scripts/update-app-icon.sh "$(ICON_PATH)"

build-release:
	xcodebuild -project AutoRPF.xcodeproj -scheme AutoRPF -configuration Release -derivedDataPath .build/DerivedData MARKETING_VERSION="$(VERSION)" build

package-release: build-release
	mkdir -p "$(RELEASE_DIR)"
	rm -f "$(PACKAGE)"
	ditto -c -k --keepParent "$(RELEASE_APP)" "$(PACKAGE)"
	@echo "Created $(PACKAGE)"
