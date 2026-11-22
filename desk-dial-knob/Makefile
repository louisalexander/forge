# Desk dial knob + round-head housing: STLs (each on its print face), README pictures and the OpenSCAD checks.
SCAD = desk_dial_knob_housing.scad
OSC  = openscad --backend=manifold
PARTS = knob_floor knob_body mockup_knob_floor mockup_knob_body body accent_ring light_cup back_cap diffuser_ring cable_clip mockup
.PHONY: all images test
all:
	for p in $(PARTS); do \
	  $(OSC) --export-format=binstl -o desk_dial_kh_$$p.stl -D "part=\"$${p}_print\"" $(SCAD) || exit 1; \
	done
images:
	mkdir -p img
	$(OSC) --autocenter --viewall --imgsize=900,700 --camera=0,0,0,65,0,40,0 --colorscheme=Tomorrow -o img/assembly.png render.scad
	$(OSC) --autocenter --viewall --imgsize=900,700 --camera=0,0,0,60,0,220,0 --colorscheme=Tomorrow -o img/back.png render.scad
test:
	python3 -m pytest tests -q
