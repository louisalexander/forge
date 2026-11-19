OPENSCAD ?= openscad
O = $(OPENSCAD) --backend=manifold
BAMBU ?= /Applications/BambuStudio.app/Contents/MacOS/BambuStudio

# Trimming-kit case, v5 (trim_case.scad). `make` builds the print file and the halves.
all: trim_case_print.3mf trim_case_body_2color.3mf trim_case_lid_2color.3mf
images: img/closed.png img/open.png img/stand.png
tests: trim_case_keyhole_test.3mf trim_case_clip_test_0.3.stl trim_case_hinge_test_body.stl trim_case_hinge_test_lid.stl

# Clip test with a given squeeze (mm per side), labelled on its back
trim_case_clip_test_%.stl: trim_case.scad
	$(O) --export-format binstl -D 'part="clip_test"' -D 'clip_sq=$*' -D 'test_label="$*"' -o $@ $<

trim_case_%.stl: trim_case.scad
	$(O) --export-format binstl -D 'part="$*"' -o $@ $<

# Colour inlays: lid = grip ticks + handle silhouette, body = logo (needs ref/bambu-lab.svg)
.build/v5_lid_inlays.stl .build/v5_lid_inlays_inset.stl .build/v5_body_inlays.stl .build/v5_body_inlays_inset.stl: trim_case.scad
	mkdir -p .build
	$(O) --export-format binstl -D 'part="inlays"' -o .build/v5_lid_inlays.stl $<
	$(O) --export-format binstl -D 'part="inlays"' -D 'inlay_inset=0.02' -o .build/v5_lid_inlays_inset.stl $<
	$(O) --export-format binstl -D 'part="body_inlays"' -o .build/v5_body_inlays.stl $<
	$(O) --export-format binstl -D 'part="body_inlays"' -D 'inlay_inset=0.02' -o .build/v5_body_inlays_inset.stl $<

# Each half with its inlays as one two-part object (half = filament 1, inlays = filament 2)
trim_case_%_2color.3mf trim_case_%_combined.stl: trim_case_%.stl .build/v5_%_inlays.stl .build/v5_%_inlays_inset.stl pack_2color.py
	python3 pack_2color.py trim_case_$* trim_case_$*.stl .build/v5_$*_inlays.stl .build/v5_$*_inlays_inset.stl .

# Print file: body and lid (each with its inlays) on one plate, with the P2S / PETG Matte settings
# from print_profile.py. Bambu Studio's CLI merges the profiles into project settings first.
.build/print/project_settings.config: print_profile.py trim_case_clip_test_0.3.stl
	python3 print_profile.py .build/print
	$(BAMBU) --slice 0 --outputdir $(CURDIR)/.build/print/seed --load-settings ".build/print/machine.json;.build/print/process.json" --load-filaments ".build/print/filament.json;.build/print/filament.json" --export-3mf seed.3mf trim_case_clip_test_0.3.stl > .build/print/seed.log 2>&1
	python3 print_profile.py --project .build/print/seed/seed.3mf $@

trim_case_print.3mf: trim_case_body.stl trim_case_lid.stl .build/v5_body_inlays.stl .build/v5_lid_inlays.stl .build/print/project_settings.config pack_plate.py pack_2color.py
	python3 pack_plate.py --stack --settings .build/print/project_settings.config $@ "trim_case_body=trim_case_body.stl@1,.build/v5_body_inlays.stl@2" "trim_case_lid=trim_case_lid.stl@1,.build/v5_lid_inlays.stl@2"

# Fit test: the chosen seats (2.9 slit, Ø3.12 keyhole; rows labelled 2.9 K / 3.0 K)
trim_case_keyhole_test.3mf: trim_case_keyhole_test.stl pack_plate.py pack_2color.py
	python3 pack_plate.py $@ "keyhole_test=trim_case_keyhole_test.stl@1"

# README images (render.scad: two-colour look, blades and handle in place)
IMG = $(O) --colorscheme=Tomorrow --viewall --autocenter
img/closed.png: render.scad trim_case.scad
	mkdir -p img
	$(IMG) -D 'view="closed"' --camera=0,0,0,60,0,35,0 --imgsize=1200,800 -o $@ $<
img/open.png: render.scad trim_case.scad
	mkdir -p img
	$(IMG) -D 'view="open"' --camera=0,0,0,40,0,20,0 --imgsize=1200,1000 -o $@ $<
img/stand.png: render.scad trim_case.scad
	mkdir -p img
	$(IMG) -D 'view="stand"' --camera=0,0,0,70,0,330,0 --imgsize=1200,900 -o $@ $<

# Closed halves must overlap only on the parting seam (z = 17)
check: trim_case.scad
	mkdir -p .build
	$(O) -D 'part="closed_check"' -o .build/closed_check.stl $<

clean:
	rm -rf .build trim_case_*_combined.stl

.PRECIOUS: trim_case_%.stl
.PHONY: all images tests check clean
