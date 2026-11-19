// Lens-wipe dispenser tower
// Wipes lie in a stack on a floor tilted 15 deg (rising toward the front).
// The front edge of the bottom wipe sits ~13 mm up over a finger pocket;
// pull it forward through the slot in the front wall. Only one fits the slot.
//
// style = "dock": flat-sided block with recessed horizontal grooves in framed
//                 side panels, flat top with a grooved drop-in lid.
// style = "fins": protruding heat-sink fins with 45 deg undersides.
//
// Axes: X across the front, Y front(-) to back(+), Z up. Units: mm.
// Spec: DESIGN.md

/* [Packets] */
packet_w   = 55;    // across the front (X)
packet_l   = 50;    // front-to-back, pull direction (Y)
packet_t   = 3.5;   // thickness
count      = 20;    // packets per fill
clearance  = 1.5;   // side clearance
depth_slack = 3;    // extra front-to-back room
top_slack  = 3;     // headroom above a full stack

/* [Dispensing] */
tilt       = 15;    // floor angle, rising toward the front
slot_perp  = 4.5;   // slot opening measured perpendicular to the floor
pocket_w   = 30;    // finger pocket width
pocket_len = 22;    // how far back the pocket reaches under the stack
pocket_floor = 1.2; // material under the pocket

/* [Follower weight] */
// Weighted plate that rides on top of the stack so the bottom wipe stays flat
// even when only a few are left. Fill the tray with coins or washers.
weight_plate = true;
plate_t    = 10;    // overall plate thickness
plate_floor = 2;    // tray floor
plate_wall = 2.4;   // tray wall
cover_t    = 1.6;   // inset cover that hides the weights (sits flush in the rim)
cover_ledge = 0.8;  // ledge the cover rests on
cover_gap  = 0.15;  // per-side clearance
snap_d     = 0.5;   // snap ridge height on the cover's long edges (0 = no snap)
snap_len   = 30;    // snap ridge length
plate_gap  = 0.75;  // side clearance in the chamber
plate_end_gap = 1.0; // front/back clearance in the chamber
// Front and back ends are slanted so they stand vertical (parallel to the
// chamber walls) when the plate lies on the tilted stack.

/* [Style] */
style      = "dock";  // [dock, fins]

/* [Body] */
side_wall  = 3.2;   // side walls (grooves are cut into these)
end_wall   = 2.4;   // front and back walls
floor_t    = 3;     // floor thickness at the low (back) end of the ramp
corner_r   = 8;     // vertical corner radius

/* [Dock grooves] */
groove_w   = 1.4;   // groove height at the bottom of the groove
groove_d   = 1.2;   // groove depth (top edge chamfered 45 deg for printing)
groove_pitch = 3.0;
frame      = 6;     // plain border around the grooved panel
lid        = true;  // print a lid
lid_t      = 3;     // lid plate thickness
lid_plug   = 4;     // plug depth into the chamber
lid_gap    = 0.3;   // plug clearance per side
dot_d      = 2;     // small indicator dimple on the front (0 = none)

/* [Fins] */
fin_d      = 3;
fin_t      = 1.2;
fin_pitch  = 3.6;
base_band  = 8;
rim_band   = 6;

/* [Details] */
window_w   = 4;     // fill-level window
feet_d     = 8.5;   // pockets for stick-on rubber feet (0 = none)
feet_depth = 0.8;

/* [Export] */
part       = "tower";  // [tower, lid, fit_test, assembly]
fit_test_h = 30;

$fn = 64;

// ---------- derived ----------
chamber_w = packet_w + 2*clearance;
chamber_d = packet_l*cos(tilt) + depth_slack;
body_w    = chamber_w + 2*side_wall;
body_d    = chamber_d + 2*end_wall;
pkt_tilt  = packet_t / cos(tilt);
plate_l   = (chamber_d - 2*plate_end_gap) / cos(tilt); // length along the slope                     // vertical height per packet
slot_h    = slot_perp / cos(tilt);                    // vertical slot opening

function ramp_z(y) = floor_t + (chamber_d/2 - y) * tan(tilt);

front_edge_y = chamber_d/2 - packet_l*cos(tilt);      // bottom packet's front edge
front_lift   = ramp_z(front_edge_y) - pocket_floor;   // finger gap under it
stack_top    = ramp_z(front_edge_y) + count*pkt_tilt; // highest point of a full stack
plug         = (style == "dock" && lid) ? lid_plug : 0;
plate_vert   = weight_plate ? plate_t / cos(tilt) : 0;  // vertical room the plate takes
body_h       = stack_top + plate_vert + top_slack + plug;  // flat top of the body
capacity     = floor((body_h - plug - top_slack - plate_vert - ramp_z(front_edge_y)) / pkt_tilt + 1e-6);
outer_w      = body_w + (style == "fins" ? 2*fin_d : 0);
outer_d      = body_d + (style == "fins" ? 2*fin_d : 0);
total_h      = body_h + ((style == "dock" && lid) ? lid_t : 0);

echo(str("Outer size: ", outer_w, " x ", outer_d, " x ", total_h, " mm",
         (style == "dock" && lid) ? " (with lid)" : ""));
echo(str("Capacity: ", capacity, " packets"));
echo(str("Front lift (finger gap): ", front_lift, " mm"));
echo(str("Slot height: ", slot_h, " mm  (one packet = ", pkt_tilt, " mm)"));

// ---------- checks ----------
assert(slot_h > pkt_tilt && slot_h < 2*pkt_tilt, "slot must pass one packet but not two");
assert(front_lift >= 12, "not enough finger room under the bottom packet");
assert(chamber_d >= packet_l*cos(tilt) + 2, "chamber too shallow for tilted packets");
assert(capacity >= count, "chamber too short for the packet count");
assert(groove_d < side_wall - 1.5, "grooves too deep for the side wall");
assert(!weight_plate || plate_l*cos(tilt) <= chamber_d - 2,
       "weight plate too long for the chamber");
assert(!weight_plate || plate_t > 2*slot_h, "weight plate must not fit through the slot");

// ---------- helpers ----------
module rr(w, l, r) offset(r) square([w - 2*r, l - 2*r], center = true);

// Half-space above/below a plane tilted like the floor, through z0 at the back inner wall.
module tilted_halfspace(z0, above) {
    translate([0, chamber_d/2, z0]) rotate([-tilt, 0, 0])
        translate([-200, -200, above ? 0 : -400]) cube([400, 400, 400]);
}

// ---------- body ----------
module core() {
    // body with a small chamfer at the foot
    hull() {
        linear_extrude(0.01) rr(body_w - 2, body_d - 2, corner_r - 1);
        translate([0, 0, 1]) linear_extrude(body_h - 1) rr(body_w, body_d, corner_r);
    }
}

module side_grooves() {
    // recessed horizontal grooves in a framed panel on both sides
    len = body_d - 2*frame;
    for (s = [-1, 1], z = [frame : groove_pitch : body_h - frame - groove_w - groove_d])
        mirror([s < 0 ? 1 : 0, 0, 0])
            hull() {
                translate([body_w/2 - groove_d, -len/2, z]) cube([0.01, len, groove_w]);
                translate([body_w/2 + 0.5, -len/2, z]) cube([0.01, len, groove_w + groove_d + 0.5]);
            }
}

module fins() {
    for (z = [base_band + fin_d : fin_pitch : body_h - rim_band - fin_t])
        hull() {
            translate([0, 0, z - fin_d]) linear_extrude(0.01) rr(body_w, body_d, corner_r);
            translate([0, 0, z]) linear_extrude(fin_t) rr(outer_w, outer_d, corner_r + fin_d);
        }
}

module chamber() {
    intersection() {
        translate([0, 0, -1]) linear_extrude(body_h + 10) rr(chamber_w, chamber_d, 2);
        tilted_halfspace(floor_t, true);
    }
}

module pull_slot() {
    // slab parallel to the floor, through the front wall only
    intersection() {
        translate([0, chamber_d/2, floor_t]) rotate([-tilt, 0, 0])
            translate([-(chamber_w - 1)/2, -200, -0.01]) cube([chamber_w - 1, 400, slot_perp]);
        translate([-100, -100, -10]) cube([200, 100 - chamber_d/2 + 1, 300]);
    }
}

module finger_pocket() {
    intersection() {
        translate([0, -chamber_d/2 + pocket_len - 50, pocket_floor])
            linear_extrude(100) rr(pocket_w, 100, 6);
        tilted_halfspace(floor_t + 0.01, false);
    }
}

module fill_window() {
    z0 = ramp_z(-chamber_d/2) + slot_h + 6;
    z1 = body_h - 22;
    hull() for (z = [z0, z1])
        translate([0, -chamber_d/2 + 1, z]) rotate([90, 0, 0]) cylinder(d = window_w, h = 20);
}

module front_dot() {
    if (style == "dock" && dot_d > 0)
        translate([0, -body_d/2 - 1, body_h - 12]) rotate([-90, 0, 0]) cylinder(d = dot_d, h = 1.6);
}

module lid_notch() {
    // finger scallop at the back so the lid can be lifted
    if (style == "dock" && lid)
        translate([0, body_d/2, body_h]) rotate([90, 0, 0]) scale([1, 0.6, 1])
            cylinder(r = 9, h = end_wall*2 + 2, center = true);
}

module feet() {
    if (feet_d > 0) {
        fx = body_w/2 - feet_d/2 - 3;
        fy = body_d/2 - feet_d/2 - 3;
        for (x = [-fx, fx], y = [-fy, fy])
            translate([x, y, -0.01]) cylinder(d = feet_d, h = feet_depth + 0.01);
    }
}

module tower() {
    difference() {
        union() { core(); if (style == "fins") fins(); }
        if (style == "dock") side_grooves();
        chamber();
        pull_slot();
        finger_pocket();
        fill_window();
        front_dot();
        lid_notch();
        feet();
    }
}

// ---------- lid (dock style) ----------
// Modelled in place (plate on top of the body). Export flips it plug-up.
module lid_in_place() {
    translate([0, 0, body_h]) difference() {
        linear_extrude(lid_t) rr(body_w, body_d, corner_r);
        // grooves running front to back, framed
        n = floor((body_w - 2*frame) / groove_pitch);
        for (i = [0 : n - 1])
            translate([-(n - 1)*groove_pitch/2 + i*groove_pitch - groove_w/2,
                       -body_d/2 + frame, lid_t - 1])
                cube([groove_w, body_d - 2*frame, 2]);
    }
    translate([0, 0, body_h - lid_plug])
        linear_extrude(lid_plug + 0.01) difference() {
            rr(chamber_w - 2*lid_gap, chamber_d - 2*lid_gap, 2 - lid_gap);
            rr(chamber_w - 2*lid_gap - 3.2, chamber_d - 2*lid_gap - 3.2, 0.5);
        }
}

// ---------- follower weight plate ----------
// Modelled flat, tray opening up, as printed. The shear leans the ends 15 deg
// so they are vertical once the plate tilts to lie on the stack.
module plate_shear() {
    multmatrix([[1, 0, 0, 0], [0, 1, -tan(tilt), 0], [0, 0, 1, 0]]) children();
}

module weight_tray() plate_shear() weight_tray_flat();
module weight_cover() plate_shear() difference() {
    union() {
        linear_extrude(cover_t) cover_outline(cover_gap);
        // snap ridges: click into the grooves in the tray rim
        if (snap_d > 0) for (m = [0, 1]) mirror([m, 0, 0])
            translate([cover_half_w(cover_gap) - 0.1, 0, cover_t/2])
                tri_ridge(snap_len, snap_d + 0.1, 1.0);
    }
    // debossed arrow + label pointing to the front of the tower (-Y)
    translate([0, 0, cover_t - 0.6]) linear_extrude(1) {
        translate([0, -4]) polygon([[0, -14], [-7, -5], [-2.5, -5], [-2.5, 6], [2.5, 6], [2.5, -5], [7, -5]]);
        translate([0, 10]) text("FRONT", size = 5, halign = "center", valign = "center",
                                font = "Liberation Sans:style=Bold");
    }
}

module weight_tray_flat() {
    w = chamber_w - 2*plate_gap;
    difference() {
        hull() {   // 1 mm chamfer on the bottom edges so it can't catch
            linear_extrude(0.01) rr(w - 2, plate_l - 2, 1);
            translate([0, 0, 1]) linear_extrude(plate_t - 1) rr(w, plate_l, 2);
        }
        // weight cavity
        translate([0, 0, plate_floor])
            linear_extrude(plate_t) rr(w - 2*plate_wall, plate_l - 2*plate_wall, 1);
        // counterbore for the inset cover
        translate([0, 0, plate_t - cover_t])
            linear_extrude(plate_t) cover_outline(0);
        // snap grooves in the long sides of the counterbore
        if (snap_d > 0) for (m = [0, 1]) mirror([m, 0, 0])
            translate([cover_half_w(0) - 0.01, 0, plate_t - cover_t/2])
                tri_ridge(snap_len + 4, snap_d + 0.15, 1.4);
        // fingernail notch to pry the cover out
        translate([0, -plate_l/2 + plate_wall - cover_ledge, plate_t])
            rotate([0, 90, 0]) cylinder(r = cover_t + 0.4, h = 10, center = true);
    }
}

function tray_w() = chamber_w - 2*plate_gap;
function cover_half_w(gap) = (tray_w() - 2*plate_wall + 2*cover_ledge - 2*gap) / 2;

// Triangular ridge along Y, pointing +X, centred on z = 0.
module tri_ridge(len, depth, h) {
    rotate([90, 0, 0]) linear_extrude(len, center = true)
        polygon([[0, -h/2], [depth, 0], [0, h/2]]);
}
module cover_outline(gap) {
    rr(tray_w() - 2*plate_wall + 2*cover_ledge - 2*gap,
       plate_l - 2*plate_wall + 2*cover_ledge - 2*gap, 1 + cover_ledge - gap);
}

if (part == "tower") tower();
else if (part == "weight") weight_tray();
else if (part == "weight_cover") weight_cover();
else if (part == "lid") translate([0, 0, body_h + lid_t]) rotate([180, 0, 0]) lid_in_place();
else if (part == "assembly") { tower(); color("silver") lid_in_place(); }
else if (part == "fit_test")
    intersection() { tower(); translate([-100, -100, 0]) cube([200, 200, fit_test_h]); }
