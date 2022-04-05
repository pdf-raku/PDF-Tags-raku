DocProj=pdf-raku.github.io
DocRepo=https://github.com/pdf-raku/$(DocProj)
DocLinker=../$(DocProj)/etc/resolve-links.raku
TaggedPDFDtD=resources/tagged-pdf.dtd

all : doc dtd

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

dtd : $(TaggedPDFDtD)

$(TaggedPDFDtD) : etc/make-tagged-pdf-dtd.raku $(wildcard src/*.csv)
	raku etc/make-tagged-pdf-dtd.raku > $@

doc : $(DocLinker) docs/index.md docs/PDF/Tags.md docs/PDF/Tags/Attr.md docs/PDF/Tags/Elem.md docs/PDF/Tags/Mark.md docs/PDF/Tags/ObjRef.md docs/PDF/Tags/Node.md docs/PDF/Tags/Node/Parent.md docs/PDF/Tags/Text.md docs/PDF/Tags/XML-Writer.md docs/PDF/Tags/XPath.md

docs/index.md : README.md
	cp $< $@

docs/PDF/Tags.md : lib/PDF/Tags.rakumod

docs/PDF/Tags/Attr.md : lib/PDF/Tags/Attr.rakumod

docs/PDF/Tags/Elem.md : lib/PDF/Tags/Elem.rakumod

docs/PDF/Tags/Mark.md : lib/PDF/Tags/Mark.rakumod

docs/PDF/Tags/ObjRef.md : lib/PDF/Tags/ObjRef.rakumod

docs/PDF/Tags/Node.md : lib/PDF/Tags/Node.rakumod

docs/PDF/Tags/Node/Parent.md : lib/PDF/Tags/Node/Parent.rakumod

docs/PDF/Tags/Text.md : lib/PDF/Tags/Text.rakumod

docs/PDF/Tags/XML-Writer.md : lib/PDF/Tags/XML-Writer.rakumod

docs/PDF/Tags/XPath.md : lib/PDF/Tags/XPath.rakumod


