# Freezer bin: design log

An open-front stackable storage bin with honeycomb walls, as deep as a Bambu P2S will print.
Inspired by PandaN's "Stackable Storage Basket 200×200×150", with the swept front taken from a
second reference design. Nothing is derived from anyone else's mesh: this is a fresh parametric
model, and the reference files stay on the local disk.

## 2026-11-23: first design

### Size, and what the bed actually allows

The brief was "as deep as the printer allows". Read from the shipped P2S profile rather than
guessed:

- `printable_area` = 256 × 256, `printable_height` = 256.
- `bed_exclude_area` is an L: 28 × 28 at the front left, plus an 8 mm strip up the whole left edge.

So a part narrow enough to clear that corner can use nearly the whole 256 in Y. At 204.7 mm wide
the bin sits at x ∈ [28, 232.7], leaving y ∈ [3.5, 251.85] — about 23 mm of slack in X and 4 mm in
Y. Settled on **`depth = 246`** (248.35 over the flange), `width = 200`, `height = 150`.

An earlier instinct to print it rotated 45° was wrong and was dropped: turning a rectangle on the
diagonal only helps when it is much longer than it is wide. At 200 wide, rotating makes the
footprint bigger, not smaller, so the bin prints axis-aligned.

### Stacking

The bin above has to land on the one below without either needing support material, which rules out
anything hanging down off its underside — the floor is the first layer and must stay flat.

So the location feature goes *upward* instead. The top of each wall flares out over `flare_h = 3.0`
and carries on as a `collar_t = 2.0` flange standing `collar_h = 6.0` above the rim. The bin above
drops inside it and bears wall-on-wall on the rim. Outer faces stay flush, nothing overhangs, and
the flare is about 38° from vertical, so it prints clean.

- `stack_clear = 0.35` per side, flange to the bin above.
- The flange exists only where the rim is at full height, and fades out over `collar_ramp = 18`.
- `bottom_ch = 0.6` chamfer round the bottom edge: lead-in, and it keeps elephant foot off the fit.

`part = "stack_check"` intersects a bin with the bin stacked on it; the result must be empty. The
two meet face to face on the rim, so the upper bin is lifted by `check_eps = 0.02` to keep those
coplanar faces out of the result — anything left is real interference. First run flagged a
zero-thickness patch at z = 150 spanning y ∈ [−13, 122.4], which is exactly the intended bearing
ring; the epsilon makes the pass mechanical instead of something you have to measure.

### The front

The first version cut the side walls down to the lip on a straight diagonal, as in the PandaN
original. Changed to a **quarter-ellipse sweep** (`front_curve`), taken from the second reference:
it leaves the lip vertically and flattens out level with the rim. The straight cut is still there
as `front_curve = false`.

The curve leaves about 3100 mm² more wall per side than the diagonal — roughly 4 g — and removes
the stress concentrator where the diagonal met the rim.

`front_h = 50` with `slope_run = 110`: a stacked bin leaves 100 mm of access into the one below, and
the floor above cantilevers 110 mm over that opening. The side walls and front lip act as downstand
beams along that edge. For a 4 mm floor spanning the 195 mm between side walls, 4 kg distributed
works out at about 1.4 mm of sag — acceptable, and the governing reason the floor did not get
thinner (see below).

### Honeycomb

Pointy-top hexagons on a triangular lattice: the only overhang is a self-supporting apex, so no
cell needs support. Each panel is a 2D silhouette inset by a margin, intersected with the grid,
then **opened** (`offset(-1.0)` then `offset(+1.0)`) so part-cells at the panel edge drop out
instead of printing as slivers. That also rounds the cell corners, which extrudes more cleanly.

Two bugs found by looking at the renders rather than trusting the code:

- The grid was generated centred on z = 0, so it only reached about 100 mm up a 150 mm wall and the
  top third of every panel came out solid. The grid is now centred on the panel.
- A 3/4 preview made the side walls *look* solid. They were not — an orthographic side elevation
  showed the honeycomb was there all along. Preview shading was hiding it; the images are now
  rendered with `--render`.

### Weight

First slice of the design as drawn — 9 mm cells, 2.4 mm webs, solid floor — came back at
**294.6 g and 13 h 32 m** (P2S 0.4, 0.20 Standard, Bambu PETG Matte). Too heavy; target was 200 g.

Mesh volume says 334 cm³ but the slicer only lays down 215 cm³, because the 4 mm floor gets sparse
infill between its solid skins. That matters: **thinning the floor mostly removes air, not
plastic.** Dropping it 4.0 → 3.0 would have saved about 8 cm³ while halving its stiffness. It
stayed at 4.0.

What actually works is opening the panels up. Every figure below is a real slice of the real STL,
not an estimate:

| Walls (af/web) | Floor | Wall t | Filament | Time |
|---|---|---|---|---|
| 9 / 2.4 | solid | 2.4 | 294.6 g | 13 h 32 m |
| 12 / 2.0 | solid | 2.4 | 271.1 g | 11 h 41 m |
| 12 / 2.0 | hex 12 / 3.0 | 2.4 | 224.0 g | 12 h 35 m |
| 12 / 2.0 | hex 12 / 3.0 | 2.0 | 211.9 g | 10 h 41 m |
| 14 / 2.0 | hex 12 / 3.0 | 2.4 | 219.4 g | 12 h 00 m |
| 14 / 1.8 | hex 12 / 3.0 | 2.4 | 219.9 g | 12 h 33 m |
| 14 / 1.8 | hex 12 / 3.0, front too | 2.4 | 207.9 g | 12 h 47 m |
| 14 / 1.8 | hex 14 / 2.6 | 2.4 | 210.4 g | 12 h 07 m |
| **16 / 1.8** | **hex 14 / 2.6** | **2.4** | **203.1 g** | **11 h 28 m** |

Reading it:

- **Perforating the floor is the big one, −47 g.** It is also the counter-intuitive one: a
  perforated 4 mm floor is both lighter *and* stiffer than a solid 2.4 mm one, because bending
  stiffness goes with thickness cubed while weight goes with the material that is left.
- Coarsening the walls from 9 to 12 mm cells: −23.5 g. 12 → 16 gives another −21 g.
- Thinning the walls 2.4 → 2.0 only buys 12 g, and costs rigidity on a bin this size plus bearing
  width at the rim. **Rejected** — the walls stay at 2.4 (6 lines at 0.4).
- Perforating the front lip is worth 12 g but the lip is too short for a tidy pattern and it is the
  obvious face to label. Left in as `front_hex`, **off by default**.

Settled on **`hex_af = 16`, `hex_web = 1.8`, floor perforated at 14 / 2.6**: 203 g, 11 h 28 m, a
31% cut in filament and two hours off the print. The floor keeps smaller cells and thicker webs
than the walls — it carries the load, and less falls through it.

### Open questions

- Not yet printed. The fit tests (`stack_test_top`, `stack_test_bottom`) exist so `stack_clear` can
  be checked for 8 g instead of 203 g.
- Intended use is a freezer, which is why the perforation everywhere is a feature rather than only
  a weight saving — but it has not been tested cold, and PETG and PLA both stiffen and embrittle at
  −18 °C. Nothing in the design has been tuned for that yet.
- 14 mm floor cells are large. If small items need to not fall through, drop `floor_hex_af`; the
  cost is in the table above.

## 2026-11-23: structural review, and two fixes

Reviewed for strength and printability before committing to an 11-hour print. Intended filament
and service conditions are now known: **Sunlu PETG 2.0**, in a freezer logged at **-5 to -7 F
(about -21 C)**, spiking to 0 F.

### Strength: not close to the limit

Cross-sections sliced out of the mesh, exactly, rather than estimated:

| Where | Measured |
|---|---|
| Floor, solid fraction | 19,196 of 49,145 mm2 = **39.1%** |
| Wall, weakest plane (through a row of holes) | **310 mm2** (~20% of the solid wall) |
| Wall, through the webs between rows | 780 mm2 |
| Rim band (z 142-150, solid) | 1,240-1,290 mm2 |
| Bearing ledge at z=150 | 2,223 mm2 |

Against that, a loaded bin above is about 100 N:

- Compression through the weakest wall plane: **0.32 MPa**, against ~50 MPa for PETG.
- Bearing on the rim ring (2,398 mm2): **0.042 MPa**.
- Euler buckling of a single 1.8 x 2.4 x 9.2 mm web: critical load ~270 N, versus a fraction of a
  newton actually carried.
- The 110 mm front cantilever, which sounds like the weak point, is not one: the side walls act as
  150 mm deep beams, giving ~0.07 mm deflection and ~1 MPa.
- Floor under 5 kg: ~1-2.5 mm sag, ~5 MPa, rising to ~12 MPa at the hole edges once stress
  concentration is allowed for.

Nothing is within an order of magnitude of failing. At -21 C PETG gets stiffer, so the deflections
improve; what gets worse is ductility, which moves the whole risk to notches.

**Correcting the entry above:** the 2026-11-23 weight section claims a perforated 4 mm floor is
"both lighter *and* stiffer" than a solid 2.4 mm one. Lighter is right, stiffer is not supported.
Perforated-plate stiffness follows ligament efficiency (web / pitch = 2.6 / 16.6 = 0.157), not area
fraction, which puts the effective modulus near 10-20% of solid: E.t^3 of roughly 6-13 against 13.8
for a solid 2.4 mm floor. Call it parity. The perforated floor is still the right choice -- it is
where the 47 g came from and the margins hold -- but the reason given was wrong.

### Fix 1: the honeycomb pointed the wrong way

The cells were pointy-top. For a hole in a **vertical wall** that is the worst orientation: the two
upper edges of each hexagon lie at 30 degrees from horizontal, so each layer advances 0.346 mm over
a 0.42 mm line -- about 18% supported.

Measured on the mesh, over the wall band z 20-140: **108 cm2, 11.7% of the wall surface, below 45
degrees.** Bambu Studio agreed, though not in the way the feature labels suggest -- it tags only
1.03 m as "Overhang wall", but **22.46 m of extrusion runs at 10 mm/s**, which is
`overhang_4_4_speed`, the fully-unsupported bucket. That is about 37 minutes of crawling and a
drooped roof on every cell, and PETG handles this worse than PLA.

The note in the first entry that "pointy-top hexagons self-support" is true for honeycomb infill and
for holes through a horizontal plate. It is wrong for holes in a vertical wall, which is where these
are. The reference design that prints cleanly measures 14.5% flat-bridge and 22.4% above 45 degrees
with ~1% in the 30-40 band -- the flat-top signature.

`hex_grid()` now lays the lattice out pointy-top and gives it a quarter turn, so the cells are
flat-top: side edges at 60 degrees, and each hole roofed by a short flat that bridges.

| | pointy-top | flat-top |
|---|---|---|
| Wall surface below 45 deg | 108.3 cm2 (11.7%) | **16.0 cm2 (1.7%)** |
| Extrusion at or below 30 mm/s | 5.05% | **0.35%** |
| Extrusion at 10 mm/s (unsupported) | 22.46 m | **none** |
| Sliced | 203.1 g, 11 h 28 m | 201.7 g, 10 h 44 m |

Lighter, 44 minutes faster, and the unsupported crawl is gone.

### Fix 2: a radius where the floor meets the wall

That junction was a sharp internal 90 degree corner, and with the floor flexing a millimetre or two
under load it is the highest-stressed line in the part. Cold PETG is notch-sensitive, so it now gets
`fillet_r = 4.0`, swept as a quarter-round out of the cavity.

The cut only ever narrows downward, so the fillet is free to print: re-measuring the overhang
budget over z 3.5-140 leaves the sub-45 figure at **16.0 cm2**, unchanged, with the fillet's own
7.8 cm2 of surface landing above 45 degrees. It adds 3,006 mm3 to the mesh (+3.8 g of solid), but
the sliced weight went *down* 0.8 g, because the thickened base takes sparse infill where the sharp
corner previously forced solid.

### Stacking features: kept, because they carry load rather than cause problems

Checked on the question of whether the flange is a liability. It is not -- it is the strongest part
of the bin:

- Bearing stress on the rim ring is **0.042 MPa** against ~50 MPa. A margin over 1,000x.
- The flare widens the rim radially from 2.4 mm to 4.75 mm. In-plane bending of a ring goes as
  width cubed, so the flare leaves the rim about **7.8x stiffer**. Deleting it would leave a wall
  that is 80% holes with a free top edge -- the floppiest condition available, and the mouth would
  go oval under load.
- It needs no support: the flare stands about 38 degrees off vertical.
- There is no eccentricity problem. The bearing ring's centroid sits 0.175 mm outboard of the wall
  centreline, worth 0.025 N.mm/mm.

The one caveat is the 2 mm upstand itself, which is the most exposed thin feature on the part. A
hard point knock on ~20 mm of it computes to ~94 MPa, past yield for cold PETG; spread along a
whole side the same shove gives ~9 MPa. So it is what breaks first if a loaded stack gets shoved,
and `collar_t` is the knob if that happens in practice.

### Cold service

- Thermal contraction is **not** a fit problem. Both bins shrink about 0.7 mm over 246 mm equally,
  so `stack_clear` is preserved. Fit-test at room temperature and the result holds at -21 C.
- The rounded hole corners from the morphological open matter more than they did at room
  temperature: sharp corners would be crack initiators in cold PETG.
- The floor is well oriented for its load. It is printed flat, so bending puts tension along the
  layers rather than across them.

### Final

**200.90 g, 10 h 43 m 8 s, 780 layers** on the P2S 0.4 / 0.20 Standard / PETG profile. Down from
294.6 g and 13 h 32 m as first drawn: 32% less filament and nearly three hours quicker.

### Still open

- Still not printed. Fit tests first; they are ~8 g and ~23 g against 201 g.
- No cold validation yet. The reasoning above is about where the risk sits, not a test.
- 14 mm floor cells remain large for small items.

## 2026-11-23: grab rail, label pocket, and a cold test piece

### A rail on the front lip

The bin had no grip. 200 mm wide and about 7 kg loaded, and the only thing to hold was the
2.4 mm top edge of the front lip -- which is also a free edge spanning the full width, so it
flexes when pulled.

`lip_rail()` grows the top of the lip outward into a rounded bead: `rail_w = 3.0` proud of the
face over `rail_h = 9.0`, ramping out at about 27 degrees from vertical and then rolling over on
a 3 mm radius. That gives a 5.4 mm rounded face to pull on, and it stiffens the edge.

Outward only, deliberately -- a bulge on the inside would overhang the cavity. The underside
ramp is well inside 45 degrees, so it carries itself: measured over the rail band z 40-51, the
sub-45 overhang is **0.94 cm2**, and the whole-part figure stays at 0.93%.

The ring is built from `footprint()` offsets like the collar, so it follows the rounded corners,
and it is trimmed back to the front by the same `top_wedge()` that cuts the opening, shifted down
by `rail_h`. Because the quarter-ellipse sweep leaves the lip vertically, that trim kills the rail
within about 3 mm of the front face: it covers the flat front, wraps to about x = +/-98 round the
corner radii, and fades out instead of stopping in a step.

### Label pocket

`label_recess()`: 40 x 30 mm, `label_d = 0.6` deep (three layers at 0.2), corners on a 2 mm
radius. Centred at `label_z = 24`, which keeps it clear of the lip root below -- that root is the
section that works hardest if the bin is dragged by the rail -- and 2 mm clear of the rail above.
`label_w = 0` turns it off.

The pocket thins the wall to 1.8 mm locally, the same as a honeycomb web. Radiused corners are not
decoration: this is a thinned patch in a wall that gets pulled on, and cold PETG starts cracks at
sharp corners.

Rail and pocket together cost **0.73 g and 7 minutes**: 201.63 g, 10 h 50 m 41 s.

### Bed placement: an error in the first entry, found by checking the toolpaths

The first entry claims the bin "sits at x in [28, 232.7]". That is where it *has* to sit, but it
is not where a slicer puts it. Reading the actual G-code back: auto-centred, the part lands at
**X 25.86 to 230.14**, and 101 extruding moves fall inside the 28 x 28 front-left exclusion
corner. That was already true before the rail was added; it was simply never checked.

So the part has to be moved right by about 2.5 mm, to a left edge at X >= 28. Then it sits at
X 28-232.7, Y 2.3-253.7, clear of the L. The README now says so.

The rail also pushed the overall depth from 248.35 to **251.35 mm**, since it stands 3 mm proud of
the front. Front and back clearance is now about 2.3 mm rather than 3.8 mm. Kept, because the
brief was the deepest bin the bed takes and the rail is part of the bin; `depth = 243` returns the
old footprint for anyone who would rather have the margin.

### Cold test piece

`cold_test = true` builds a 94.7 x 65.35 x 76 mm bin: **38.2 g, 2 h 6 m**. Only `width`, `depth`,
`height`, `front_h`, `slope_run`, `collar_ramp` and `label_h`/`label_z` change. Everything that
decides cold survival stays at full size -- wall 2.4, cells 16 / 1.8, floor 4.0 perforated at
14 / 2.6, `fillet_r` 4.0, `collar_t` 2.0, `collar_h` 6.0, `stack_clear` 0.35, the rail, and a
label pocket that thins the lip to 1.8 mm exactly as the full one does.

A uniform scale would have been the wrong test. At 0.4 scale the wall becomes 0.96 mm, the webs
0.72 mm and the stacking clearance 0.14 mm: three features that would fail for reasons the real
bin would never see. The flag shrinks the box and nothing else.

Checks on the test piece: `stack_check` passes with `cold_test=true`, the sections oscillate
between 213 and 684 mm2 so the honeycomb is really there, and the sub-45 overhang is 0.81%.

The panels only carry two or three cells each at this size, which is the point -- a cell, a web
junction and a panel edge are what crack, and those are all present.

### Confirmed, not assumed

The all-round perforation is wanted: this is a deep freezer and the holes are for **airflow**.
The first entry guessed at that; it is now the stated reason, and it means the floor cells stay
as they are rather than being closed up to stop things falling through.

## 2026-11-23: Bambu Studio print files, and a correction about the bed

Target filament is now known: **SUNLU PETG 2.0**.

### The P2S has no exclusion zone. The first two entries were wrong about this.

Both earlier entries build on "`bed_exclude_area` is an L: 28 x 28 at the front left, plus an
8 mm strip up the whole left edge", and the last one went further and called auto-centring a bug
because 101 extruding moves landed in that corner.

Reading the profile chain properly:

- `fdm_bbl_3dp_001_common.json` does declare that L:
  `["0x0","28x0","28x28","0x28","0x28","8x28","8x256","0x256"]`.
- `Bambu Lab P2S 0.4 nozzle.json` inherits that file and then sets **`"bed_exclude_area": []`**,
  clearing it. The flattened P2S profile has no exclusion area at all.

So the L belongs to the older machines that inherit 001_common without clearing it. On the P2S the
whole 256 x 256 is usable, centring is correct, and nothing needs moving. The depth argument in
the first entry reached the right answer -- 246 mm of body fits -- but by the wrong route: it is
the bed being 256 deep that allows it, not a part narrow enough to dodge a corner.

Centred, the bin sits at X 25.6-230.4, Y 2.3-253.7. Y is the tight dimension at 2.3 mm either end;
X has 25.6 mm spare. `pack_plate.py` now reads `printable_area` and `bed_exclude_area` out of the
machine profile and only shifts when there is something to shift away from, so the same script
does the right thing on an X1 or P1.

### Filament profile

Bambu ships `SUNLU PETG @base` but instantiates it only for the A1, A1M and X1C, and has nothing
for PETG 2.0. `print_profile.py` therefore starts from `Bambu PETG Matte @BBL P2S 0.4 nozzle` for
the machine-specific keys that have to be right -- retraction 0.4, the overhang speed buckets,
Spiral Lift z-hop, the per-slot array widths -- and lays SUNLU's material numbers over it.

| | SUNLU PETG 2.0 | Bambu PETG Matte | why |
|---|---|---|---|
| density | 1.27 | 1.37 | real unfilled PETG; Matte is filled |
| nozzle | 245 / 250 first | 240 / 240 | SUNLU's own profile |
| textured plate | 70 | 60 | SUNLU publish 70-80; 70 is the low end, and PETG on PEI can bond hard enough to damage the sheet |
| flow ratio | 0.95 | 0.98 | SUNLU's own profile |
| max volumetric | 12 | 13-15 | SUNLU's own limit |
| fan max / min | 30 / 10 | 60 / 30 | PETG wants less part cooling |
| overhang fan | 90% | 40% | every hex roof is a bridge now |

**The density change is why the weight dropped.** Same plastic, same volume: 201 g quoted against
Matte is 186 g in SUNLU. Every figure in the weight table above was sliced against Matte, so
multiply by 0.927 for this filament. The relative comparisons in that table all still hold.

### Process settings: two kept, three rejected on measurement

Kept: `brim_type = no_brim` (2.3 mm of bed front and back, and a flat PETG bottom on textured PEI
does not need one) and `curr_bed_type = Textured PEI Plate`. Everything else is the system
default for 0.20 mm Standard.

Three that looked obviously right and were not. Each A/B sliced on the real part:

| Candidate | Measured | Verdict |
|---|---|---|
| `reduce_crossing_wall = 1` | 10 h 00 -> 10 h 42, 0 g. Travel **up** 8.5% (608 -> 660 m), retractions up 3% | rejected |
| `wall_generator = arachne` | sparse infill in the honeycomb zone 9.07% -> 8.91%, gap infill 0.00% either way, 1.2% more extrusion, ~46 min slower | rejected |
| `seam_position = aligned` | already the system default | no-op |

`reduce_crossing_wall` is the instructive one. It was picked to fight stringing, on the strength
of the 169,000 retractions and 608 m of travel measured earlier -- but it does not reduce travel,
it reroutes it around perimeters, so it buys its (unmeasurable here) anti-ooze benefit by adding
distance. The filament profile already asks for Spiral Lift z-hop, which is the cheap defence. It
is documented in `print_profile.py` as the thing to turn on if the first print strings inside the
cells, with its price attached.

Worth noting for anyone comparing numbers: the earlier sweeps in this file were sliced with
profiles borrowed from `trim-kit-case`, which carry `reduce_crossing_wall = 1` and `arachne` for
that project's two-colour inlays. That is most of why the bin was quoted at 10 h 51 before and
9 h 14 now. The sweep's internal comparisons are unaffected -- every row had the same settings.

### Output

`make print` builds two files, each a single plate so the placement is verifiable:

| File | Contents | Sliced |
|---|---|---|
| `freezer_bin_print.3mf` | the bin, centred | 186.42 g, 9 h 14 m 18 s |
| `freezer_bin_cold_test_print.3mf` | two cold-test bins | 70.88 g, 3 h 6 m 9 s |

A single three-plate project was tried first and abandoned. Bambu writes multi-plate 3MFs by
offsetting each plate in one global coordinate space, and the stride is not in the profile: at
256, 266 and 276 mm plate 2 came back "Found Object partly inside, can not be sliced", at 280 and
above it sliced. Since the correct value could not be established and the GUI's placement cannot
be checked headlessly, one plate per file is the honest answer -- both slice cleanly from the CLI
with every embedded setting verified in the G-code.
