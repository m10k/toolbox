PHONY = install uninstall

ifeq ($(PREFIX), )
	PREFIX = /usr/local
endif

all:

clean:

install:
	mkdir -p $(DESTDIR)/$(PREFIX)/share/toolbox
	mkdir -p $(DESTDIR)/$(PREFIX)/bin
	cp toolbox.sh $(DESTDIR)/$(PREFIX)/share/toolbox/.
	cp -r include $(DESTDIR)/$(PREFIX)/share/toolbox/.
	chown -R root.root $(DESTDIR)/$(PREFIX)/share/toolbox
	find $(DESTDIR)/$(PREFIX)/share/toolbox -type d -exec chmod 755 {} \;
	find $(DESTDIR)/$(PREFIX)/share/toolbox -type f -exec chmod 644 {} \;
	chmod -R 755 $(DESTDIR)/$(PREFIX)/share/toolbox
	ln -sf $(DESTDIR)/$(PREFIX)/share/toolbox/toolbox.sh $(DESTDIR)/$(PREFIX)/bin/toolbox.sh

uninstall:
	rm $(DESTDIR)/$(PREFIX)/bin/toolbox.sh
	rm -rf $(DESTDIR)/$(PREFIX)/share/toolbox

.PHONY: $(PHONY)
