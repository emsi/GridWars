BMK ?= bmk
ARCH ?= x64

.PHONY: all debug run test clean

# BMK handles incremental compilation of the game and its imported modules.
# -w preserves the original code's implicit numeric argument conversions.
all:
	"$(BMK)" makeapp -t gui -g "$(ARCH)" -r -w -o gridwars gridwars.bmx

debug:
	"$(BMK)" makeapp -t gui -g "$(ARCH)" -d -w -o gridwars.debug gridwars.bmx

run: all
	./gridwars

test:
	python3 tests/run.py "$(BMK)"

clean:
	rm -rf .bmx tests/.bmx
	rm -f gridwars gridwars.debug
