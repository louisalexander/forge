# Desk dial pod: STLs, README pictures and the OpenSCAD checks.
SCAD = desk_dial_pod.scad
OSC  = openscad --backend=manifold
.PHONY: all images test
all:
	for p in pod cap bracket coupon fittings_coupon; do \
	  $(OSC) -o desk_dial_$$p.stl -D "part=\"$$p\"" $(SCAD) || exit 1; \
	done
	# the two-piece pod, each turned onto its print face; the round piece also as body + accent ring (two colours)
	for p in pod_round pod_root pod_round_body pod_accent; do \
	  $(OSC) -o desk_dial_$$p.stl -D "part=\"$${p}_print\"" $(SCAD) || exit 1; \
	done
images:
	mkdir -p img
	$(OSC) --autocenter --viewall --imgsize=900,700 --camera=0,0,0,180,0,0,0 --colorscheme=Tomorrow -D 'view="round"' -o img/round.png render.scad
	$(OSC) --autocenter --viewall --imgsize=900,700 --camera=0,0,0,60,0,215,0 --colorscheme=Tomorrow -o img/pod_back.png render.scad
test:
	python3 -m pytest tests -q
