SCAD = lens_wipe_box.scad
OPENSCAD ?= openscad

all: lens_wipe_box.stl lens_wipe_box_fit_test.stl preview.png lens_wipe_tower.stl lens_wipe_tower_lid.stl lens_wipe_tower_weight.stl lens_wipe_tower_weight_cover.stl lens_wipe_tower_fit_test.stl tower_preview.png

lens_wipe_box.stl: $(SCAD)
	$(OPENSCAD) --backend=manifold -D 'part="box"' -o $@ $<

# Short ring to check packet fit before printing the full box
lens_wipe_box_fit_test.stl: $(SCAD)
	$(OPENSCAD) --backend=manifold -D 'part="fit_test"' -D outer_length=31 -o $@ $<

preview.png: $(SCAD)
	$(OPENSCAD) --backend=manifold --render --camera=0,0,0,55,0,25,0 --viewall --autocenter --imgsize=900,800 -D 'part="box"' -o $@ $<

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

tower_preview.png: lens_wipe_tower.scad
	$(OPENSCAD) --backend=manifold --render -D 'part="assembly"' --camera=0,0,0,70,0,330,0 --viewall --autocenter --imgsize=800,900 -o $@ $<

clean:
	rm -f *.stl preview.png tower_preview.png

.PHONY: all clean
