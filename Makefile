node_bin = ./node_modules/.bin

spsd = $(wildcard app/*.coffee app/controllers/*.coffee app/lib/*.coffee app/models/*.coffee)
atom = $(wildcard src/*.coffee)
css = css/new.scss

spsd_out = public/application.js
atom_out = $(atom:%.coffee=%.js)
css_out = public/application.css

build-atom: $(atom_out)

src/%.js: src/%.coffee
	@$(node_bin)/coffee -bc $< > $@

build-app: $(spsd_out)

$(spsd_out): $(spsd)
	$(node_bin)/coffee -bcp $< > $@

style:
	@sass $(css) $(css_out)

npm:
	@npm install .

clean:
	@rm -f $(spsd_out) $(atom_out)

default: npm build-atom build-app style
