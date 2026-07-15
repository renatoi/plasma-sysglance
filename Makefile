PKG = com.nerdstrike.sysglance
VERSION = $(shell python3 -c "import json; print(json.load(open('metadata.json'))['KPlugin']['Version'])")

.PHONY: install upgrade uninstall lint restart dist

# Build the installable/store-uploadable package archive
dist: lint
	rm -f $(PKG)-v$(VERSION).plasmoid
	zip -r $(PKG)-v$(VERSION).plasmoid metadata.json contents LICENSE -x '*~'

install:
	kpackagetool6 --type Plasma/Applet --install .

upgrade: lint
	kpackagetool6 --type Plasma/Applet --upgrade .
	systemctl --user restart plasma-plasmashell.service

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(PKG)

lint:
	qmllint contents/ui/*.qml contents/config/*.qml

restart:
	systemctl --user restart plasma-plasmashell.service
