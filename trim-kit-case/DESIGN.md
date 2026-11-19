# Trimming-kit case (v5): design

A hinged case for the Bambu trimming tool kit. It holds 10 snap-in blades and the handle, closes with a magnet latch and has two-colour inlays.
`trim_case.scad` is the whole design, and `make` builds `trim_case_print.3mf`, the file to print.
The design brief is in `docs/2026-11-18-roomy-rebuild-design.md`.

**Logo:** the body's logo inlay reads `ref/bambu-lab.svg`, which is not in the repo. See `ref/README.md`.
**History:** this rebuild replaced the earlier v4 case (`deburr_case.scad`), a remix of another designer's model. v4 is not in this repo.

## v5: roomy rebuild (`trim_case.scad`)

v5 is the same case, rebuilt from primitives with no imported meshes, bigger and roomier.
Design: `docs/2026-11-18-roomy-rebuild-design.md`. v4 (`deburr_case.scad`) is unchanged.

- **Size:** closed 168 × 84 × 28 (86 across the hinge bosses; v4 153 × 62 × 22). Walls 3, floor and back 2.5. Hinge bosses stand 1 mm proud, so the arm has 2 mm under each screw head, as in v4.
- **Blades:**
  - 9 mm apart across (v4 5.5).
  - The columns are 21 mm apart along the case (v4 15.3) and 12 mm apart vertically (v4 9.5).
  - Riser seats grip 14.5 mm of shank. Proven fits are kept: bore 3.25, mouth 2.45 (riser 2.35).
- **Handle:**
  - Bore Ø21.5 (v4 19.2). Finger scoop in the lid floor just past the tip.
  - One clip, 90 mm up the handle, on Ø17 with 0.4 squeeze.
  - The body cradle has a relief beside the riser blades' hooks.
- **Hinge:**
  - M2×8, pivot 5 mm under the top, knuckles r 5 flush with the rim.
  - Hidden tooth-and-groove stop at 300° (30° past upright). The lid's back meets the cover plate end at about 301.5°.
  - The cover plate stops 1 mm past the riser seats' snap mouths.
  - Assembly as v4: open the lid to about 115° so the teeth drop into the groove openings at the arm tops.
- **Magnets:** two at the latch end, at y ±22 (lid x 72), with Ø10.6 bosses tied into the end walls.
- **Edges:**
  - 2 mm 45° chamfers on all bed edges.
  - 2.5 mm round on the side-wall tops.
  - 6 mm round on the latch-end corners, 1.5 mm on the arm ends.
  - 2 mm chamfer across the latch-end top and the lid's hinge-end back.
  - Lid's nested long edges: 1 mm.
- **Finish:** Toolroom knurl on both walls at the latch end, three ticks in the lid back, Bambu logo inlay on the bottom.
- **Checks passed:**
  - Closed: overlap only on the z = 17 seam.
  - Swing: clear from 1° to 299°, teeth engage at 300°.
  - Table: the lid stays off the table at 270° and 300°.
  - Tools: the blades and handle clear the closed body.
  - Meshes: all STLs watertight.
- **Build:** `make v5` →
  - `trim_case_body_2color.3mf`, `trim_case_lid_2color.3mf`
  - `trim_case_tests.3mf` (snap, clip, hinge body, hinge lid)

## v5 embellishments (2026-11-18)
- **Handle silhouette** on the lid back, centred along the lid (`sil_x0`). It is 18 mm off centre across the lid (`sil_y = 18`), which puts it above the centre line in a top view with the hinge on the right. The profile was measured row by row from the product photo and scaled to Ø18.21 × 133 (`sil_profile`): the neck is Ø9 and the collar is a short 6 mm cone. It is a two-colour inlay, 0.6 deep, in the lid inlay body. The knurl crosshatch is 0.7 lines at 3 pitch. A probe confirmed at least 0.9 of lid under the inlay everywhere. Toggle: `silhouette`.
- **Lid ticks:** dropped (`ticks = false`, own switch; `grip` now only drives the body knurl). The silhouette is centred along the lid again.
- **Latch tabs** (`tabs`), as on the original Deburring Tool Case (measured from ref/dtc_*.stl: 5.3 mm wedge lips, top face flush with the seam, body tab in the centre below the seam, two lid tabs either side above it). For v5 they are scaled up: they reach 6 mm past the latch end and are 7.5 → 1.5 thick, so the undersides are at 45° and need no support. The body tab is 26 → 14 wide; the lid tabs are centred at y ±23.75 and are 20.5 → 11 wide, 0.5 mm clear of the body tab. Each root sinks 1 mm into the end face so it fills the flutes behind it.
- **Flutes dropped** (`flutes = false`). Instead the body **knurl runs the full length of both sides** (`knurl_x = [-78, 70]`), stopping 13 mm short of the pivot to stay clear of the screw bosses and stop grooves. A 5 mm-wider case (more room for hooked blades turned outward) was tried and reverted: the user will orient the blades instead.
- **Flush hinge end:** the closed lid stopped 2.2 mm short of the arm ends (lid x 85.8 vs arms 88; it looked like about 3 mm with the chamfers). `X_hinge` is now `pivot + knuckle_r` (88). To keep the longer lid end off the table at the stand stops, the hinge-end lid back chamfer is now `e_hinge_back = 4.5` (it was `e_end`, 2). The table check is clear at 270° and 300°. Mid-swing (255–265°) the lid crosses the table plane, as the old lid did at 255°, so it can't be swung while the case sits upside down.
- Checks after the tabs (re-run after the knurl and flush-end changes, all still green): swing clear from 1° to 299° (the teeth engage at 300°), table clear at 270° and 300°, closed overlap only at z = 17, 0 bad edges.
- The closed check is still seam-only and the meshes have 0 bad edges. The hinge and swing are untouched.
- **Blade bore 3.25 → 3.2** (`bore`), for a snugger seat on the Ø3.15 shank (0.05 clearance). Mouths are unchanged (2.45 lower column, 2.35 riser column). `trim_case_tests.3mf` was regenerated to test it.

## Fit tests, round 2 (2026-11-19, PETG)
- **Snap mouths:** the 2.45 / 2.35 slits were too narrow to snap a Ø3.15 shank through, so blades were being slid in from the end. `snap_test` now uses one mouth width per row, the same in both columns: 2.6, 2.7, 2.8, 2.9, 3.0 (`test_mouths`). The narrowest is on the handle side, and each width is engraved 0.4 deep on the back. The full case keeps `mouth` until a width is picked. The bore stays 3.2.
- **Clip moved 2.5 mm toward the handle's bottom end** (`clip_x = hb + 87.5`, was 90). It sits on the smooth Ø17 part just past the knurled grip, so the grip's shoulder stops the handle from sliding when the case is upside down. The lid-vs-tools intersection is only the clip squeeze at x 3.5–9.5. The closed check overlaps only at z = 17.
- **Clip squeeze series:** `trim_case_clip_test_0.3/0.4/0.5.stl` (`clip_sq`, mm per side), labelled on the back.
- `trim_case_tests.3mf` now holds the snap series and the three clips. The hinge tests are still built as STLs.
- **Keyhole test** (`trim_case_keyhole_test.stl` / `.3mf`): rows with 2.9 and 3.0 mouths (labelled "2.9 K" / "3.0 K"). Each slit's deep end has a vertical Ø3.12 hole (`keyhole_d`) down to the bore axis, with the same 0.8 lead-in. The slit runs into it. The shank goes in tip-first through the hole, then the blade pivots down through the slit. The hole sits where the shank tip rests (bore end + 0.3). It appears only in `keyhole_test`.
- **Clip squeeze set to 0.3** (`clip_sq`): the 0.3 test clip was the best fit. The case clip now uses it.
- **Seats set (2026-11-19):** every one of the 10 slits is now 2.9 wide (`mouth` 2.9, `up_tighten` 0; it was 2.45 / 2.35), with a Ø3.12 keyhole at its deep end (`keyholes`, `keyhole_d`), as tested. The bore stays 3.2. Blades go in tip-first through the keyhole and are pivoted down through the slit.

## Print file (2026-11-19)
- `trim_case_print.3mf` puts the body and the lid on one plate, front to back, each with its inlays (filament 1 = case, filament 2 = inlays). It embeds Bambu Studio project settings for a P2S 0.4 with PETG Matte on a textured PEI plate.
- How it's built:
  1. `print_profile.py` flattens the system profiles (0.20mm Standard @BBL P2S, PETG Matte) and applies these settings: 0.2 layers, first-layer line width 0.42, Arachne, elephant foot 0, first layer 25/40 mm/s, avoid crossing walls, Spiral Lift z-hop, prime tower on.
  2. Bambu Studio's CLI merges the profiles into project settings.
  3. The flush matrix is set to 2×2 (white→black 170, black→white 670 mm³), and the colours to white/black.
  4. `pack_plate.py --stack --settings` packs the plate.
- Check: a CLI slice of the file takes 4 h 17 m, 140 layers, 129.8 g + 2.5 g, with 4 colour changes on layers 1–3. The first-layer inlay toolpaths land inside the pockets: the body logo prints 2 layers and the lid silhouette 3.
- **Fix (2026-11-19, after the first full print):**
  - **Clip moved down to the knurl:** `clip_x = hb + 82`. The clip runs 79–85 mm up the handle, with its lower face 0.5 mm above the end of the knurl (78.5, `sil_lines[0]`). The knurl shoulder stops the handle sliding. Before this it was at 87.5, still 6 mm above the knurl.
  - **Lower-step keyholes:** the lower-column slits started 1 mm from the bore end, so the Ø3.12 keyhole stuck out only 0.7 mm past them and read as a rounded slit end. These slits now start 2 mm in, like the riser seats (`snap_slot(LO, LO[1] + 2, …)`), so all 10 seats are the same: the keyhole stands 1.7 mm past each slit.
  - Checks:
    - Meshes are watertight.
    - Lid vs tools: only the clip squeeze on the handle (x −2…4).
    - Body vs tools: empty.
    - Closed: overlap only at z = 17.
    - Swing: clear from 1 to 299°, stop at 300°.
    - CLI slice: 4 h 18 m, 129.8 + 2.5 g.
- **Clip moved 5 mm further down** (user's request, after the first full print): `clip_x = hb + 77`, so the clip spans 74–80 mm up the handle. This means the real knurl ends lower than the 78.5 measured from the photo, which is still used for the silhouette inlay. Checks repeated:
  - Lid vs tools: only the clip squeeze.
  - Body vs tools: empty.
  - Closed: overlap only at z = 17.
  - Swing: clear, stop at 300°.
  - CLI slice: 4 h 18 m.
