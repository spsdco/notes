BIN = ./node_modules/.bin
SRC = $(wildcard src/*.coffee)
OUT = $(SRC:src/%.coffee=js/%.js)

build: $(OUT)

js/%.js: src/%.coffee
	@mkdir -p $(@D)
	@$(BIN)/coffee -bcp $< > $@

npm:
	@npm install .

clean:
	@rm -f $(OUT)

default: npm build
