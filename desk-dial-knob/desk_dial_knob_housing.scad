// Desk dial — knob + under-desk housing (#228).
// Spec: docs/superpowers/specs/2026-11-14-desk-dial-knob-housing-design.md
// Plans: docs/superpowers/plans/2026-11-14-desk-dial-knob-housing.md, …-desk-dial-round-head.md (rev 2, §7)
//
// World frame (mm): desk underside z = 0, desk front edge x = 0, x+ toward the chair, y across the
// desk (y = 0 the knob's centre plane). The desk is x <= 0, 0 <= z <= 25.
// Knob frame: z = 0 the knob floor's underside, the knob's axis +z. at_knob() maps it into the world:
// the axis becomes the 45° face normal n = [cos45, 0, sin45] (up and toward the chair).
//
// Materials: PLA (charcoal shell, rose gold accent, ivory light box) and PETG (translucent knob floor,
// black knob body, translucent diffuser) never share a print object: PETG and PLA don't fuse.
//
//   openscad --backend=manifold -o out.stl -D 'part="knob"' desk_dial_knob_housing.scad

part = "assembly";

// ── Desk ────────────────────────────────────────────────────────────────────────
desk_t      = 25;     // owner: 25 mm dark bamboo laminate
tape_t      = 1.0;    // nano gel tape between the desk and the housing's top
finger_room = 15;     // pinch grip at the top rim: knurl → desk, >= this (owner)

// ── Placement: the knob's centre on the face ───────────────────────────────────
tilt      = 45;       // the face's tilt: its normal points up and toward the chair
knob_out  = 20;       // knob centre, mm past the desk's front edge
knob_down = 29.5;     // knob centre, mm below the desk's underside
knob_gap  = 1.5;      // the knob floor's gap to the face

// ── Knob ────────────────────────────────────────────────────────────────────────
knob_d       = 40;
knob_h       = 11;
floor_t      = 1.5;   // translucent PETG floor: the glow
knurl_n      = 60;    // teeth round the rim
knurl_depth  = 0.5;
knurl_helix  = 30;    // helix angle from the axis; the two crossing helices make the diamonds
knurl_z0     = 2.5;   // the knurled band; plain 1 mm above the floor and below the top
knurl_z1     = 10;
top_chamfer  = 0.6;

// ── Shaft and D-bore (Adafruit 5880 = 377 encoder, 6 mm D-shaft) ────────────────
shaft_d      = 6.0;   // [OWNER] caliper: the shaft diameter
shaft_flat   = 4.5;   // [OWNER] caliper: flat face to the round side opposite
fit_d        = 0.20;
fit_flat     = 0.15;
bore_depth   = 7.5;   // [OWNER] must not exceed the shaft's D-flat length
bore_chamfer = 0.5;

// ── Board (5880: 25.4 sq, holes 2.54 in from each edge) and encoder ─────────────
board_w           = 25.4;
board_t           = 1.6;
board_hole_inset  = 2.54;
board_hole_d      = 2.7;    // [OWNER] caliper: M2.5 clearance assumed
led_r             = 10.4;   // NeoPixel on the board front, off the shaft (Adafruit fab print)
// [OWNER] the board's turn on its posts. 0: the NeoPixel toward the chair (+x), the pads toward the neck.
// 180: the NeoPixel toward the neck. Never ±90: the LED up or down, not sideways (owner, 2026-11-16).
// The QT sockets sit mid-edge, a quarter turn from the pads, so they're on the ±y edges
qt_plug_w   = 6.0;   // a JST SH 4-pin plug (SHR-04V-S): across the pins ...
qt_plug_t   = 3.0;   // ... its thickness, off the board's back ...
qt_plug_out = 2.5;   // ... and how far it sticks out past the board's edge, plugged in
qt_cable_w  = 4.2;   // the STEMMA QT cable's 4 × 28 AWG, side by side
board_spin  = 0;
// [OWNER] "qt": a STEMMA QT cable in a side socket, through a side pocket and round the groove on the
// cup's back. "solder": wires on the pads, down the slot on the neck side. The cup cuts only its own
wiring      = "qt";
assert(board_spin == 0 || board_spin == 180, "board_spin: 0 or 180, the LED up or down");
assert(wiring == "qt" || wiring == "solder", "wiring: \"qt\" or \"solder\"");
shaft_above_board = 22;     // [OWNER] caliper: board front → shaft tip
enc_body_h        = 6.5;    // [OWNER] caliper: board front → top of the encoder body
bushing_d         = 7;      // [OWNER] caliper: threaded bushing (0 if none)
bushing_h         = 5;      // [OWNER] caliper
board_depth       = shaft_above_board - (knob_gap + bore_depth);   // board front, behind the face's outside


// ── Housing (spec §7: a round head on a neck, a taped plate, a connector block) ───────
wall        = 2.4;    // every wall, the face included
head_d      = 56;     // the round head: an 8 mm ring round the ø40 knob
back_fillet = 2;      // the back cap's rounded edge (<= wall: no knife edge, review I5)
front_chamfer = 0.8;
neck_w      = 28;     // the neck: flush with the face, up and back to the plate
neck_t      = 13;     // its depth behind the face: 12 leaves the wire channel < 0.8 mm of wall at 30/19.5
plate_w     = 46;     // the gel-taped plate under the desk
plate_t     = 6.4;    // room for the wire channel inside it (0.8 walls)
plate_back  = -72;    // where the plate ends, toward the wall
edge_r      = 6;      // the plate's corners, seen from above: tape peels from a sharp corner
soft_r      = 2;      // the block's and the neck's outside edges
fillet      = 4;      // the inside corners where the neck and the block meet the plate (45° chamfers)
cradle_t    = 3;      // the light cup's back plate (the board's posts stand on it)
post_h      = 1.5;    // board posts: the board's back sits this far off the cup's back plate
board_back_h = 3.5;   // [OWNER] caliper: the tallest thing on the board's back (STEMMA QT sockets ~2.9, the encoder's pins)
relief      = board_back_h - post_h;   // the cup's back plate is sunk this much under the board
wire_r      = 1.95;   // the bundle: four 22 AWG pigtail leads (ø1.6) round up to ~ø3.9
wire_gap    = 4;      // behind the cup's back plate: the wires run round to the neck here
boss_r      = 24.9;   // the back cap's 3 screw bosses: just outside the light cup, which they locate
boss_d      = 4.6;
boss_l      = 8;
plug_h      = 3;      // the cup's tapered plug behind its back plate, keyed into the cap's rim (owner)
cap_press   = 0.2;    // the cap's ring stands this proud of the cup: a clamp, never a rattle
hole_clear  = 0.25;   // the diffuser's radial clearance in the face hole
diffuser_r_in  = 12;  // the band the glow needs; the diffuser is a full disc to r_out
diffuser_r_out = 21;
lip_r       = 22.5;   // the diffuser's lip behind the face, clamped by the light cup
lip_t       = 1.2;
face_hole_r = 21 + 0.25;   // = diffuser_r_out + hole_clear
accent_on   = true;   // rose gold inlay round the face opening
accent_r0   = face_hole_r;
accent_r1   = 22.6;
accent_t    = 0.6;
press_travel = 0.5;   // the encoder's push-switch travel

// ── Connector block, booster ────────────────────────────────────────────────────
// owner, 2026-11-14: a smaller connector. M8 4-pin A-coded (IP67, screw-locking): a rear-fastened
// solder-cup socket, nut OUTSIDE the wall, so the block only holds its body. The cable end takes a
// field-wireable M8 plug (screw terminals). "gx12" keeps the first choice (nut inside).
// owner, 2026-11-14 (later): no socket at all — a JST-SM 4-pin pigtail comes out of the plate's back,
// tied down under it; the pod's cable carries the other half. "m8" / "gx12" bring back a socket block.
connector   = "pigtail";
has_block   = connector != "pigtail";
channel_r   = 2.2;   // the wire channel: four 22 AWG pigtail wires
conn_hole_d = connector == "gx12" ? 12.2 : 8.2;   // the panel hole (M8 × 0.5 thread)
conn_body_d = connector == "gx12" ? 17 : 11;      // [OWNER] caliper: what sits inside (GX12: its nut)
conn_depth  = connector == "gx12" ? 20 : 16;      // [OWNER] caliper: the body + cups behind the panel
conn_flat   = 0;    // [OWNER] across-flat size if the thread has an anti-rotation flat, else 0
ltc_room    = false; // LTC4311 room under the socket. Off: it belongs at the bus's start, the pod (Adafruit's guide)
ltc_w       = 25.4; // [OWNER] caliper
ltc_l       = 17.8;
cable_d     = 4.3;  // the owner's 24/4 cable, measured
clip_channel = 4.5;
clip_opening = 3.6;
cover_gap   = 0.2;
screw_len   = 8;    // M2.5 × 8 self-tapping: cap and block cover

E = 0.01;
$fn = 96;

assert(shaft_flat < shaft_d, "the flat must be inside the shaft's circle");
assert(shaft_d + fit_d < 10 - 2.4, "the hub needs >= 1.2 mm round the bore");
assert(bore_depth < knob_h - 1.5, "the bore must stop inside the knob");
assert(board_depth >= enc_body_h + wall, "shaft too short: the encoder body would reach into the face (measure shaft_above_board)");
assert(-board_depth + enc_body_h + bushing_h <= knob_gap - 0.5, "shaft too short: the bushing would hit the knob (measure shaft_above_board / bushing_h)");

// ── Knob ────────────────────────────────────────────────────────────────────────
module d_profile(d, flat) {   // a D: circle d, flat at `flat` from the round side, flat on +x
    intersection() { circle(d = d); translate([-d / 2, -d / 2]) square([flat, d]); }
}

module d_bore() {             // knob frame, mouth at z = 0
    D = shaft_d + fit_d;
    F = shaft_flat + fit_flat;
    translate([0, 0, -E]) {
        linear_extrude(bore_depth + E) d_profile(D, F);
        hull() {              // lead-in that keeps the D
            linear_extrude(E) offset(delta = bore_chamfer) d_profile(D, F);
            translate([0, 0, bore_chamfer]) linear_extrude(E) d_profile(D, F);
        }
    }
}

// Diamond knurl as ONE polyhedron, watertight by construction (review: two counter-twisted
// extrusions left T-junctions that Bambu Studio flagged as non-manifold). A ring of 2·knurl_n points
// per row, alternating crest (r = R) and root (r = R - depth), each row shifted by one: every quad is
// split along its crest-to-crest diagonal, so the crests run as ridges at ±knurl_helix → diamonds.
module knurl_band() {
    R  = knob_d / 2;
    n  = 2 * knurl_n;
    h  = knurl_z1 - knurl_z0;
    m  = max(2, round(h / ((2 * PI * R / n) / tan(knurl_helix))));
    pr = function(i, j) let(a = 360 * i / n, rr = (i + j) % 2 == 0 ? R : R - knurl_depth)
                        [rr * cos(a), rr * sin(a), knurl_z0 + h * j / m];
    pts = concat([for (j = [0 : m], i = [0 : n - 1]) pr(i, j)],
                 [[0, 0, knurl_z0], [0, 0, knurl_z1]]);
    id  = function(i, j) j * n + (i % n);
    cb  = (m + 1) * n;
    side = [for (j = [0 : m - 1], i = [0 : n - 1]) each
        (i + j) % 2 == 0
            ? [[id(i, j), id(i, j + 1), id(i + 1, j + 1)], [id(i, j), id(i + 1, j + 1), id(i + 1, j)]]
            : [[id(i, j), id(i, j + 1), id(i + 1, j)], [id(i, j + 1), id(i + 1, j + 1), id(i + 1, j)]]];
    caps = concat([for (i = [0 : n - 1]) [cb, id(i, 0), id(i + 1, 0)]],
                  [for (i = [0 : n - 1]) [cb + 1, id(i + 1, m), id(i, m)]]);
    polyhedron(points = pts, faces = concat(side, caps), convexity = 4);
}

module knob_body() {
    R = knob_d / 2;
    difference() {
        union() {
            translate([0, 0, floor_t]) cylinder(r = R, h = knurl_z0 - floor_t + E);
            knurl_band();
            translate([0, 0, knurl_z1 - E]) cylinder(r = R, h = knob_h - top_chamfer - knurl_z1 + E);
            translate([0, 0, knob_h - top_chamfer]) cylinder(r1 = R, r2 = R - top_chamfer, h = top_chamfer);
        }
        d_bore();
    }
}

module knob_floor() { difference() { cylinder(d = knob_d, h = floor_t); d_bore(); } }
module knob()       { knob_floor(); knob_body(); }

// ── Snap-together knob (owner, 2026-11-15) ─────────────────────────────────────
// The clear PETG floor and a charcoal PLA body, printed apart and snapped. The joint is a hub round the
// shaft (r <= 6), inside the dark centre: the glow enters the floor's underside at r 12-21 and shows at its
// edge, so the floor stays a plain disc out there. The shaft runs through the PETG hub (springy, it grips
// the D), and the hub's outside is a D too, so the body turns it. Slits let the barb flex in; once the
// shaft is in, the fingers can't, so the knob can't come apart on the shaft.
hub_d     = 11;
hub_flat  = 9.45;     // the hub's own D: a 2.4 mm wall on the bore's flat side too
hub_h     = 5;        // above the floor
barb      = 0.35;     // the barb's radial step
barb_h    = 0.6;      // its straight catch band, under a 45° lead-in of `barb`
snap_clear = 0.15;    // the pocket's clearance round the hub
slit_w    = 1;
hub_top   = floor_t + hub_h;
slit_z0   = floor_t + 0.2;   // the slits run almost to the floor: long fingers bend gently
// bending strain of a finger pushed in by (barb - clearance): 3·t·δ / (2·L²). PETG yields at ~4 %
snap_strain = 3 * ((hub_d - shaft_d - fit_d) / 2) * (barb - snap_clear) / (2 * pow(hub_top - slit_z0, 2));
assert(snap_strain <= 0.035, str("the snap fingers would bend ", snap_strain * 100, " %: PETG yields at ~4 %"));
z_catch   = hub_top - barb - barb_h;   // the barb's catch face = the groove's
module hub_2d(grow = 0) { offset(delta = grow) d_profile(hub_d, hub_flat); }
module snap_floor() {
    difference() {
        union() {
            cylinder(d = knob_d, h = floor_t);
            translate([0, 0, floor_t - E]) linear_extrude(hub_h + E) hub_2d();
            translate([0, 0, z_catch]) linear_extrude(barb_h) hub_2d(barb);        // the barb ...
            hull() {                                                              // ... and its lead-in
                translate([0, 0, z_catch + barb_h - E]) linear_extrude(E) hub_2d(barb);
                translate([0, 0, hub_top - E]) linear_extrude(E) hub_2d(0);
            }
        }
        d_bore();
        for (a = [45, 135]) rotate([0, 0, a])                                     // the slits: four fingers
            translate([-hub_d, -slit_w / 2, slit_z0]) cube([2 * hub_d, slit_w, hub_h]);
    }
}
module snap_pocket() {   // in the body: the hub's D + clearance, the groove the barb clicks into
    translate([0, 0, floor_t - 1]) linear_extrude(hub_h + 1 + snap_clear) hub_2d(snap_clear);
    translate([0, 0, z_catch]) linear_extrude(barb_h + barb + snap_clear) hub_2d(barb + snap_clear);
}
module snap_body() { difference() { knob_body(); snap_pocket(); } }
module snap_knob() { snap_floor(); snap_body(); }
module light_ring_zone() {   // r 8 outward, the floor and the body's underside: the glow's territory
    difference() { translate([0, 0, -1]) cylinder(r = knob_d / 2 + 1, h = floor_t + 1.5); translate([0, 0, -2]) cylinder(r = 8, h = 10); }
}

// ── Placement ───────────────────────────────────────────────────────────────────
// the face point under the knob's centre; the knob frame sits knob_gap off it along n
module at_face() { translate([knob_out, 0, -knob_down]) rotate([0, 90 - tilt, 0]) children(); }
module at_knob() { at_face() translate([0, 0, knob_gap]) children(); }

// face frame → world: the point [x, y, z] of the face frame (z = 0 the face's outside, +z = n)
a_face = 90 - tilt;
function fw(p) = [knob_out + p[0] * cos(a_face) + p[2] * sin(a_face), p[1],
                  -knob_down - p[0] * sin(a_face) + p[2] * cos(a_face)];
function face_x_at(z) = knob_out - tan(tilt) * (z + knob_down);   // the face plane at height z

module along_n(d) { translate(fw([0, 0, d]) - fw([0, 0, 0])) children(); }   // slide along the knob's axis
module inv_face() { rotate([0, -(90 - tilt), 0]) translate([-knob_out, 0, knob_down]) children(); }   // world → face frame
cup_shift = [0, 0, 0];   // probes only
module desk() { translate([-200, -200, 0]) cube([200, 400, desk_t]); }
module below_tape() { translate([-200, -200, -200]) cube([400, 400, 200 - tape_t]); }

// ── The stack behind the face (face frame) ─────────────────────────────────────
z_board_back  = -(board_depth + board_t);
z_plate_front = z_board_back - post_h;
z_plate_back  = z_plate_front - cradle_t;
z_cap_front   = z_plate_back - wire_gap;
z_head_back   = z_cap_front - wall;
head_r  = head_d / 2;
head_in = head_r - wall;
hole_xy = board_w / 2 - board_hole_inset;   // ±10.16
bushing_hole_r = bushing_d / 2 + 0.5;
box_r0 = diffuser_r_out + 0.2;     // the cup's sleeve: just outside the light path ...
box_r1 = lip_r - 0.1;              // ... and over the diffuser's lip, which it clamps
plug_r_tip = box_r1 - plug_h;      // 45°: the plug's cone runs out to the cup's edge
debug_post = 0;                    // test-only: 1 puts an opaque post in the light path
assert(boss_r - boss_d / 2 > box_r1 + 0.1, "the cap bosses would bite the light cup");
assert(boss_r + boss_d / 2 > head_in, "the cap bosses must join the head wall");
assert(back_fillet <= wall, "the cap's rounded edge would eat its wall");

// ── Head, neck, plate ──────────────────────────────────────────────────────────
// the head ends at the cap's front in a full-wall back face; the cap closes it from outside and
// carries the rounded back edge (review I5: the old r 4 fillet ate the 2.4 wall to a knife edge)
module head_profile() {
    hull() {
        translate([0, z_cap_front]) square([head_r - 0.4, -z_cap_front]);
        translate([0, z_cap_front + 0.4]) square([head_r, -z_cap_front - 0.4 - front_chamfer]);
        translate([0, -front_chamfer]) square([head_r - front_chamfer, front_chamfer]);
    }
}
module cap_profile() {
    intersection() {   // the fillet's circle would poke up into the head: clip at the cap's front
    translate([0, z_head_back]) square([head_r + 1, wall]);
    hull() {
        translate([0, z_head_back]) square([head_r - back_fillet, wall]);
        translate([head_r - back_fillet, z_head_back + back_fillet]) circle(r = back_fillet, $fn = 32);
        translate([0, z_head_back + back_fillet]) square([head_r, wall - back_fillet]);
    }
    }
}
module head_local() { rotate_extrude($fn = 160) head_profile(); }
module head_cavity_local(w = wall) { translate([0, 0, z_head_back - 1]) cylinder(r = head_r - w, h = -z_head_back + 1 - w); }

module neck_section() {   // (y, z): flush and square at the face, rounded at the back
    hull() {
        translate([-neck_w / 2, -E]) square([neck_w, E]);
        for (s = [-1, 1]) translate([s * (neck_w / 2 - 3), -neck_t + 3]) circle(r = 3, $fn = 32);
    }
}
module neck() {
    x0 = -sqrt(head_r * head_r - neck_w * neck_w / 4) + 0.5;   // starts inside the head's wall
    intersection() {
        at_face() translate([x0 - 100, 0, 0]) rotate([90, 0, 90]) linear_extrude(100) neck_section();
        below_tape();
    }
}

plate_front = min(face_x_at(-tape_t), 0);   // to the face line, never past the desk's edge
module plate_footprint(d = 0) {
    offset(delta = d) offset(r = edge_r) offset(delta = -edge_r)
        translate([plate_back, -plate_w / 2]) square([plate_front - plate_back, plate_w]);
}
module plate() {          // the tape face stays one flat rounded rectangle; its underside edge a 45° chamfer
    hull() {
        translate([0, 0, -tape_t - E]) linear_extrude(E) plate_footprint();
        translate([0, 0, -tape_t - plate_t]) linear_extrude(E)   // back and sides only: the neck lands on the front
            offset(r = edge_r - 2) offset(delta = -(edge_r - 2))
                translate([plate_back + 2, -plate_w / 2 + 2]) square([plate_front - plate_back - 2, plate_w - 4]);
    }
}
// the inside corners: the neck's back meets the plate at 45°, filled with a chamfer up to `fillet` deep
module neck_fillet() {
    zp = -tape_t - plate_t;
    xb = x_neck_back_at(zp);
    hull() {
        intersection() { neck(); translate([-200, -200, zp - fillet - 2]) cube([400, 400, fillet + 2]); }
        translate([xb - fillet - 2, -neck_w / 2 + 1, zp]) cube([fillet + 2, neck_w - 2, E]);
    }
}

module face_opening() {        // the hole for the diffuser disc, stepped behind for its lip
    at_face() {
        translate([0, 0, -wall - 1]) cylinder(r = face_hole_r, h = wall + 2);
        translate([0, 0, -wall - 1]) cylinder(r = lip_r + hole_clear, h = 1 + lip_t);
    }
}

module accent_local(over = 0) {   // over: the cutter runs past the face, the printed ring doesn't
    translate([0, 0, -accent_t]) difference() {
        cylinder(r = accent_r1, h = accent_t + over);
        // the cutter's bore runs 0.3 inside the face hole: on the hole's own radius the two facetings
        // left slivers that a slicer reads as floating
        translate([0, 0, -E]) cylinder(r = accent_r0 - (over > 0 ? 0.3 : 0), h = accent_t + 3 * E);
    }
}
module accent_ring(over = 0) { if (accent_on) at_face() accent_local(over); }

function boss_xy() = [for (a = [0, 120, 240]) boss_r * [cos(a), sin(a)]];   // 180° (the neck) left free
gusset_r = head_d / 2 - wall + 0.4;   // where the gusset lands: just inside the head wall
module cap_bosses() {
    at_face() for (p = boss_xy()) translate([p[0], p[1], z_cap_front]) difference() {
        union() {   // printed face down, the boss's end hangs: a 45° gusset leans it on the head wall
            cylinder(d = boss_d, h = boss_l);   // (a centred cone tip started 0.7 mm off the wall, in mid-air)
            hull() {
                translate([0, 0, boss_l - E]) cylinder(d = boss_d, h = E);
                translate(p / norm(p) * (gusset_r - boss_r)) translate([0, 0, boss_l + gusset_r - (boss_r - boss_d / 2)])
                    cylinder(d = 0.4, h = E);
            }
        }
        translate([0, 0, -1]) cylinder(d = 2.2, h = boss_l + 2);
    }
}

// ── Connector block (world frame): the socket faces the wall, the cover closes its bottom ─
cav_l = ltc_room ? max(30, conn_depth + 10) : max(26, conn_depth + 10);   // socket + cups, wire drop, cover screws (+ the LTC)
cav_w = ltc_room ? 29 : max(15, conn_body_d + 4);   // just the socket when there's no LTC
cav_h = ltc_room ? 27.5 : conn_body_d + 1;   // the socket + 0.5 each side (+ the LTC on posts)
blk_l = cav_l + 2 * wall;
blk_w = cav_w + 2 * wall;
z_cav_top  = -tape_t - plate_t;
z_cov_top  = z_cav_top - cav_h;
z_blk_bot  = z_cov_top - wall;
conn_z     = z_cav_top - conn_body_d / 2 - 0.5;
blk_x0     = plate_back + 3;   // in from the plate's chamfered back edge
x_cav0     = blk_x0 + wall;
function x_neck_back_at(zw) = let(u = (-knob_down + (-neck_t) * cos(a_face) - zw) / sin(a_face)) fw([u, 0, -neck_t])[0];
cov_boss   = 5;

// the block and the plate's back end as ONE extruded cross-section: separate coplanar back faces left a
// doubled seam edge (non-manifold) where the plate's underside met the block's back wall
module rbox(p0, p1, r) {   // a box with every edge rounded
    hull() for (x = [p0[0] + r, p1[0] - r], y = [p0[1] + r, p1[1] - r], z = [p0[2] + r, p1[2] - r])
        translate([x, y, z]) sphere(r = r, $fn = 24);
}
module block_solid() {
    zp = -tape_t - plate_t;
    rbox([blk_x0, -blk_w / 2, z_blk_bot], [blk_x0 + blk_l, blk_w / 2, zp + soft_r + 1], soft_r);
    hull() {   // 45° chamfers into the plate's underside, front and sides (the back stays flat: the socket)
        translate([blk_x0, -blk_w / 2, zp - fillet - 1]) cube([blk_l - soft_r, blk_w, fillet + 1]);
        translate([blk_x0, -blk_w / 2 - fillet, zp]) cube([blk_l + fillet, blk_w + 2 * fillet, E]);
    }
}
module block_cavity() { translate([x_cav0, -cav_w / 2, z_blk_bot - 1]) cube([cav_l, cav_w, z_cav_top - z_blk_bot + 1]); }
// two screws at the front corners, past the socket; the cover's back edge tabs into the back wall
function cov_boss_xy() = [for (y = [-1, 1]) [x_cav0 + cav_l - cov_boss / 2, y * (cav_w / 2 - cov_boss / 2)]];
tab_l = 1.5;
module cover_tab_pocket() { translate([x_cav0 - tab_l - 0.2, -(cav_w / 2 - 2), z_blk_bot - 1]) cube([tab_l + 0.2 + E, cav_w - 4, wall + 1 + 0.3]); }
module cover_bosses() {
    for (p = cov_boss_xy()) translate([p[0], p[1], z_cov_top]) difference() {
        translate([-cov_boss / 2, -cov_boss / 2 - (p[1] < 0 ? 0.5 : 0), 0])
            cube([cov_boss + 0.5, cov_boss + 0.5, 8]);   // run 0.5 into the walls: no coplanar seam
        translate([0, 0, -1]) cylinder(d = 2.2, h = 10);
    }
}
module conn_hole_2d() {
    if (conn_flat > 0) intersection() { circle(d = conn_hole_d); square([conn_hole_d, conn_flat], center = true); }
    else circle(d = conn_hole_d);
}
module conn_cutter() { translate([blk_x0 - 1, 0, conn_z]) rotate([0, 90, 0]) linear_extrude(wall + 2) conn_hole_2d(); }
module conn_envelope() { translate([x_cav0, 0, conn_z]) rotate([0, 90, 0]) cylinder(d = conn_body_d, h = conn_depth); }
module ltc_envelope() { translate([x_cav0 + 2, -ltc_l / 2, z_cov_top + 4]) cube([ltc_w, ltc_l, board_t + 4]); }

module block_cover() {
    if (has_block) difference() {
        union() {
            translate([x_cav0 + cover_gap, -cav_w / 2 + cover_gap, z_blk_bot]) cube([cav_l - 2 * cover_gap, cav_w - 2 * cover_gap, wall]);
            translate([x_cav0 - tab_l, -(cav_w / 2 - 2) + 0.2, z_blk_bot + 0.2]) cube([tab_l + cover_gap + E, cav_w - 4 - 0.4, wall - 0.2]);   // the tab
            if (ltc_room) for (dx = [3, ltc_w - 3]) translate([x_cav0 + 2 + dx, 0, z_cov_top - E]) cylinder(d = 4.5, h = 4 + E);
        }
        for (p = cov_boss_xy()) translate([p[0], p[1], z_blk_bot - 1]) cylinder(d = 2.7, h = wall + 2);
        if (ltc_room) for (dx = [3, ltc_w - 3]) translate([x_cav0 + 2 + dx, 0, z_cov_top - 1]) cylinder(d = 2.2, h = 6);
    }
}

// ── The wires: board pads → round the cup → down the neck → along the plate → the block ─
function wire_x_at_plate() = (-knob_down + (-8) * cos(a_face) - (-tape_t - plate_t / 2)) / sin(a_face);
x_wire_drop = x_cav0 + cav_l - 3;
// the pigtail: out of the plate's underside, under a zip-tie bar, off the plate's back end
x_pig_drop = plate_back + 18;
tie_x0     = plate_back + 4;
tie_l      = 8;
tie_drop   = 5;                       // the bar hangs this far under the plate
z_pig_run  = -tape_t - plate_t - tie_drop - wire_r - 0.1;   // the bundle runs snug under the bar
module tie_bar() {
    zp = -tape_t - plate_t;
    difference() {
        rbox([tie_x0, -6, zp - tie_drop], [tie_x0 + tie_l, 6, zp + 1], 1);
        translate([tie_x0 + (tie_l - 3.8) / 2, -10, zp - 2.4]) cube([3.8, 20, 1.8]);   // the tie's tunnel
    }
}        // past the socket's body + cups: wires bend up once (review I2)
z_wire_plate = -tape_t - plate_t / 2;
// through the head wall at face-z -8, or deeper when the head sits high (more-out placements, review I3)
function z_wire_wall() = min(-8, (z_wire_plate + knob_down + (-(head_r + 3)) * sin(a_face)) / cos(a_face));
function wire_pts() = [
    fw([-(board_w / 2 - 2.54), 0, z_plate_back - wire_gap / 2]),   // behind the cup's slot, under the pads
    fw([-(box_r1 - 2), 0, z_plate_back - wire_gap / 2]),
    fw([-(head_in - 1.2), 0, z_plate_back - wire_gap / 2]),   // in the gap between the cup and the head wall
    fw([-(head_in - 1.2), 0, -8]),
    fw([-(head_r + 3), 0, z_wire_wall()]),               // through the head wall into the neck
    [min(fw([wire_x_at_plate(), 0, -8])[0], -3), 0, z_wire_plate],   // never bend past the desk edge
    each (has_block
        ? [[x_wire_drop, 0, z_wire_plate],               // along the plate
           [x_wire_drop, 0, z_cav_top - 3]]              // down into the block
        : [[x_pig_drop, 0, z_wire_plate],                // along the plate, out of its underside,
           [x_pig_drop, 0, z_pig_run],
           [plate_back - 3, 0, z_pig_run]])];            // under the tie bar and off the back
module wire_chain(r, upto = 0) {   // upto > 0: only the first `upto` points (the enclosed run)
    p = upto > 0 ? [for (i = [0 : upto - 1]) wire_pts()[i]] : wire_pts();
    for (i = [0 : len(p) - 2]) hull() { translate(p[i]) sphere(r = r, $fn = 16); translate(p[i + 1]) sphere(r = r, $fn = 16); }
}
module wire_path() {                       // the probe: the ø3.9 bundle, plus the pads → slot stretch (thin)
    wire_chain(wire_r);                    // (the QT cable's own run, side pockets + groove: qt_plug_side)
    if (wiring == "solder") hull() { at_face() translate([-(board_w / 2 - 2.54), 0, (z_board_back + z_plate_front) / 2]) sphere(r = 0.6, $fn = 12);
             translate(wire_pts()[0]) sphere(r = 0.6, $fn = 12); }
}

// ── The body: one charcoal print, face down ────────────────────────────────────
module body() {
    difference() {
        union() { at_face() head_local(); neck(); neck_fillet(); plate(); if (has_block) block_solid(); else tie_bar(); }
        at_face() head_cavity_local();
        if (has_block) { block_cavity(); cover_tab_pocket(); conn_cutter(); }
        face_opening();
        accent_ring(E);
        wire_chain(channel_r);
    }
    cap_bosses();
    if (has_block) cover_bosses();
}
// face down on the bed: undo at_face, then turn over
module body_print() { rotate([180, 0, 0]) rotate([0, -a_face, 0]) translate([-knob_out, 0, knob_down]) children(); }

module tape_face() { intersection() { body(); translate([-200, -200, -tape_t - 0.2]) cube([400, 400, 0.2]); } }
module finger_envelope() { at_knob() cylinder(r = knob_d / 2 + finger_room, h = knob_h, $fn = 192); }

// ── Light path: diffuser disc + ivory light cup (face frame) ───────────────────
module diffuser_local(grow = 0) {
    difference() {
        union() {
            translate([0, 0, -wall + lip_t]) cylinder(r = diffuser_r_out + grow, h = wall - lip_t);
            translate([0, 0, -wall]) cylinder(r = lip_r + grow, h = lip_t);
        }
        translate([0, 0, -wall - 1]) cylinder(r = bushing_hole_r, h = wall + 2);
    }
}
module diffuser_ring() { at_face() diffuser_local(); }

module board_local() {
    translate([-board_w / 2, -board_w / 2, z_board_back]) cube([board_w, board_w, board_t]);
    translate([0, 0, -board_depth]) {
        rotate([0, 0, 45]) translate([-6.2, -6.2, 0]) cube([12.4, 12.4, enc_body_h]);   // EC11 body
        translate([0, 0, enc_body_h]) cylinder(d = bushing_d, h = bushing_h);
        translate([0, 0, enc_body_h]) linear_extrude(shaft_above_board - enc_body_h) d_profile(shaft_d, shaft_flat);
    }
    led_local();
}
// the NeoPixel: on the board's front, the edge opposite the pads (Adafruit's board file), toward the chair (+x)
module led_local() { rotate([0, 0, board_spin]) translate([led_r - 1.75, -1.75, -board_depth]) cube([3.5, 3.5, 1]); }
module board_envelope() { at_face() board_local(); }
// the four wired pads (3V, GND, SCL, SDA: the middle four of six, 0.1" pitch) on the edge facing the neck
pad_xy = [for (y = [-3.81, -1.27, 1.27, 3.81]) [-(board_w / 2 - 2.54), y]];
module pad_leads() {   // a ø1.6 lead straight back from each pad, through the cup to behind its plug
    at_face() rotate([0, 0, board_spin]) for (p = pad_xy) translate([p[0], p[1], z_plug_tip - 1]) cylinder(d = 1.6, h = z_board_back - z_plug_tip + 1, $fn = 16);
}
module board_back_envelope() {   // what stands off the board's back, the posts' footprints excepted
    at_face() translate([0, 0, z_board_back - board_back_h]) linear_extrude(board_back_h) difference() {
        square(board_w, center = true);
        for (x = [-1, 1], y = [-1, 1]) translate([x * hole_xy, y * hole_xy]) circle(d = 5.5);
    }
}

// a STEMMA QT plug in the socket on the neck edge (board_spin 90): the socket's mouth is 0.45 in from the
// edge (Adafruit's board file), the plug sticks out past it under the plate's front, and its cable bends
// straight back through the cup into the wires' groove (owner, 2026-11-16: hand-cut on the first print)
qt_mouth_x = -(board_w / 2 - 0.45);
module qt_plug_local() {
    translate([qt_mouth_x - qt_plug_out, -qt_plug_w / 2, z_board_back - qt_plug_t]) cube([qt_plug_out + 1.5, qt_plug_w, qt_plug_t]);
    hull() {   // the cable: out of the plug's back, a tight bend, straight down to the groove's middle
        translate([qt_mouth_x - qt_plug_out - 1.2, -qt_cable_w / 2, z_board_back - qt_plug_t + 0.6]) cube([1.2, qt_cable_w, 1.8]);
        translate([qt_mouth_x - qt_plug_out - 1.2, -qt_cable_w / 2, z_plate_back - wire_gap / 2]) cube([1.2, qt_cable_w, E]);
    }
}
qt_hole = [qt_mouth_x - qt_plug_out - 2.2, qt_mouth_x + 0.6];   // x span of the plug's pocket and the cable's hole
// the side sockets' cable: the four 28 AWG wires bundled 2 × 2 (~2.0 sq) in a T in the plug's face (the
// owner's sketch, 2026-11-16): straight across the middle between the side holes, then straight up the
// middle into the neck groove, in the same teardrop as the neck groove.
// The groove round the rim printed as spaghetti twice: keep it straight
qt_bar_l  = 33;         // across: into both side holes (y 11.65 → 16.95)
qt_stem_x = -11.5;      // up the middle to here, inside the neck groove (it starts at x -10.16)
// every wire groove in the cup has one shape (owner, 2026-11-16): the neck channel's ø4.5 round bottom with
// 45° flanks up to a 1.8 flat cap, a teardrop that prints plug down (the cap is a short bridge)
module groove_profile() {   // 2D: (across, z)
    r = channel_r + 0.05; zc = z_plate_back - wire_gap / 2; t = r * (sqrt(2) - 1);
    hull() { translate([0, zc]) circle(r = r, $fn = 48); translate([-t, zc + r - E]) square([2 * t, E]); }
}
module qt_t(along_y_l, stem_x) {   // the bar along y (centred), the stem along -x from just past the centre
    rotate([90, 0, 0]) linear_extrude(along_y_l, center = true) children();
    translate([stem_x, 0, 0]) rotate([0, 0, 90]) rotate([90, 0, 0]) linear_extrude(-stem_x + 1.5) children();
}
module qt_groove_local() { qt_t(qt_bar_l, qt_stem_x) groove_profile(); }
// the neck groove's stretch through the cup: the round channel's crown would be a 4.4 bridge, so the cup cuts
// the teardrop round it; the body and cap keep the round channel
module neck_groove_roof_local() {
    x0 = -(head_in - 1.2); x1 = -(board_w / 2 - 2.54) + channel_r + 0.1;   // covers the channel's round end
    translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) groove_profile();   // 2D (y, z), along x
}
module qt_hole_cut() {
    translate([qt_hole[0], -(qt_plug_w / 2 + 0.5), z_plate_back - plug_h - 1])
        linear_extrude(plug_h + cradle_t + 2) offset(r = 1) offset(delta = -1)
            square([qt_hole[1] - qt_hole[0], qt_plug_w + 1]);
}
module qt_plug_side_local() {   // both side plugs, their drops, and the cables lying flat in the groove
    for (a = [-90, 90]) rotate([0, 0, a]) qt_plug_local();
    qt_t(32, qt_stem_x + 0.5) translate([-1, z_plug_tip - 0.6]) square([2, 2]);   // the 2 × 2 bundle
}
module cup_screw_holes() {   // M2.5 from the front: the screw ends at the plate's back, the hole just past it
    for (x = [-1, 1], y = [-1, 1]) translate([x * hole_xy, y * hole_xy, z_plate_back - 0.3]) cylinder(d = 2.2, h = cradle_t + post_h + 2);
}

// the old sleeve + cradle in one ivory cup: the sleeve clamps the diffuser's lip, the board stands on
// its back plate's posts (M2.5 from the front), wires leave through the slot behind the pad edge
module light_cup_local(grow = 0) {
    difference() {
        union() {
            translate([0, 0, z_plate_front - E]) difference() {
                cylinder(r = box_r1 + grow, h = -z_plate_front - wall + E);
                translate([0, 0, -1]) cylinder(r = box_r0, h = -z_plate_front + 2);
            }
            difference() {   // the back plate, with a relief under the board for what stands off its back
                translate([0, 0, z_plate_back]) cylinder(r = box_r1 + grow, h = cradle_t);
                translate([0, 0, z_plate_front - relief]) linear_extrude(relief + 1) offset(r = 1) offset(delta = -1)
                    square(board_w + 1, center = true);
            }
            for (x = [-1, 1], y = [-1, 1]) translate([x * hole_xy, y * hole_xy, z_plate_front - relief - E])
                cylinder(d = 4.5, h = relief + post_h + E);   // the posts rise from the relief's floor
            // the plug: a 45° cone behind the back plate that seats in the cap's rim. Printed plug down, the
            // cone is its own support, and clamped it centres the cup with no play
            translate([0, 0, z_plate_back - plug_h]) cylinder(r1 = plug_r_tip + grow, r2 = box_r1 + grow, h = plug_h + E);
        }
        cup_screw_holes();
        // the slot under the four wired pads (pads at x -10.16, y ±3.81 ± 0.9): the leads drop straight through
        if (wiring == "solder") rotate([0, 0, board_spin])
            translate([-board_w / 2 + 2.54 - 1.7, -5, z_plate_back - plug_h - 1]) cube([3.4, 10, plug_h + cradle_t + 2]);
        // a QT plug's pocket and its cable's way out at each side edge, right through the plate and the plug
        // (a vertical wall, so nothing to support either way up), and the groove round the back to the neck
        if (wiring == "qt") { for (a = [-90, 90]) rotate([0, 0, a]) qt_hole_cut(); qt_groove_local(); }
        neck_groove_roof_local();
    }
}
module light_cup() { difference() { at_face() light_cup_local(); wire_chain(channel_r, 3); } }   // the wires' groove through the plug

// the back cap: a disc in the head's open back, a standoff ring that bears on the cup's back plate
z_plug_tip = z_plate_back - plug_h;
function seat_r(z) = plug_r_tip + (z - z_plug_tip) - cap_press;   // the plug's cone, cap_press forward
z_seat_top = z_plug_tip + cap_press + (box_r1 - 0.8 - plug_r_tip);    // a 0.6 flat top on the rim
module back_cap_local() {
    difference() {
        union() {
            rotate_extrude($fn = 160) cap_profile();
            // the rim: a 45° seat for the cup's plug, cap_press forward of touching, so the screws clamp the
            // cup in the cone: centred and pressed onto the diffuser's lip, no rattle (review I7, owner)
            rotate_extrude($fn = 160) polygon([
                [seat_r(z_cap_front - E), z_cap_front - E], [box_r1 - 0.2, z_cap_front - E],
                [box_r1 - 0.2, z_seat_top], [seat_r(z_seat_top), z_seat_top]]);
        }
        for (p = boss_xy()) translate([p[0], p[1], z_head_back - 1]) cylinder(d = 2.7, h = wall + 2);
    }
}
module back_cap() { difference() { at_face() back_cap_local(); wire_chain(channel_r); } }

module light_path() {
    at_face() translate([0, 0, -board_depth]) difference() {
        cylinder(r = diffuser_r_out, h = board_depth);
        translate([0, 0, -1]) cylinder(r = diffuser_r_in, h = board_depth + 2);
    }
}
module opaque() {
    body(); accent_ring(); light_cup(); back_cap();
    if (debug_post) at_face() translate([16, 0, -board_depth]) cylinder(r = 1.5, h = board_depth - wall);
}
module cap_screws() { at_face() for (p = boss_xy()) translate([p[0], p[1], z_head_back]) cylinder(d = 2.5, h = screw_len); }


// ── Review probes (rev 2) ───────────────────────────────────────────────────────
board_screw_len = 6;   // M2.5 × 6 from the front, through the board into the cup's posts
module board_screws(heads = true, shanks = true) {
    at_face() for (x = [-1, 1], y = [-1, 1]) translate([x * hole_xy, y * hole_xy, -board_depth]) {
        if (heads)  cylinder(d = 4.5, h = 1.7);
        if (shanks) translate([0, 0, -board_screw_len]) cylinder(d = 2.5, h = board_screw_len);
    }
}
module body_outline() { at_face() { head_local(); rotate_extrude($fn = 160) cap_profile(); } neck(); neck_fillet(); plate(); if (has_block) block_solid(); else tie_bar(); }
z_body_back = z_cap_front;
module cap_hole_cyls() { at_face() for (p = boss_xy()) translate([p[0], p[1], z_head_back]) cylinder(d = 2.7, h = wall); }
cap_r = head_r;

// ── Cable clip ──────────────────────────────────────────────────────────────────
module cable_clip() {                       // gel-taped saddle on the desk underside, ~5 cm behind the socket
    difference() {
        union() {
            translate([-10, -7.5, 0]) cube([20, 15, 2]);
            translate([-10, 0, 2 + clip_channel / 2]) rotate([0, 90, 0]) cylinder(d = clip_channel + 3.2, h = 20);
            translate([-10, -(clip_channel + 3.2) / 2, 0]) cube([20, clip_channel + 3.2, 2 + clip_channel / 2]);
        }
        translate([-11, 0, 2 + clip_channel / 2]) rotate([0, 90, 0]) cylinder(d = clip_channel, h = 22);
        translate([-11, -clip_opening / 2, 2 + clip_channel / 2]) cube([22, clip_opening, 10]);
    }
}
module clip_cable(lift = 0) { translate([-15, 0, 2 + clip_channel / 2 + lift]) rotate([0, 90, 0]) cylinder(d = cable_d, h = 30); }

// ── Mock-up: the body's outline, 1.2 mm walls, no bosses or channel — a quick fit test ─
module mockup() {
    difference() {
        union() { at_face() rotate_extrude($fn = 160) union() { head_profile(); cap_profile(); } neck(); neck_fillet(); plate(); if (has_block) block_solid(); else tie_bar(); }
        at_face() head_cavity_local(1.2);
        if (has_block) translate([blk_x0 + 1.2, -blk_w / 2 + 1.2, z_blk_bot - 1]) cube([blk_l - 2.4, blk_w - 2.4, z_cav_top - z_blk_bot + 1]);
        face_opening();
    }
}

// ── Parts ───────────────────────────────────────────────────────────────────────
if      (part == "desk")              desk();
else if (part == "body")              body();
else if (part == "body_print")        body_print() body();
else if (part == "accent_ring")       accent_ring();
else if (part == "accent_ring_print") body_print() accent_ring();
else if (part == "accent_x_body")     intersection() { accent_ring(); body(); }
else if (part == "accent_x_body_print") intersection() { body_print() accent_ring(); body_print() body(); }
else if (part == "head_on_face")      head_local();
else if (part == "body_x_desk")       intersection() { union() { body(); accent_ring(); } desk(); }
else if (part == "knob_x_desk")       intersection() { at_knob() knob(); desk(); }
else if (part == "finger_x_desk")     intersection() { finger_envelope(); desk(); }
else if (part == "finger_x_body")     intersection() { finger_envelope(); union() { body(); accent_ring(); } }
else if (part == "knob_x_body")       intersection() { at_knob() knob(); union() { body(); accent_ring(); } }
else if (part == "knob_pressed_x_body")
    intersection() { at_face() translate([0, 0, knob_gap - press_travel]) knob(); union() { body(); accent_ring(); } }
else if (part == "tape_face")         tape_face();
else if (part == "diffuser_ring")     diffuser_ring();
else if (part == "diffuser_ring_print") translate([0, 0, wall]) diffuser_local();   // lip on the bed
else if (part == "diffuser_x_body")   intersection() { diffuser_ring(); union() { body(); accent_ring(); } }
else if (part == "diffuser_x_cup")    intersection() { diffuser_ring(); light_cup(); }
else if (part == "diffuser_grown_x_body") intersection() { at_face() diffuser_local(0.2); body(); }
else if (part == "diffuser_lip_x_front_wall")   // the lip pushed out the front by its own thickness hits the face
    intersection() { at_face() translate([0, 0, lip_t]) intersection() { diffuser_local(); translate([0, 0, -wall]) difference() { cylinder(r = lip_r, h = lip_t); translate([0, 0, -1]) cylinder(r = diffuser_r_out, h = lip_t + 2); } } body(); }
else if (part == "accent_on_face")    { if (accent_on) accent_local(); }
else if (part == "face_hole_on_face") cylinder(r = face_hole_r, h = 1);
else if (part == "light_path_x_opaque") intersection() { light_path(); opaque(); }
else if (part == "board_on_face")     board_local();
else if (part == "knob_on_face")      translate([0, 0, knob_gap]) knob();
else if (part == "board_envelope")    board_envelope();
else if (part == "board_x_everything")
    intersection() { board_envelope(); union() { body(); accent_ring(); light_cup(); diffuser_ring(); back_cap(); at_knob() knob(); } }
else if (part == "light_cup")         light_cup();
else if (part == "light_cup_print")   translate([0, 0, -(z_plate_back - plug_h)]) difference() { light_cup_local(); inv_face() wire_chain(channel_r, 3); }   // plug down
else if (part == "cup_x_body")        intersection() { light_cup(); body(); }
else if (part == "cup_grown_x_body")  intersection() { at_face() light_cup_local(0.3); body(); }
else if (part == "stack_sweep_x_body")
    intersection() { at_face() for (d = [0 : 1 : 30]) translate([0, 0, -d]) { light_cup_local(); board_local(); } body(); }
else if (part == "back_cap")          back_cap();
else if (part == "back_cap_print")    translate([0, 0, -z_head_back]) difference() { back_cap_local(); inv_face() wire_chain(channel_r); }   // with the wires' notch
else if (part == "cap_x_body")        intersection() { back_cap(); body(); }
else if (part == "led_on_face")       led_local();
else if (part == "pad_leads")         pad_leads();
else if (part == "cup_at_neck_slot")  intersection() { light_cup(); at_face() translate([-10.5, -0.5, z_plate_back + 0.1]) cube([1, 1, 0.7]); }
else if (part == "qt_plug_side")      at_face() qt_plug_side_local();
else if (part == "qt_plug_side_x_cup") intersection() { at_face() qt_plug_side_local(); light_cup(); }
else if (part == "qt_plug_side_x_cap") intersection() { at_face() qt_plug_side_local(); along_n(-cap_press) back_cap(); }
else if (part == "qt_groove")         at_face() qt_groove_local();
else if (part == "qt_groove_centre")  intersection() { at_face() qt_groove_local(); at_face() translate([-0.5, -0.5, z_plug_tip]) cube(1); }
else if (part == "neck_roof")         neck_groove_roof_local();
else if (part == "qt_bar_section")    intersection() { qt_groove_local(); translate([-5, 6, -60]) cube([10, 0.1, 60]); }    // face frame
else if (part == "neck_section")      intersection() { neck_groove_roof_local(); translate([-16, -5, -60]) cube([0.1, 10, 60]); }
else if (part == "qt_groove_stem")    intersection() { at_face() qt_groove_local(); at_face() translate([-5.5, -0.5, z_plug_tip]) cube(1); }
else if (part == "qt_groove_rim")     intersection() { at_face() qt_groove_local();
                                          at_face() for (a = [135, 225]) rotate([0, 0, a]) translate([17, -0.5, z_plug_tip]) cube(1); }
else if (part == "qt_groove_x_screw_holes") intersection() { qt_groove_local(); cup_screw_holes(); }
else if (part == "pad_leads_x_cup")   intersection() { pad_leads(); light_cup(); }
else if (part == "board_back_envelope") board_back_envelope();
else if (part == "board_back_x_cup")  intersection() { board_back_envelope(); light_cup(); }
else if (part == "cap_x_cup")         intersection() { back_cap(); light_cup(); }
else if (part == "cap_seated_x_cup")  intersection() { along_n(-cap_press) back_cap(); light_cup(); }
else if (part == "cap_seated_x_cup_shifted")
    intersection() { along_n(-cap_press) back_cap(); translate(fw(cup_shift) - fw([0, 0, 0])) light_cup(); }
else if (part == "cap_screws")        cap_screws();
else if (part == "cap_screws_x_light") intersection() { cap_screws(); union() { light_cup(); light_path(); } }
else if (part == "wire_path")         wire_path();
else if (part == "wire_x_solids")     intersection() { wire_path(); union() { body(); light_cup(); back_cap(); } }
else if (part == "conn_hole")         intersection() { conn_cutter(); translate([blk_x0, -50, -100]) cube([wall, 100, 100]); }
else if (part == "conn_x_everything") intersection() { conn_envelope(); union() { body(); block_cover(); if (ltc_room) ltc_envelope(); } }
else if (part == "ltc_x_everything")  intersection() { ltc_envelope(); union() { body(); block_cover(); conn_envelope(); } }
else if (part == "block_cover")       block_cover();
else if (part == "block_cover_print") translate([0, 0, -z_blk_bot]) block_cover();
else if (part == "cover_x_body")      intersection() { block_cover(); body(); }
else if (part == "cable_clip" || part == "cable_clip_print") cable_clip();
else if (part == "cable_x_clip")      intersection() { cable_clip(); clip_cable(); }
else if (part == "cable_lifted_x_clip") intersection() { cable_clip(); clip_cable(clip_channel); }
else if (part == "mockup_print")      body_print() mockup();
else if (part == "outline_print")     body_print() { body(); back_cap(); }
else if (part == "knob")              knob();
else if (part == "knob_body" || part == "knob_body_print")   knob_body();
else if (part == "knob_floor" || part == "knob_floor_print") knob_floor();
else if (part == "knob_floor_x_body") intersection() { knob_floor(); knob_body(); }
else if (part == "preview")           { color("#222") at_knob() knob(); color("#3a3b40") body(); color("#c9907a") accent_ring(); color("#9fe8ff") diffuser_ring(); color("#3a3b40") block_cover(); color("#b33", 0.9) wire_path(); color("#7a5230", 0.25) translate([-80, -40, 0]) cube([80, 80, 3]); }
else if (part == "board_screws_bite_cup") intersection() { board_screws(false, true); light_cup(); }
else if (part == "board_pulled_x_screw_heads")
    intersection() { at_face() translate([-board_w / 2, -board_w / 2, z_board_back + 0.3]) cube([board_w, board_w, board_t]); board_screws(true, false); }
else if (part == "wire_x_socket_zone") intersection() { wire_path(); translate([x_cav0, -cav_w / 2, z_cov_top]) cube([conn_depth + 5, cav_w, cav_h]); }
else if (part == "channel_wall_breach") difference() { wire_chain(channel_r + 0.8, has_block ? 0 : len(wire_pts()) - 2); body_outline(); }   // the pigtail leaves the plate on purpose
else if (part == "cap_hole_breakout") difference() { cap_hole_cyls(); at_face() translate([0, 0, z_head_back - 1]) cylinder(r = cap_r, h = wall + 2); }
else if (part == "head_back_face")    rotate([0, -a_face, 0]) translate([-knob_out, 0, knob_down]) intersection() { body(); at_face() translate([0, 0, z_body_back]) difference() { cylinder(r = 40, h = 0.1); translate([0, 0, -1]) cylinder(r = 25.5, h = 2); } }
else if (part == "ltc_posts")         { if (ltc_room) intersection() { block_cover(); translate([-200, -200, z_cov_top]) cube([400, 400, 10]); } }
else if (part == "tape_corner_probe")
    intersection() { body(); for (x = [plate_back + 0.3, plate_front - 1.3], y = [-1, 1]) translate([x, y * (plate_w / 2 - 0.65) - 0.35, -tape_t - 0.4]) cube([1, 0.7, 0.3]); }
else if (part == "block_edge_probe")
    intersection() { body(); translate([blk_x0 + blk_l - 0.6, blk_w / 2 - 0.6, z_blk_bot]) cube([0.5, 0.5, 0.5]); }
else if (part == "neck_corner_probe") intersection() { body(); translate([x_neck_back_at(-tape_t - plate_t) - 1.5, -1, -tape_t - plate_t - 0.9]) cube([0.5, 2, 0.5]); }
else if (part == "block_corner_probe") intersection() { body(); translate([blk_x0 + blk_l + 0.5, -1, -tape_t - plate_t - 0.9]) cube([0.5, 2, 0.5]); }
else if (part == "block_below_plate") intersection() { body(); translate([blk_x0 - 1, -50, -100]) cube([blk_l + 1, 100, 100 - tape_t - plate_t - fillet - 1 - E]); }   // under the chamfer into the plate
else if (part == "tie_bar")           { if (!has_block) tie_bar(); }
else if (part == "tie_x_wires")       { if (!has_block) intersection() { tie_bar(); wire_path(); } }
else if (part == "tie_slot_open")     { if (!has_block) intersection() { tie_bar(); translate([tie_x0 + (tie_l - 3.6) / 2, -30, -tape_t - plate_t - 2.3]) cube([3.6, 60, 1.6]); } }
else if (part == "snap_floor")        snap_floor();
else if (part == "snap_body")         snap_body();
else if (part == "snap_knob")         snap_knob();
else if (part == "snap_floor_x_light_ring")   // anything in the floor out there that a plain disc doesn't have
    intersection() { difference() { snap_floor(); cylinder(d = knob_d, h = floor_t); } light_ring_zone(); }
else if (part == "snap_body_x_light_ring")    // the body's underside out there must be the fused knob's
    intersection() { difference() { knob_body(); snap_body(); } light_ring_zone(); }
else if (part == "snap_floor_x_body") intersection() { snap_floor(); snap_body(); }
else if (part == "snap_floor_pulled_x_body") intersection() { translate([0, 0, -0.6]) snap_floor(); snap_body(); }
else if (part == "snap_floor_turned_x_body") intersection() { rotate([0, 0, 5]) snap_floor(); snap_body(); }
else if (part == "shaft_x_snap_knob") intersection() { translate([0, 0, -5]) linear_extrude(5 + bore_depth) d_profile(shaft_d, shaft_flat); snap_knob(); }
else if (part == "mockup_knob_floor_print") snap_floor();                                              // floor down
else if (part == "mockup_knob_body_print")  translate([0, 0, knob_h]) rotate([180, 0, 0]) snap_body();   // top down: the plate's matte finish
else if (part == "snap_cut")          // a picture: the two halves cut in half, pulled 4 mm apart
    difference() { union() { color("#7fd8e8", 0.85) snap_floor(); color("#3a3b40") translate([0, 0, 4]) snap_body(); } translate([-30, 0, -10]) cube([60, 30, 40]); }
else if (part == "assembly")          { at_knob() knob(); body(); accent_ring(); diffuser_ring(); light_cup(); back_cap(); block_cover(); %board_envelope(); %conn_envelope(); if (ltc_room) %ltc_envelope(); %desk(); }
else if (part == "none") {}   // render.scad draws its own dressed views
else assert(false, str("unknown part: ", part));
