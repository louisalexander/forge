# Desk accent case: STLs for both variants (stacked is the current pick) and the README pictures.
OSC = openscad --backend=manifold
.PHONY: all images
all:
	for p in body carrier lid window; do \
	  $(OSC) -o desk_accent_stacked_$$p.stl -D "PART=\"$$p\"" desk_accent_case_stacked.scad || exit 1; \
	done
	for p in body lid window; do \
	  $(OSC) -o desk_accent_$$p.stl -D "PART=\"$$p\"" desk_accent_case.scad || exit 1; \
	done
images:
	mkdir -p img
	$(OSC) --autocenter --viewall --imgsize=900,600 --camera=0,0,0,60,0,30,0 --colorscheme=Tomorrow -o img/stacked.png render.scad
