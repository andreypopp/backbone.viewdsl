all: index.html man.css

watch:
	watch -n1 $(MAKE) all

index.html:: man.css
	@git show master:README.md | RONN_STYLE=. ronn --html --pipe > $@

man.css: man.sass
	@sass --compass $< > $@

clean:
	rm -f man.css index.html

publish: all
	git push origin gh-pages
