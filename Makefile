SRC=src

all : doc

test :
	@prove -e"perl6 -I ." t

loudtest :
	@prove -e"perl6 -I ." -v t

clean :
	@rm -f Makefile doc/Tags/*.md doc/Tags/*/*.md

doc : doc/Tags.md doc/Tags/Elem.md doc/Tags/Mark.md doc/Tags/ObjRef.md doc/Tags/Node.md doc/Tags/Node/Parent.md doc/Tags/Text.md doc/Tags/XML-Writer.md doc/Tags/XPath.md

doc/Tags.md : lib/PDF/Tags.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags.rakumod > doc/Tags.md

doc/Tags/Elem.md : lib/PDF/Tags/Elem.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Elem.rakumod > doc/Tags/Elem.md

doc/Tags/Mark.md : lib/PDF/Tags/Mark.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Mark.rakumod > doc/Tags/Mark.md

doc/Tags/ObjRef.md : lib/PDF/Tags/ObjRef.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/ObjRef.rakumod > doc/Tags/ObjRef.md

doc/Tags/Node.md : lib/PDF/Tags/Node.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Node.rakumod > doc/Tags/Node.md

doc/Tags/Node/Parent.md : lib/PDF/Tags/Node/Parent.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Node/Parent.rakumod > doc/Tags/Node/Parent.md

doc/Tags/Text.md : lib/PDF/Tags/Text.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/Text.rakumod > doc/Tags/Text.md

doc/Tags/XML-Writer.md : lib/PDF/Tags/XML-Writer.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/XML-Writer.rakumod > doc/Tags/XML-Writer.md

doc/Tags/XPath.md : lib/PDF/Tags/XPath.rakumod
	rakudo -I . --doc=Markdown lib/PDF/Tags/XPath.rakumod > doc/Tags/XPath.md


