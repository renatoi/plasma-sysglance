PKG = com.renato.sysglance

.PHONY: install upgrade uninstall lint restart

install:
	kpackagetool6 --type Plasma/Applet --install .

upgrade: lint
	kpackagetool6 --type Plasma/Applet --upgrade .
	systemctl --user restart plasma-plasmashell.service

uninstall:
	kpackagetool6 --type Plasma/Applet --remove $(PKG)

lint:
	qmllint --bare contents/ui/*.qml contents/config/*.qml || true

restart:
	systemctl --user restart plasma-plasmashell.service
