SCAD = lens_wipe_box.scad
OPENSCAD ?= openscad

all: images lens_wipe_box.stl lens_wipe_box_fit_test.stl lens_wipe_tower.stl lens_wipe_tower_lid.stl lens_wipe_tower_weight.stl lens_wipe_tower_weight_cover.stl lens_wipe_tower_fit_test.stl

lens_wipe_box.stl: $(SCAD)
	$(OPENSCAD) --backend=manifold -D 'part="box"' -o $@ $<

# Short ring to check packet fit before printing the full box
lens_wipe_box_fit_test.stl: $(SCAD)
	$(OPENSCAD) --backend=manifold -D 'part="fit_test"' -D outer_length=31 -o $@ $<


lens_wipe_tower.stl: lens_wipe_tower.scad
	$(OPENSCAD) --backend=manifold -D 'part="tower"' -o $@ $<

lens_wipe_tower_lid.stl: lens_wipe_tower.scad
	$(OPENSCAD) --backend=manifold -D 'part="lid"' -o $@ $<

# Weighted follower plate: fill with coins or washers
lens_wipe_tower_weight.stl: lens_wipe_tower.scad
	$(OPENSCAD) --backend=manifold -D 'part="weight"' -o $@ $<

lens_wipe_tower_weight_cover.stl: lens_wipe_tower.scad
	$(OPENSCAD) --backend=manifold -D 'part="weight_cover"' -o $@ $<

# Bottom 30 mm only: tests the ramp, slot and finger pocket
lens_wipe_tower_fit_test.stl: lens_wipe_tower.scad
	$(OPENSCAD) --backend=manifold -D 'part="fit_test"' -o $@ $<


# README images
images: img/tower.png img/box.png
IMG = $(OPENSCAD) --backend=manifold --colorscheme=Tomorrow --viewall --autocenter
img/tower.png: render.scad lens_wipe_tower.scad
	mkdir -p img
	$(IMG) -D 'view="tower"' --camera=0,0,0,70,0,40,0 --imgsize=800,900 -o $@ $<
img/box.png: render.scad lens_wipe_box.scad
	mkdir -p img
	$(IMG) -D 'view="box"' --camera=0,0,0,55,0,25,0 --imgsize=900,800 -o $@ $<

clean:
	rm -f *.stl

.PHONY: all images clean
