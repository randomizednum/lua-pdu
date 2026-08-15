.PHONY: install

PREFIX?=/usr/local

install:
	mkdir -p $(PREFIX)/share/lua/5.1/pdu
	install -m 644 init.lua gsmalph.lua $(PREFIX)/share/lua/5.1/pdu
	install -m 755 pdu-convert.lua $(PREFIX)/bin/pdu-convert
