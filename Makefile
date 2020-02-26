SRC=src

all : doc

test : all
	@prove -e"perl6 -I ." t

loudtest : all
	@prove -e"perl6 -I ." -v t

clean :
	@rm -f Makefile doc/*.md doc/*/*.md

doc : doc/Tags.md doc/Tags/Elem.md doc/Tags/Mark.md doc/Tags/ObjRef.md doc/Tags/Root.md doc/Tags/Text.md doc/Tags/XML.md doc/Tags/XPath.md

doc/Tags.md : lib/PDF/Tags.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags.rakumod > doc/Tags.md

doc/Tags/Elem.md : lib/PDF/Tags/Elem.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Elem.rakumod > doc/Tags/Elem.md

doc/Tags/Mark.md : lib/PDF/Tags/Mark.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Mark.rakumod > doc/Tags/Mark.md

doc/Tags/ObjRef.md : lib/PDF/Tags/ObjRef.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/ObjRef.rakumod > doc/Tags/ObjRef.md

doc/Tags/Root.md : lib/PDF/Tags/Root.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Root.rakumod > doc/Tags/Root.md

doc/Tags/Text.md : lib/PDF/Tags/Text.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Text.rakumod > doc/Tags/Text.md

doc/Tags/XML.md : lib/PDF/Tags/XML.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/XML.rakumod > doc/Tags/XML.md

doc/Tags/XPath.md : lib/PDF/Tags/XPath.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/XPath.rakumod > doc/Tags/XPath.md


