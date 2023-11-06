DocProj=pdf-raku.github.io
DocRepo=https://github.com/pdf-raku/$(DocProj)
DocLinker=../$(DocProj)/etc/resolve-links.raku
TEST_JOBS ?= 6

all : doc

test :
	@prove6 -I . -j $(TEST_JOBS) t

loudtest :
	@prove6 -I . -v t

clean :
	@rm -f docs/Tags.md docs/Tags/*.md docs/Tags/*/*.md

$(DocLinker) :
	(cd .. && git clone $(DocRepo) $(DocProj))

docs/%.md : lib/%.rakumod
	@raku -I. -c $<
	raku -I . --doc=Markdown $< \
	|  TRAIL=$* raku -p -n $(DocLinker) \
        > $@

Pod-To-Markdown-installed :
	@raku -M Pod::To::Markdown -c

doc : $(DocLinker) Pod-To-Markdown-installed docs/index.md docs/PDF/Tags.md docs/PDF/Tags/Attr.md docs/PDF/Tags/Elem.md docs/PDF/Tags/Mark.md docs/PDF/Tags/ObjRef.md docs/PDF/Tags/Node.md docs/PDF/Tags/Node/Parent.md docs/PDF/Tags/Text.md docs/PDF/Tags/XML-Writer.md docs/PDF/Tags/XPath.md

docs/index.md : README.md
	cp $< $@


