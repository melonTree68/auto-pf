.PHONY: all rebuild update-app-icon build-release package-release
.DEFAULT_GOAL := all

DERIVED_DATA := $(CURDIR)/.build/DerivedData
RELEASE_DIR := $(CURDIR)/.build/release
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/AutoPF.app
VERSION ?= $(shell tag=$$(git describe --tags --exact-match 2>/dev/null); if [ -n "$$tag" ]; then printf "%s" "$${tag\#v}"; else printf "dev"; fi)
PACKAGE := $(RELEASE_DIR)/AutoPF-v$(VERSION)-macos.zip
ICON ?=
ICON_PATH := $(if $(ICON),$(abspath $(ICON)),)

all: update-app-icon rebuild

rebuild:
	rm -rf "$(DERIVED_DATA)"
	xcodebuild -project AutoPF.xcodeproj -scheme AutoPF -configuration Debug -derivedDataPath .build/DerivedData build

update-app-icon:
	@test -n "$(ICON_PATH)" || { echo "Usage: make update-app-icon ICON=/path/to/source-image.png" >&2; exit 1; }
	./scripts/update-app-icon.sh "$(ICON_PATH)"

build-release:
	xcodebuild -project AutoPF.xcodeproj -scheme AutoPF -configuration Release -derivedDataPath .build/DerivedData MARKETING_VERSION="$(VERSION)" build

package-release: build-release
	mkdir -p "$(RELEASE_DIR)"
	rm -f "$(PACKAGE)"
	ditto -c -k --keepParent "$(RELEASE_APP)" "$(PACKAGE)"
	@echo "Created $(PACKAGE)"
