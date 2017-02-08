.PHONY: all \
	highlight-pull highlight-build highlight-copy \
	reveal-pull reveal-build reveal-copy

all: highlight-copy reveal-copy unikernel

unikernel:
	cd src && mirage configure -t unix && make depend && make

clean:
	cd src && mirage clean

CP=rsync -avzrR

NODESH=docker run -ti -v $$(pwd -P):/cwd -v /usr/local/lib/node_modules \
  --entrypoint sh mor1/node

HIGHLIGHTV=9.9.0
HIGHLIGHTD=src/assets/highlight.js-$(HIGHLIGHTV)

highlight-pull:
	[ -r highlight.js ] || git clone https://github.com/isagalaev/highlight.js
	cd highlight.js && git co master && git pull

highlight-build:
	cd highlight.js \
	  && git co tags/$(HIGHLIGHTV) \
	  && $(NODESH) -c "npm install" \
	  && $(NODESH) -c "node tools/build.js -t cdn python c bash asm"

highlight-copy:
	rm -rf $(HIGHLIGHTD) && mkdir -p $(HIGHLIGHTD)
	$(CP) highlight.js/build/./highlight.min.js $(HIGHLIGHTD)
	$(CP) highlight.js/build/./styles/magula.min.css $(HIGHLIGHTD)
	$(CP) highlight.js/build/./styles/zenburn.min.css $(HIGHLIGHTD)

REVEALV=3.3.0
REVEALD=src/assets/reveal.js-$(REVEALV)
reveal-pull:
	[ -r reveal.js ] || git clone https://github.com/hakimel/reveal.js
	cd reveal.js && git co master && git pull

reveal-build:
	cd reveal.js \
	  && git co tags/$(REVEALV) \
	  && $(NODESH) -c "npm install && npm install -g grunt-cli && grunt"

reveal-copy:
	rm -rf $(REVEALD) && mkdir -p $(REVEALD)
	$(CP) reveal.js/./css/reveal.min.css $(REVEALD)
	$(CP) reveal.js/./css/theme/white.css $(REVEALD)
	$(CP) reveal.js/./js/reveal.min.js $(REVEALD)
	$(CP) reveal.js/./css/print $(REVEALD)
	$(CP) reveal.js/./lib $(REVEALD)
	$(CP) reveal.js/./plugin $(REVEALD)
