SCAD = freezer_bin.scad
OPENSCAD ?= openscad
SC = $(OPENSCAD) --backend=manifold

all: images freezer_bin.stl tests print

freezer_bin.stl: $(SCAD)
	$(SC) -D 'part="bin"' -o $@ $<

# Fit tests: the back-right corner of the rim and of the floor, each in its printed orientation.
# Print one of each and check that the top piece's flange takes the bottom piece without slop.
tests: freezer_bin_stack_test_top.stl freezer_bin_stack_test_bottom.stl freezer_bin_cold_test.stl

freezer_bin_stack_test_top.stl: $(SCAD)
	$(SC) -D 'part="stack_test_top"' -o $@ $<

freezer_bin_stack_test_bottom.stl: $(SCAD)
	$(SC) -D 'part="stack_test_bottom"' -o $@ $<

# Cold test: a small bin with every feature at full size. Print two, load them, freeze them,
# then try the stack, the rail and the walls cold. See README.
freezer_bin_cold_test.stl: $(SCAD)
	$(SC) -D cold_test=true -D 'part="bin"' -o $@ $<

# A bin and the bin stacked on it must not share any volume: "Current top level object is empty."
check: $(SCAD)
	@mkdir -p .build
	@rm -f .build/stack_check.stl
	@$(SC) -D 'part="stack_check"' -o .build/stack_check.stl $(SCAD) 2>&1 | \
		grep -E 'top level object is empty|Top level object is a' || true
	@test ! -s .build/stack_check.stl && echo "check: PASS (no interference)" || \
		(echo "check: FAIL -- see .build/stack_check.stl"; exit 1)

# Bambu Studio print files: the bin, and the two cold-test bins, with the P2S / SUNLU PETG 2.0
# settings from print_profile.py. Bambu Studio's CLI merges the profiles into project settings
# first (it segfaults on a 3MF that has none, hence the seed).
BAMBU ?= /Applications/BambuStudio.app/Contents/MacOS/BambuStudio

.build/print/project_settings.config: print_profile.py freezer_bin_stack_test_top.stl
	python3 print_profile.py .build/print
	$(BAMBU) --slice 0 --outputdir $(CURDIR)/.build/print/seed \
		--load-settings ".build/print/machine.json;.build/print/process.json" \
		--load-filaments ".build/print/filament.json" \
		--export-3mf seed.3mf freezer_bin_stack_test_top.stl > .build/print/seed.log 2>&1
	python3 print_profile.py --project .build/print/seed/seed.3mf $@

print: freezer_bin_print.3mf freezer_bin_cold_test_print.3mf

freezer_bin_print.3mf: freezer_bin.stl .build/print/project_settings.config pack_plate.py
	python3 pack_plate.py $@ --machine .build/print/machine.json \
		--settings .build/print/project_settings.config freezer_bin.stl

freezer_bin_cold_test_print.3mf: freezer_bin_cold_test.stl .build/print/project_settings.config pack_plate.py
	python3 pack_plate.py $@ --machine .build/print/machine.json \
		--settings .build/print/project_settings.config \
		freezer_bin_cold_test.stl freezer_bin_cold_test.stl

# README images
images: img/bin.png img/stack.png img/joint.png img/cold_test.png
IMG = $(SC) --render --colorscheme=Tomorrow --viewall --autocenter

img/bin.png: render.scad $(SCAD)
	@mkdir -p img
	$(IMG) -D 'view="bin"' --camera=0,0,0,64,0,28,0 --imgsize=900,800 -o $@ $<

img/stack.png: render.scad $(SCAD)
	@mkdir -p img
	$(IMG) -D 'view="stack"' --camera=0,0,0,72,0,28,0 --imgsize=760,1000 -o $@ $<

img/joint.png: render.scad $(SCAD)
	@mkdir -p img
	$(IMG) --projection=o -D 'view="joint"' --camera=0,0,0,90,0,0,0 --imgsize=620,780 -o $@ $<

img/cold_test.png: render.scad $(SCAD)
	@mkdir -p img
	$(IMG) -D cold_test=true -D 'view="bin"' --camera=0,0,0,64,0,28,0 --imgsize=760,660 -o $@ $<

clean:
	rm -f *.stl *.3mf
	rm -rf .build

.PHONY: all tests check images print clean
