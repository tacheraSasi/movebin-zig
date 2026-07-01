.PHONY: all build run dev clean test lint deps release checksums \
        build-all build-linux build-darwin build-windows

# ── Variables ────────────────────────────────────────────────────────────────
APP_NAME    := movebin
VERSION     := $(shell grep "VERSION" src/constants.zig | awk -F'"' '{print $$2}')
COMMIT      := $(shell git rev-parse --short HEAD 2>/dev/null || echo "dev")
BUILD_DIR   := ./release-bins
ZIG_FLAGS   :=
RELEASE     := -Doptimize=ReleaseSafe

# ── Development ───────────────────────────────────────────────────────────────
build:
	zig build $(ZIG_FLAGS)

run: build
	zig build run

dev:
	zig build run --

deps:
	zig build

test:
	zig build test

lint:
	zig fmt --check src/

clean:
	rm -rf zig-out/ release-bins/ .zig-cache/

# ── Cross-platform builds ────────────────────────────────────────────────────
build-all: | $(BUILD_DIR)
	@echo "==> Building for all platforms ($(VERSION))..."
	$(MAKE) build-linux
	$(MAKE) build-darwin
	$(MAKE) build-windows
	@echo "==> Done! Binaries in $(BUILD_DIR)/"

build-linux: | $(BUILD_DIR)
	@echo "==> Building for Linux..."
	zig build -Dtarget=x86_64-linux-gnu $(RELEASE) --prefix $(BUILD_DIR)/linux-amd64 2>/dev/null
	@cp $(BUILD_DIR)/linux-amd64/bin/$(APP_NAME) $(BUILD_DIR)/$(APP_NAME)-linux-amd64
	@rm -rf $(BUILD_DIR)/linux-amd64
	zig build -Dtarget=aarch64-linux-gnu $(RELEASE) --prefix $(BUILD_DIR)/linux-arm64 2>/dev/null
	@cp $(BUILD_DIR)/linux-arm64/bin/$(APP_NAME) $(BUILD_DIR)/$(APP_NAME)-linux-arm64
	@rm -rf $(BUILD_DIR)/linux-arm64
	cd $(BUILD_DIR) && cp $(APP_NAME)-linux-amd64 $(APP_NAME) && \
		tar czf $(APP_NAME)-linux-amd64.tar.gz $(APP_NAME) && rm $(APP_NAME)
	cd $(BUILD_DIR) && cp $(APP_NAME)-linux-arm64 $(APP_NAME) && \
		tar czf $(APP_NAME)-linux-arm64.tar.gz $(APP_NAME) && rm $(APP_NAME)

build-darwin: | $(BUILD_DIR)
	@echo "==> Building for macOS..."
	zig build -Dtarget=x86_64-macos-none $(RELEASE) --prefix $(BUILD_DIR)/darwin-amd64 2>/dev/null
	@cp $(BUILD_DIR)/darwin-amd64/bin/$(APP_NAME) $(BUILD_DIR)/$(APP_NAME)-darwin-amd64
	@rm -rf $(BUILD_DIR)/darwin-amd64
	zig build -Dtarget=aarch64-macos-none $(RELEASE) --prefix $(BUILD_DIR)/darwin-arm64 2>/dev/null
	@cp $(BUILD_DIR)/darwin-arm64/bin/$(APP_NAME) $(BUILD_DIR)/$(APP_NAME)-darwin-arm64
	@rm -rf $(BUILD_DIR)/darwin-arm64
	cd $(BUILD_DIR) && cp $(APP_NAME)-darwin-amd64 $(APP_NAME) && \
		tar czf $(APP_NAME)-darwin-amd64.tar.gz $(APP_NAME) && rm $(APP_NAME)
	cd $(BUILD_DIR) && cp $(APP_NAME)-darwin-arm64 $(APP_NAME) && \
		tar czf $(APP_NAME)-darwin-arm64.tar.gz $(APP_NAME) && rm $(APP_NAME)

build-windows: | $(BUILD_DIR)
	@echo "==> Building for Windows..."
	zig build -Dtarget=x86_64-windows-gnu $(RELEASE) --prefix $(BUILD_DIR)/windows-amd64 2>/dev/null
	@cp $(BUILD_DIR)/windows-amd64/bin/$(APP_NAME).exe $(BUILD_DIR)/$(APP_NAME)-windows-amd64.exe
	@rm -rf $(BUILD_DIR)/windows-amd64
	cd $(BUILD_DIR) && cp $(APP_NAME)-windows-amd64.exe $(APP_NAME).exe && \
		zip $(APP_NAME)-windows-amd64.zip $(APP_NAME).exe && rm $(APP_NAME).exe

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# ── SHA256 checksums ─────────────────────────────────────────────────────────
checksums:
	@echo "==> Generating checksums..."
	cd $(BUILD_DIR) && shasum -a 256 *.tar.gz *.zip > checksums.txt
	@cat $(BUILD_DIR)/checksums.txt

# ── GitHub Release ───────────────────────────────────────────────────────────
# Usage:
#   make release                              # builds all, creates tag & release
#   make release VERSION=0.2.0                # override version in constants.zig
#   make release FORCE=1                      # overwrite existing tag/release

release: clean build-all checksums
	@echo "==> Tagging v$(VERSION)..."
	git tag -f v$(VERSION)
	git push origin v$(VERSION) --force
ifdef FORCE
	@echo "==> Deleting existing release v$(VERSION) (FORCE=1)..."
	-gh release delete v$(VERSION) --yes --cleanup-tag 2>/dev/null || true
	@sleep 2
endif
	@echo "==> Creating GitHub release v$(VERSION)..."
	gh release create v$(VERSION) \
		--title "$(APP_NAME) v$(VERSION)" \
		--generate-notes \
		$(BUILD_DIR)/*.tar.gz \
		$(BUILD_DIR)/*.zip \
		$(BUILD_DIR)/checksums.txt
