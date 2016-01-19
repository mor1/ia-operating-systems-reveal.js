.PHONY: all \
	highlight-clone highlight-build highlight-copy \
	reveal-clone reveal-build reveal-copy

all: highlight-copy reveal-copy

CP=rsync -avzrR

HIGHLIGHTV=9.1.0
HIGHLIGHTD=src/assets/highlight.js-$(HIGHLIGHTV)

highlight-clone:
	git clone https://github.com/isagalaev/highlight.js

highlight-build:
	cd highlight.js \
	  && git co $(HIGHLIGHTV) \
	  && node tools/build.js -t cdn python c bash

highlight-copy: highlight-build
	rm -rf $(HIGHLIGHTD) && mkdir -p $(HIGHLIGHTD)
	$(CP) highlight.js/build/./highlight.min.js $(HIGHLIGHTD)
	$(CP) highlight.js/build/./styles/magula.min.css $(HIGHLIGHTD)
	$(CP) highlight.js/build/./styles/zenburn.min.css $(HIGHLIGHTD)

REVEALV=3.2.0
REVEALD=src/assets/reveal.js-$(REVEALV)
reveal-clone:
	git clone https://github.com/hakimel/reveal.js

reveal-build:
	cd reveal.js \
	  && git co 3.2.0 \
	  && npm install && grunt

reveal-copy: reveal-build
	rm -rf $(REVEALD) && mkdir -p $(REVEALD)
	$(CP) reveal.js/./css/reveal.min.css $(REVEALD)
	$(CP) reveal.js/./css/theme/black.css $(REVEALD)
	$(CP) reveal.js/./js/reveal.min.js $(REVEALD)
	$(CP) reveal.js/./css/print $(REVEALD)
	$(CP) reveal.js/./lib $(REVEALD)
	$(CP) reveal.js/./plugin $(REVEALD)
