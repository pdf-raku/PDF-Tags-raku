SRC=src

all : doc

test :
	@prove -e"raku -I ." t

loudtest :
	@prove -e"raku -I ." -v t

clean :
	@rm -f docs/Tags.md docs/Tags/*.md docs/Tags/*/*.md

doc : docs/Tags.md docs/Tags/Attr.md docs/Tags/Elem.md docs/Tags/Mark.md docs/Tags/ObjRef.md docs/Tags/Node.md docs/Tags/Node/Parent.md docs/Tags/Text.md docs/Tags/XML-Writer.md docs/Tags/XPath.md

docs/Tags%.md : lib/PDF/Tags%.rakumod
	raku -I . --doc=Markdown $< \
	| raku -p -n etc/resolve-links.raku \
        > $@

docs/Tags.md : lib/PDF/Tags.rakumod
	rakudo -I . --doc=Markdown $< \
	| raku -p -n etc/resolve-links.raku \
         > $@

docs/Tags/Attr.md : lib/PDF/Tags/Attr.rakumod

docs/Tags/Elem.md : lib/PDF/Tags/Elem.rakumod

docs/Tags/Mark.md : lib/PDF/Tags/Mark.rakumod

docs/Tags/ObjRef.md : lib/PDF/Tags/ObjRef.rakumod

docs/Tags/Node.md : lib/PDF/Tags/Node.rakumod

docs/Tags/Node/Parent.md : lib/PDF/Tags/Node/Parent.rakumod

docs/Tags/Text.md : lib/PDF/Tags/Text.rakumod

docs/Tags/XML-Writer.md : lib/PDF/Tags/XML-Writer.rakumod

docs/Tags/XPath.md : lib/PDF/Tags/XPath.rakumod


