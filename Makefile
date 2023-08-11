PHONY = install uninstall test

ifeq ($(PREFIX), )
	PREFIX = /usr
endif

all:

clean:

# test:
# 	./test.sh

install:
	mkdir -p $(DESTDIR)/$(PREFIX)/share/toolbox
	mkdir -p $(DESTDIR)/$(PREFIX)/bin
	mkdir -p $(DESTDIR)/var/lib/toolbox/ipc/pub
	mkdir -p $(DESTDIR)/var/lib/toolbox/ipc/priv
	mkdir -p $(DESTDIR)/var/lib/toolbox/ipc/pubsub
	mkdir -p $(DESTDIR)/var/lib/toolbox/uipc/pub
	mkdir -p $(DESTDIR)/var/lib/toolbox/uipc/priv
	mkdir -p $(DESTDIR)/var/lib/toolbox/uipc/pubsub
	chmod -R g+rwxs $(DESTDIR)/var/lib/toolbox/ipc
	chmod -R g+rwxs $(DESTDIR)/var/lib/toolbox/uipc
	cp toolbox.sh $(DESTDIR)/$(PREFIX)/share/toolbox/.
	cp -r include $(DESTDIR)/$(PREFIX)/share/toolbox/.
	cp -r utils   $(DESTDIR)/$(PREFIX)/share/toolbox/.
	cp -r spec    $(DESTDIR)/$(PREFIX)/share/toolbox/.
	chown -R root:root $(DESTDIR)/$(PREFIX)/share/toolbox
	find $(DESTDIR)/$(PREFIX)/share/toolbox -type d -exec chmod 755 {} \;
	find $(DESTDIR)/$(PREFIX)/share/toolbox -type f -exec chmod 644 {} \;
	chmod -R 755 $(DESTDIR)/$(PREFIX)/share/toolbox
	ln -sf $(PREFIX)/share/toolbox/toolbox.sh $(DESTDIR)/$(PREFIX)/bin/toolbox.sh
	ln -sf $(PREFIX)/share/toolbox/spec/validate.py $(DESTDIR)/$(PREFIX)/bin/toolbox-json-validate
	ln -sf $(PREFIX)/share/toolbox/utils/ipc-tap.sh $(DESTDIR)/$(PREFIX)/bin/ipc-tap
	ln -sf $(PREFIX)/share/toolbox/utils/ipc-inject.sh $(DESTDIR)/$(PREFIX)/bin/ipc-inject
	ln -sf $(PREFIX)/share/toolbox/utils/ipc-sshtunnel.sh $(DESTDIR)/$(PREFIX)/bin/ipc-sshtunnel

uninstall:
	rm $(DESTDIR)/$(PREFIX)/bin/toolbox.sh
	rm $(DESTDIR)/$(PREFIX)/bin/ipc-tap
	rm $(DESTDIR)/$(PREFIX)/bin/ipc-inject
	rm $(DESTDIR)/$(PREFIX)/bin/ipc-sshtunnel
	rm -rf $(DESTDIR)/$(PREFIX)/share/toolbox

.PHONY: $(PHONY)
