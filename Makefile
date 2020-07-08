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

docs/index.md : lib/PDF/Tags.rakumod
	rakudo -I . --doc=Markdown $< \
	| raku -p -n $(DocLinker) \
         > $@

docs/%.md : lib/PDF/Tags/%.rakumod
	raku -I . --doc=Markdown $< \
	| raku -p -n $(DocLinker) \
        > $@

doc : $(DocLinker) docs/index.md docs/Attr.md docs/Elem.md docs/Mark.md docs/ObjRef.md docs/Node.md docs/Node/Parent.md docs/Text.md docs/XML-Writer.md docs/XPath.md

docs/Attr.md : lib/PDF/Tags/Attr.rakumod

docs/Elem.md : lib/PDF/Tags/Elem.rakumod

docs/Mark.md : lib/PDF/Tags/Mark.rakumod

docs/ObjRef.md : lib/PDF/Tags/ObjRef.rakumod

docs/Node.md : lib/PDF/Tags/Node.rakumod

docs/Node/Parent.md : lib/PDF/Tags/Node/Parent.rakumod

docs/Text.md : lib/PDF/Tags/Text.rakumod

docs/XML-Writer.md : lib/PDF/Tags/XML-Writer.rakumod

docs/XPath.md : lib/PDF/Tags/XPath.rakumod


