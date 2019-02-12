.PHONY: all
all: highlight-copy reveal-copy unikernel

.PHONY: run
run: configure unikernel
	./src/main.native

FLAGS ?= -vv --net socket -t unix --port 8080 --kv_ro direct
.PHONY: configure
configure:
	cd src && mirage configure $(FLAGS)
.PHONY: unikernel
unikernel:
	cd src && make depend && make

.PHONY: clean
clean:
	cd src && mirage clean

CP=rsync -avzrR

NODESH=docker run -ti -v $$(pwd -P):/cwd -v /usr/local/lib/node_modules \
  --entrypoint sh mor1/node

HIGHLIGHTV=9.9.0
HIGHLIGHTD=src/assets/highlight.js-$(HIGHLIGHTV)

.PHONY: highlight-pull
highlight-pull:
	[ -r highlight.js ] || git clone https://github.com/isagalaev/highlight.js
	cd highlight.js && git co master && git pull

.PHONY: highlight-build
highlight-build:
	cd highlight.js \
	  && git co tags/$(HIGHLIGHTV) \
	  && $(NODESH) -c "npm install" \
	  && $(NODESH) -c "node tools/build.js -t cdn python c bash asm"

.PHONY: highlight-copy
highlight-copy:
	rm -rf $(HIGHLIGHTD) && mkdir -p $(HIGHLIGHTD)
	$(CP) highlight.js/build/./highlight.min.js $(HIGHLIGHTD)
	$(CP) highlight.js/build/./styles/magula.min.css $(HIGHLIGHTD)
	$(CP) highlight.js/build/./styles/zenburn.min.css $(HIGHLIGHTD)

REVEALV=3.3.0
REVEALD=src/assets/reveal.js-$(REVEALV)
.PHONY: reveal-pull
reveal-pull:
	[ -r reveal.js ] || git clone https://github.com/hakimel/reveal.js
	cd reveal.js && git co master && git pull

.PHONY: reveal-build
reveal-build:
	cd reveal.js \
	  && git co tags/$(REVEALV) \
	  && $(NODESH) -c "npm install && npm install -g grunt-cli && grunt"

.PHONY: reveal-copy
reveal-copy:
	rm -rf $(REVEALD) && mkdir -p $(REVEALD)
	$(CP) reveal.js/./css/reveal.min.css $(REVEALD)
	$(CP) reveal.js/./css/theme/white.css $(REVEALD)
	$(CP) reveal.js/./js/reveal.min.js $(REVEALD)
	$(CP) reveal.js/./css/print $(REVEALD)
	$(CP) reveal.js/./lib $(REVEALD)
	$(CP) reveal.js/./plugin $(REVEALD)
