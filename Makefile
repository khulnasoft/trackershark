include .env
export

OS_NAME := $(shell uname -s)

# update Wireshark source tree and build
all: sync build

clean:
	@rm -rf wireshark/build
	@rm -f wireshark/CMakeListsCustom.txt
	@rm -rf wireshark/plugins/epan/tracker-event
	@rm -rf wireshark/plugins/epan/tracker-network-capture
	@rm -f wireshark/plugins/epan/common.h
	@rm -f wireshark/plugins/epan/wsjson_extensions.c
	@rm -rf wireshark/plugins/wiretap/tracker-json

# sync plugin source files into Wireshark source
sync:
	@rsync -a CMakeListsCustom.txt wireshark/
	@rsync -a plugins/ wireshark/plugins/

build: sync
	@if ! [ -d "wireshark/build" ]; then \
		echo "Build directory doesn't exist, run \"make cmake\" first"; \
		exit 1; \
	fi

	@ninja -C wireshark/build

# update private configuration profile
install:
	@mkdir -p ~/.config/wireshark
	@cp -r profiles ~/.config/wireshark
	
	@mkdir -p ~/.local/lib/wireshark/extcap
	@cp extcap/tracker-capture.py ~/.local/lib/wireshark/extcap
	@if [ "$(OS_NAME)" = "Darwin" ]; then \
		sed -i '' -e 's/VERSION_PLACEHOLDER/$(TRACKERSHARK_VERSION)/g' ~/.local/lib/wireshark/extcap/tracker-capture.py; \
		cp extcap/tracker-capture.sh ~/.local/lib/wireshark/extcap; \
		chmod +x ~/.local/lib/wireshark/extcap/tracker-capture.sh; \
	else \
		sed -i'' -e 's/VERSION_PLACEHOLDER/$(TRACKERSHARK_VERSION)/g' ~/.local/lib/wireshark/extcap/tracker-capture.py; \
		chmod +x ~/.local/lib/wireshark/extcap/tracker-capture.py; \
	fi
	@cp -r extcap/tracker-capture ~/.local/lib/wireshark/extcap
	@chmod +x ~/.local/lib/wireshark/extcap/tracker-capture/new-entrypoint.sh

	@mkdir -p ~/.config/wireshark/extcap
	@cp extcap/tracker-capture.py ~/.config/wireshark/extcap
	@if [ "$(OS_NAME)" = "Darwin" ]; then \
		sed -i '' -e 's/VERSION_PLACEHOLDER/$(TRACKERSHARK_VERSION)/g' ~/.config/wireshark/extcap/tracker-capture.py; \
		cp extcap/tracker-capture.sh ~/.config/wireshark/extcap; \
		chmod +x ~/.config/wireshark/extcap/tracker-capture.sh; \
	else \
		sed -i'' -e 's/VERSION_PLACEHOLDER/$(TRACKERSHARK_VERSION)/g' ~/.config/wireshark/extcap/tracker-capture.py; \
		chmod +x ~/.config/wireshark/extcap/tracker-capture.py; \
	fi
	@cp -r extcap/tracker-capture ~/.config/wireshark/extcap
	@chmod +x ~/.config/wireshark/extcap/tracker-capture/new-entrypoint.sh

	$(eval WS_VERSION_SHORT := $(shell if [ -x "wireshark/build/run/wireshark" ]; then wireshark/build/run/wireshark --version | grep -o -E "Wireshark [0-9]+\.[0-9]+\.[0-9]+" | grep -o -E "[0-9]+\.[0-9]+"; fi))
ifeq ($(OS_NAME),Darwin)
	$(eval WS_VERSION_DIR := $(subst .,-,$(WS_VERSION_SHORT)))
else
	$(eval WS_VERSION_DIR := $(WS_VERSION_SHORT))
endif

	@mkdir -p ~/.local/lib/wireshark/plugins/$(WS_VERSION_DIR)/epan
	@mkdir -p ~/.local/lib/wireshark/plugins/$(WS_VERSION_DIR)/wiretap
	
	@cp wireshark/build/run/tracker-event* ~/.local/lib/wireshark/plugins/$(WS_VERSION_DIR)/epan/tracker-event.so
	@cp wireshark/build/run/tracker-network-capture* ~/.local/lib/wireshark/plugins/$(WS_VERSION_DIR)/epan/tracker-network-capture.so
	@cp wireshark/build/run/tracker-json* ~/.local/lib/wireshark/plugins/$(WS_VERSION_DIR)/wiretap/tracker-json.so

# build and run
run: all install
	@wireshark/build/run/wireshark

# build and run with debug logging
debug: all install
	@wireshark/build/run/wireshark --log-level DEBUG

# prepare build directory (needed before building for the first time)
cmake: clean sync
	@rm -rf wireshark/build && mkdir wireshark/build
# Wireshark changed DISABLE_WERROR to ENABLE_WERROR at some point. Use both for compatibility (even though it causes a cmake warning to be thrown)
ifeq ($(WERROR),y)
	@cmake -G Ninja -DTRACKERSHARK_VERSION=$(TRACKERSHARK_VERSION) -DENABLE_CCACHE=No -DENABLE_WERROR=ON -DDISABLE_WERROR=OFF -S wireshark -B wireshark/build
else
	@cmake -G Ninja -DTRACKERSHARK_VERSION=$(TRACKERSHARK_VERSION) -DENABLE_CCACHE=No -DENABLE_WERROR=OFF -DDISABLE_WERROR=ON -S wireshark -B wireshark/build
endif

dist: all
	@rm -rf dist/workdir
	@mkdir dist/workdir
	@cp dist/install.sh dist/workdir

	@cp wireshark/build/run/tracker-event* dist/workdir/tracker-event.so
	@cp wireshark/build/run/tracker-network-capture* dist/workdir/tracker-network-capture.so
	@cp wireshark/build/run/tracker-json* dist/workdir/tracker-json.so

	@if [ "$(OS_NAME)" = "Darwin" ]; then \
		scripts/macos_rpathify.sh dist/workdir/tracker-json.so; \
		scripts/macos_rpathify.sh dist/workdir/tracker-event.so; \
		scripts/macos_rpathify.sh dist/workdir/tracker-network-capture.so; \
	fi
	
	@cp -r profiles dist/workdir
	@cp -r extcap dist/workdir

	@rm dist/workdir/extcap/tracker-capture.bat
	@if [ "$(OS_NAME)" = "Linux" ]; then \
		rm dist/workdir/extcap/tracker-capture.sh; \
	fi

	@if [ "$(OS_NAME)" = "Linux" ]; then \
		sed -i'' -e 's/VERSION_PLACEHOLDER/$(TRACKERSHARK_VERSION)/g' dist/workdir/extcap/tracker-capture.py; \
	else \
		sed -i '' -e 's/VERSION_PLACEHOLDER/$(TRACKERSHARK_VERSION)/g' dist/workdir/extcap/tracker-capture.py; \
	fi

	$(eval WS_VERSION := $(shell wireshark/build/run/wireshark --version | grep -o -E "Wireshark [0-9]+\.[0-9]+\.[0-9]+" | grep -o -E "[0-9]+\.[0-9]+\.[0-9]+"))
	@echo $(WS_VERSION) > dist/workdir/ws_version.txt
	
	@cd dist/workdir && zip -r ../trackershark-v$(TRACKERSHARK_VERSION)-$(shell echo "${OS_NAME}" | tr '[A-Z]' '[a-z]')-$(shell uname -m)-wireshark-$(WS_VERSION).zip .
