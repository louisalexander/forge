// freezer_bin.scad -- open-front stackable storage bin with honeycomb walls.
//
// Sized to the largest footprint a Bambu P2S bed takes: the printable area is 256 x 256 with an
// exclusion L (28 x 28 at the front left, plus an 8 mm strip up the left edge), so a 204 mm wide
// part clears it and can use nearly the whole 256 in Y. 250 mm over the flange leaves 3 mm either end.
//
// Stacking: the top rim carries a flange that rises above it and wraps the bin above. Bins sit
// wall-on-wall at a pitch of `height`, located by the flange. The front lip is low and the side
// walls slope down to it, so a stacked bin leaves a `height - front_h` opening into the one below.

// ---- cold test piece --------------------------------------------------------
// A small bin for cold-soaking in the freezer before committing to the full print. Everything
// that decides whether this design survives -21 C is left at full size -- wall, cell, web,
// floor, fillet, flange and stacking clearance -- and only the overall box shrinks. A uniform
// scale would thin the walls and close the stacking gap, and then it would be testing a
// different object. Build it with: make freezer_bin_cold_test.stl
cold_test   = false;

// ---- size -------------------------------------------------------------------
width       = cold_test ?  90 : 200;   // X, left to right
depth       = cold_test ?  60 : 246;   // Y, front to back (250 over the flange)
height      = cold_test ?  70 : 150;   // Z, and the stacking pitch
corner_r    = 8;      // outer corner radius

// ---- shell ------------------------------------------------------------------
wall        = 2.4;    // 6 lines at 0.4
floor_t     = 4.0;
bottom_ch   = 0.6;    // chamfer round the bottom edge: lead-in, and no elephant foot on the fit
fillet_r    = 4.0;    // radius at the floor-to-wall junction. The loaded floor flexes a millimetre
                      // or two and this corner is the highest-stressed line in the part; cold PETG
                      // is notch-sensitive, so it gets a radius rather than a sharp internal edge.

// ---- open front -------------------------------------------------------------
front_h     = cold_test ? 25 : 50;     // height of the front lip
slope_run   = cold_test ? 45 : 110;    // how far back the side walls rise to full height
front_curve = true;   // false = a straight diagonal; true = a quarter-ellipse sweep
curve_steps = 48;

// ---- grab rail and label ----------------------------------------------------
// The top of the front lip is where a hand goes when the bin is full, and on its own it is a
// 2.4 mm edge across a 200 mm free span. The rail gives it a rounded 5.4 mm face to pull on and
// stiffens that edge. It grows outward only: an inward bulge would overhang the cavity.
rail_w      = 3.0;    // how far the rail stands proud of the front face
rail_h      = 9.0;    // its height, round-over included

label_w     = 40;     // label pocket in the front face. 0 for none.
label_h     = cold_test ? 10 : 30;     // the test piece keeps the pocket -- it thins the lip to
label_d     = 0.6;    // 3 layers at 0.2    1.8 mm, which is a place a cold crack could start
label_z     = cold_test ? 9.5 : 24;    // centre height: clear of the lip root and of the rail

// ---- stacking ---------------------------------------------------------------
collar_t    = 2.0;    // flange wall thickness
collar_h    = 6.0;    // how far the flange rises above the rim
collar_ramp = cold_test ? 10 : 18;  // the flange fades out over this much, where the slope starts
flare_h     = 3.0;    // the outer wall flares out to the flange over this height
stack_clear = 0.35;   // per side, flange to the bin above
collar_lead = 1.2;    // lead-in chamfer at the top of the flange

// ---- honeycomb --------------------------------------------------------------
// Cell size is the main filament knob. At 9/2.4 the bin is a 295 g print; the values below
// make it 202 g. See DESIGN.md for the sliced weight of each combination.
hex_af      = 20.0;   // across the flats
hex_web     = 1.8;    // material between holes
hex_margin  = 8.0;    // solid border round each perforated panel

// A printed web is a stack of layers, so its weak plane is horizontal and it parts in Z, where
// this filament is 20 MPa against 43 in X-Y. A 1.8 x 2.4 web is 4.3 mm2, so one lets go at about
// 86 N -- fine for a bin full of food, which spreads load over the whole wall, but a thumb puts
// all of it through a single web. A test print duly snapped one. So: the sides, which are the
// structural members and the part you grab, are solid; the back and floor stay open for airflow.
side_hex    = false;  // perforate the side walls too
hex_base    = 15;     // extra solid wall below the perforated field, on top of hex_margin
// How hard to "open" the clipped grid. Part-cells narrower than twice this are dropped rather
// than printed as slivers, and it is what stops a panel edge filling with little round offcuts.
// It has to scale with the cell: a 1 mm open that was ample at 9 mm cells leaves debris at 20.
hex_open    = hex_af / 8;

// The floor is the single heaviest panel, so it is perforated too. Its webs are thicker and
// its cells smaller than the walls': it carries the load, and less falls through.
floor_hex     = true;
floor_hex_af  = 14.0;
floor_hex_web = 2.6;
floor_margin  = 10.0;  // solid border round the floor, inside the walls

// The front lip carries almost no load, so it can be perforated as well -- worth about 12 g.
// Off by default: it leaves a face to label, and the lip is too short for a tidy pattern.
front_hex     = false;
front_label_h = 0;     // solid band at the top of the lip, when front_hex is on
front_margin  = 5.0;

$fn = 48;

y_front = -depth / 2;

function stack_pitch() = height;

// ---- helpers ----------------------------------------------------------------

// Rounded-rectangle footprint, grown (or shrunk) by d all round.
module footprint(d = 0) {
    $fn = 48;
    hull() for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * (width / 2 - corner_r), sy * (depth / 2 - corner_r)])
            circle(r = max(corner_r + d, 0.01));
}

// Extrude a 2D shape drawn in (y, z) along X, centred on x = 0.
module yz_extrude(len) {
    translate([-len / 2, 0, 0]) rotate([0, 90, 0]) rotate([0, 0, 90]) linear_extrude(len) children();
}

// Extrude a 2D shape drawn in (x, z) along Y, centred on y = 0.
module xz_extrude(len) {
    translate([0, len / 2, 0]) rotate([90, 0, 0]) linear_extrude(len) children();
}

// ---- the open front ---------------------------------------------------------

// The top edge of a side wall, front to back: it leaves the lip vertically and flattens out
// level with the rim, as a quarter ellipse. Straight if front_curve is off.
function edge_pts() =
    front_curve
    ? [for (i = [0 : curve_steps])
         let (a = i * 90 / curve_steps)
         [y_front + slope_run - (slope_run - wall) * cos(a),
          front_h + (height - front_h) * sin(a)]]
    : [[y_front + wall, front_h], [y_front + slope_run, height]];

function rev(v) = [for (i = [len(v) - 1 : -1 : 0]) v[i]];

// Everything above the top edge: the lip, the sweep up to full height, then the flange ramp.
module top_wedge() {
    yz_extrude(width + 40)
        polygon(concat([[y_front - 30, front_h]],
                       edge_pts(),
                       [[y_front + slope_run + collar_ramp, height + collar_h],
                        [y_front + slope_run + collar_ramp, height + collar_h + 40],
                        [y_front - 30,                      height + collar_h + 40]]));
}

// A rounded rail along the top of the front lip: something to hook cold fingers under when the
// bin is full, and it stiffens what is otherwise a 2.4 mm free edge across the whole width.
// It grows outward only -- an inward bulge would overhang the cavity -- and its underside ramps
// at about 27 degrees from vertical, so it carries itself. The ring runs right round the
// footprint and is trimmed back to the front by the same top_wedge that cuts the opening, so it
// fades out as the side walls sweep up instead of ending in a step.
module lip_rail() {
    steps = 10;
    intersection() {
        union() {
            hull() {
                translate([0, 0, front_h - rail_h]) linear_extrude(0.01) footprint(0);
                translate([0, 0, front_h - rail_w]) linear_extrude(0.01) footprint(rail_w);
            }
            for (i = [0 : steps - 1]) {
                a0 = i * 90 / steps;
                a1 = (i + 1) * 90 / steps;
                hull() {
                    translate([0, 0, front_h - rail_w + rail_w * sin(a0)])
                        linear_extrude(0.01) footprint(rail_w * cos(a0));
                    translate([0, 0, front_h - rail_w + rail_w * sin(a1)])
                        linear_extrude(0.01) footprint(rail_w * cos(a1));
                }
            }
        }
        translate([0, 0, -rail_h]) top_wedge();
    }
}

// Pocket for a label in the front face. 0.6 deep is three layers at 0.2 -- enough to register a
// sticker or a strip of tape and keep a sleeve from wiping it off. Corners are radiused: this is
// a thinned patch in a wall that gets pulled on, and cold PETG starts cracks at sharp corners.
module label_recess() {
    r = 2;
    translate([0, y_front + (label_d - 0.1) / 2, 0])
        xz_extrude(label_d + 0.1)
            translate([0, label_z])
                hull() for (sx = [-1, 1], sy = [-1, 1])
                    translate([sx * (label_w / 2 - r), sy * (label_h / 2 - r)])
                        circle(r = r, $fn = 24);
}

// ---- honeycomb --------------------------------------------------------------

// Flat-top hexagons on a triangular lattice. This is the orientation that prints in a vertical
// wall: each hole's side edges stand at 60 degrees from horizontal, and its roof is a short flat
// that bridges. Pointy-top is the self-supporting choice for a hole through a horizontal plate,
// but in a wall its roof edges fall to 30 degrees and droop -- measured, that put 11.7% of the
// wall surface below 45 degrees and dropped 22 m of extrusion to the slicer's 10 mm/s
// "unsupported" speed. See DESIGN.md.
module hex_grid(w, h, af = hex_af, web = hex_web) {
    R  = af / sqrt(3);              // circumradius
    p  = af + web;                  // centre to centre
    dy = p * sqrt(3) / 2;
    nx = ceil(h / p / 2) + 2;       // the lattice is laid out pointy-top and then given a quarter
    ny = ceil(w / dy / 2) + 2;      // turn, so w and h swap over when sizing it
    rotate(90)
        for (j = [-ny : ny], i = [-nx : nx])
            translate([i * p + (j % 2 != 0 ? p / 2 : 0), j * dy])
                rotate(30) circle(r = R, $fn = 6);
}

// Side wall silhouette in (y, z), inset by hex_margin.
module side_panel() {
    offset(-hex_margin) intersection() {
        translate([y_front + corner_r, floor_t + hex_base])
            square([depth - 2 * corner_r, height - floor_t - hex_base]);
        polygon(concat([[y_front - 30,   -30],
                        [depth / 2 + 30, -30],
                        [depth / 2 + 30, height]],
                       rev(edge_pts()),
                       [[y_front - 30,   front_h]]));
    }
}

// Front lip silhouette in (x, z), inset by front_margin, minus the label band at the top.
module front_panel() {
    offset(-front_margin)
        translate([-width / 2 + corner_r, floor_t])
            square([width - 2 * corner_r, front_h - floor_t - front_label_h]);
}

// Back wall silhouette in (x, z), inset by hex_margin.
module back_panel() {
    offset(-hex_margin)
        translate([-width / 2 + corner_r, floor_t + hex_base])
            square([width - 2 * corner_r, height - floor_t - hex_base]);
}

// Clip the grid to a panel, then open it (erode, dilate) so part-hexes at the edge drop out
// instead of printing as slivers. It also rounds the hex corners, which extrudes more cleanly.
module perforation(w, h, open = hex_open) {
    offset(r = open, $fn = 12) offset(r = -open, $fn = 12) intersection() {
        translate([0, height / 2]) hex_grid(w, h);
        children();
    }
}

module hex_cuts() {
    if (side_hex) yz_extrude(width + 40) perforation(depth, height) side_panel();
    translate([0, depth / 2 - wall / 2, 0])
        xz_extrude(wall + 6) perforation(width, height) back_panel();

    if (front_hex)
        translate([0, y_front + wall / 2, 0])
            xz_extrude(wall + 6) perforation(width, height) front_panel();

    // Floor: holes straight down the Z axis, so they need no overhang care at all.
    if (floor_hex)
        translate([0, 0, -1]) linear_extrude(floor_t + 2)
            offset(r = floor_hex_af / 8, $fn = 12) offset(r = -floor_hex_af / 8, $fn = 12) intersection() {
                hex_grid(width, depth, floor_hex_af, floor_hex_web);
                footprint(-wall - floor_margin);
            }
}

// ---- shell ------------------------------------------------------------------

module outer_solid() {
    union() {
        hull() {
            linear_extrude(0.01) footprint(-bottom_ch);
            translate([0, 0, bottom_ch]) linear_extrude(0.01) footprint(0);
        }
        translate([0, 0, bottom_ch]) linear_extrude(height - bottom_ch) footprint(0);
    }
}

// The cavity, open all the way up, with its bottom corner swept out to a quarter-round so the
// floor meets the wall on a radius instead of a sharp internal edge. The cut only ever narrows
// downward, so the fillet is free to print: every layer of it lands on the one below.
module cavity() {
    steps = 16;
    for (i = [0 : steps - 1]) {
        h0 = fillet_r * i / steps;
        h1 = fillet_r * (i + 1) / steps;
        d0 = fillet_r - sqrt(max(0, fillet_r * fillet_r - pow(fillet_r - h0, 2)));
        d1 = fillet_r - sqrt(max(0, fillet_r * fillet_r - pow(fillet_r - h1, 2)));
        hull() {
            translate([0, 0, floor_t + h0]) linear_extrude(0.01) footprint(-wall - d0);
            translate([0, 0, floor_t + h1]) linear_extrude(0.01) footprint(-wall - d1);
        }
    }
    translate([0, 0, floor_t + fillet_r])
        linear_extrude(height + collar_h + 2) footprint(-wall);
}

// Flange: the wall flares out over flare_h, then rises as a collar the bin above drops into.
module collar_solid() {
    union() {
        hull() {
            translate([0, 0, height - flare_h]) linear_extrude(0.01) footprint(0);
            translate([0, 0, height - 0.01])    linear_extrude(0.01) footprint(stack_clear + collar_t);
        }
        translate([0, 0, height]) linear_extrude(collar_h) footprint(stack_clear + collar_t);
    }
}

// The bin with no holes in it. Split out so the break test can borrow it for the solid rib that
// anchors its cut edges.
module shell() {
    difference() {
        union() { outer_solid(); collar_solid(); lip_rail(); }

        // cavity, open all the way up, filleted where it meets the floor
        cavity();
        // bore through the flange
        translate([0, 0, height]) linear_extrude(collar_h + 2) footprint(stack_clear);
        // lead-in chamfer at the top of the flange
        translate([0, 0, height + collar_h - collar_lead]) hull() {
            linear_extrude(0.01) footprint(stack_clear);
            translate([0, 0, collar_lead]) linear_extrude(0.01) footprint(stack_clear + collar_lead);
        }

        top_wedge();
    }
}

module bin() {
    difference() {
        shell();
        hex_cuts();
        if (label_w > 0 && label_h > 0) label_recess();
    }
}

// ---- checks and test pieces -------------------------------------------------

// Must come out empty. The bins meet face to face on the rim, so the upper one is lifted by a
// hair to keep those coplanar faces out of the result; anything left is real interference.
check_eps = 0.02;

module stack_check() {
    intersection() { bin(); translate([0, 0, height + check_eps]) bin(); }
}

// Back-right corner of the rim and flange, in its printed orientation.
module stack_test_top() {
    translate([0, 0, -(height - 25)]) intersection() {
        bin();
        translate([width / 2 - 60, depth / 2 - 60, height - 25]) cube([70, 70, collar_h + 26]);
    }
}

// Back-right corner of the floor, in its printed orientation.
module stack_test_bottom() {
    intersection() {
        bin();
        translate([width / 2 - 60, depth / 2 - 60, -1]) cube([70, 70, 26]);
    }
}

// Back corner, floor to mid-wall, in the orientation it prints in. The point of this one is to
// be broken: the first test print snapped a honeycomb web clean across a layer line, which is the
// Z direction and this filament's weak axis. Layer direction is the whole experiment, so the
// piece must not be rotated -- break it in the frame it was printed in or it tells you nothing.
//
// It spans the solid side wall, the corner, the start of the perforated back and the floor
// fillet, so the load path that failed is all present. Build it both ways and break both:
//   make freezer_bin_break_test.stl             solid sides (the fix)
//   make freezer_bin_break_test_hexside.stl     perforated sides (what broke)
bt_rib = 4;   // solid rib left along the cut edges
module break_test() {
    org = [width / 2 - 62, depth / 2 - 62, -1];
    box = [64, 64, 71];
    union() {
        intersection() { bin(); translate(org) cube(box); }
        // The cut slices straight through the honeycomb, which would leave webs waving in mid-air:
        // unprintable, and nothing like the real panel, where every web is anchored to a solid
        // margin. So the two inner cut faces keep a solid rib, which is what the real bin has.
        intersection() {
            shell();
            union() {
                translate(org) cube([bt_rib, box[1], box[2]]);
                translate(org) cube([box[0], bt_rib, box[2]]);
            }
        }
    }
}

// ---- part switch ------------------------------------------------------------

part = "bin";    // bin | stack_check | stack_test_top | stack_test_bottom | break_test | none

if (part == "bin")                    bin();
else if (part == "stack_check")       stack_check();
else if (part == "stack_test_top")    stack_test_top();
else if (part == "stack_test_bottom") stack_test_bottom();
else if (part == "break_test")        break_test();
