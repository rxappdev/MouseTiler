SCRIPT_NAME := mousetiler
PKGFILE := $(SCRIPT_NAME).kwinscript
SRC_DIR := src
SESSION_WIDTH := 1920
SESSION_HEIGHT := 1080
SESSION_OUTPUT_COUNT := 1
SESSION_VERBOSE := 0
SESSION_APPLICATIONS := # dolphin konsole kate

.NOTPARALLEL: all

.PHONY: all build install uninstall clean enable disable restart-kwin logs load unload reload remove-keybindings

all: install clean

build: $(PKGFILE)

$(PKGFILE): $(shell find $(SRC_DIR) -type f)
	@echo "Packaging $(SRC_DIR) into $(PKGFILE)..."
	@zip -rq $(PKGFILE) $(SRC_DIR)

install: build
	@echo "Installing $(PKGFILE)..."
	@kpackagetool6 --type=KWin/Script -i $(PKGFILE) || \
	kpackagetool6 --type=KWin/Script -u $(PKGFILE)

uninstall:
	@echo "Uninstalling $(SCRIPT_NAME)..."
	@kpackagetool6 --type=KWin/Script -r $(SCRIPT_NAME)

clean:
	@echo "Cleaning up $(PKGFILE)..."
	@rm -f $(PKGFILE)

enable:
	@echo "Enabling $(SCRIPT_NAME)..."
	@kwriteconfig6 --file kwinrc --group Plugins --key $(SCRIPT_NAME)Enabled true
	@qdbus org.kde.KWin /KWin reconfigure

disable:
	@echo "Disabling $(SCRIPT_NAME)..."
	@kwriteconfig6 --file kwinrc --group Plugins --key $(SCRIPT_NAME)Enabled false
	@qdbus org.kde.KWin /KWin reconfigure

restart-kwin:
	if [ "$$XDG_SESSION_TYPE" = "x11" ]; then \
		kwin_x11 --replace & \
	elif [ "$$XDG_SESSION_TYPE" = "wayland" ]; then \
		kwin_wayland --replace & \
	else \
		echo "Unknown session type"; \
	fi

logs:
	@if [ "${XDG_SESSION_TYPE}" = "x11" ]; then \
	    journalctl -f -t kwin_x11; \
	else \
	    journalctl --user -u plasma-kwin_wayland -f QT_CATEGORY=js QT_CATEGORY=qml QT_CATEGORY=kwin_scripting; \
	fi

load:
	bin/load.sh "$(SRC_DIR)" "$(SCRIPT_NAME)-test"

unload:
	bin/unload.sh "$(SCRIPT_NAME)-test"

reload: unload load

remove-keybindings:
	@echo "Removing all unused custom keybindings..."
	qdbus org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.cleanUp
