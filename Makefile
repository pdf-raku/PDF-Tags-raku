DocProj=pdf-raku.github.io
DocRepo=https://github.com/pdf-raku/$(DocProj)
DocLinker=../$(DocProj)/etc/resolve-links.raku

all : doc

test :
	@prove -e"raku -I ." t

loudtest :
	@prove -e"raku -I ." -v t

clean :
	@rm -f docs/Tags.md docs/Tags/*.md docs/Tags/*/*.md

$(DocLinker) :
	(cd .. && git clone $(DocRepo) $(DocProj))

docs/%.md : lib/%.rakumod
	raku -I . --doc=Markdown $< \
	|  TRAIL=$* raku -p -n $(DocLinker) \
        > $@

doc : $(DocLinker) docs/index.md docs/PDF/Tags.md docs/PDF/Tags/Attr.md docs/PDF/Tags/Elem.md docs/PDF/Tags/Mark.md docs/PDF/Tags/ObjRef.md docs/PDF/Tags/Node.md docs/PDF/Tags/Node/Parent.md docs/PDF/Tags/Text.md docs/PDF/Tags/XML-Writer.md docs/PDF/Tags/XPath.md

docs/index.md : README.md
	cp $< $@


