node_bin = ./node_modules/.bin

spsd = app/init.coffee
atom = $(wildcard src/*.coffee)
css = css/new.scss

spsd_out = public/application.js
atom_out = $(atom:%.coffee=%.js)
css_out = public/application.css

all: npm build-atom handlebars style build-app

build-atom: $(atom_out)

src/%.js: src/%.coffee
	@$(node_bin)/coffee -bc $<

build-app: $(spsd_out)

$(spsd_out): $(spsd)
	@$(node_bin)/browserify -t coffeeify $< > $@

handlebars:
	@$(node_bin)/handlebars app/views/note.handlebars -f app/views/note.js
	@$(node_bin)/handlebars app/views/notebook.handlebars -f app/views/notebook.js

style:
	@sass $(css) $(css_out)

npm:
	@npm install .

clean:
	@rm -f $(spsd_out) $(atom_out) $(css_out)
