# Desk dial pod: STLs, README pictures and the OpenSCAD checks.
SCAD = desk_dial_pod.scad
OSC  = openscad --backend=manifold
.PHONY: all images test print
# The cap's supports, made easy to remove (owner, 2026-11-21): organic tree, tips 0.6, 0.6 mm off the part's
# sides, a sparser interface. Every other object keeps the project's supports (print_settings.config); the
# bracket has none.
CAP_SUPPORTS = enable_support=1;support_type=tree(auto);support_style=tree_organic;tree_support_tip_diameter=0.6;support_object_xy_distance=0.6;support_interface_spacing=0.8;support_top_z_distance=0.3
all:
	for p in pod cap bracket coupon fittings_coupon; do \
	  $(OSC) --export-format=binstl -o desk_dial_$$p.stl -D "part=\"$$p\"" $(SCAD) || exit 1; \
	done
	# the two-piece pod, each turned onto its print face; the round piece also as body + accent ring (two colours)
	for p in pod_round pod_root pod_round_body pod_accent; do \
	  $(OSC) --export-format=binstl -o desk_dial_$$p.stl -D "part=\"$${p}_print\"" $(SCAD) || exit 1; \
	done
images:
	mkdir -p img
	$(OSC) --autocenter --viewall --imgsize=900,700 --camera=0,0,0,180,0,0,0 --colorscheme=Tomorrow -D 'view="round"' -o img/round.png render.scad
	$(OSC) --autocenter --viewall --imgsize=900,700 --camera=0,0,0,60,0,215,0 --colorscheme=Tomorrow -o img/pod_back.png render.scad
test:
	python3 -m pytest tests -q

# The print file: one plate, the owner's P2S profile (print_settings.config) embedded. The round piece is one
# object of two parts (body filament 1, accent ring filament 3).
print: all
	python3 pack_plate.py --settings print_settings.config desk_dial_pod.3mf \
	  "Round=desk_dial_pod_round_body.stl@1,desk_dial_pod_accent.stl@3" \
	  "Root=desk_dial_pod_root.stl@1" \
	  "Bracket=desk_dial_bracket.stl@1;enable_support=0" \
	  "Cap=desk_dial_cap.stl@1;$(CAP_SUPPORTS)"
