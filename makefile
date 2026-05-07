.PHONY: all rebuild update-app-icon
.DEFAULT_GOAL := all

DERIVED_DATA := /Users/zhijiechen/Documents/autorpf/.build/DerivedData
ICON ?=
ICON_PATH := $(if $(ICON),$(abspath $(ICON)),)

all: update-app-icon rebuild

rebuild:
	rm -rf "$(DERIVED_DATA)"
	xcodebuild -project AutoRPF.xcodeproj -scheme AutoRPF -configuration Debug -derivedDataPath .build/DerivedData build

update-app-icon:
	@test -n "$(ICON_PATH)" || { echo "Usage: make update-app-icon ICON=/path/to/source-image.png" >&2; exit 1; }
	./scripts/update-app-icon.sh "$(ICON_PATH)"
