all: index.html app.css

index.html::
	@cat head.html > $@
	@git show master:README.md | redcarpet --smarty >> $@
	@cat footer.html >> $@

app.css: app.sass
	@sass --compass $< > $@

clean:
	rm -f app.css index.html

publish: all
	git push origin gh-pages
