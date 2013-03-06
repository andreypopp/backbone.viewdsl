all: index.html app.css

watch:
	watch -n0.3 $(MAKE) all

index.html: ../README.md
	@cat head.html > $@
	@redcarpet --smarty ../README.md >> $@
	@cat footer.html >> $@

app.css: app.sass
	@sass --compass $< > $@

clean:
	rm -f app.css index.html
