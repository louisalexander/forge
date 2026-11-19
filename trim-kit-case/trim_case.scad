// Trimming-kit case v5: the v4 deburr case (deburr_case.scad) rebuilt from primitives,
// bigger and roomier, with larger bevels. Design: docs/2026-11-18-roomy-rebuild-design.md
//
// Frames
//   closed (body) frame: z = 0 is the body's bottom (bed face), z = H the lid's back.
//                        Hinge at +x, latch at -x.
//   lid frame:           the lid as printed. z = 0 is its back (bed face), hinge at -x.
//   closed lid = to_closed(lid()): (x, y, z) -> (-x, y, H - z). to_lid() is the same map.
//
// part = "body" | "lid" | "closed" | "assembly" | "posed" | "swing_check" | "closed_check" |
//        "snap_test" | "clip_test" | "hinge_test_body" | "hinge_test_lid" | "inlays" | "body_inlays" | "section"

part = "assembly";
show_tools = true;
swing_a = 0;
$fn = 64;

// ---------- Overall ----------
H        = 28;       // closed height
P        = 11;       // parting plane, lid frame (closed z = H - P = 17)
Pc       = H - P;
W        = 84;       // body outer width
wall     = 3;        // body side walls
gap_side = 0.25;     // lid side face to body wall
Wi       = W/2 - wall;                 // body inner half-width (39)
Wl       = Wi - gap_side;              // lid outer half-width (38.75)
lid_wall = 2.5;
Wt       = Wl - lid_wall;              // lid tray inner half-width (36.25)
floor_t  = 2.5;      // body floor
back_t   = 2.5;      // lid back
tray_z   = 3;        // lid tray floor top (lid frame)
X_latch  = 80;       // latch end faces: closed x = -80, lid x = +80
end_t    = 3;        // latch end walls

// ---------- Tools ----------
handle_d   = 18.21;
handle_len = 133;
shank_d    = 3.15;
blade_len  = 47;

// ---------- Handle ----------
hr   = 21.5 / 2;               // bore Ø21.5 (v4 19.2): 1.6 mm play
hy   = 21.5;                   // handle axis y
hz   = H / 2;                  // axis z, closed centre (same in both frames)
hb   = -81;                    // handle bottom end, lid frame x (in the riser tunnel)
lid_hx  = [hb - 1, hb + handle_len + 3];   // lid bore extent (tip at 52, bore to 55)
body_hx = [-lid_hx[1], -lid_hx[0]];        // same bore in the closed frame
scoop_x = hb + handle_len + 4;              // finger scoop just past the handle tip (lid frame x 56), clear of the magnet boss
clip_x   = [hb + 77];          // one clip, 74-80 mm up the handle (moved 5 mm down from 82 after the first full print), so the knurl shoulder stops the handle sliding
clip_d   = [17.0];
clip_len = 6;
clip_sq  = 0.3;                // 0.3 per side: picked from the 0.3/0.4/0.5 clip test (PETG)
clip_y   = [hy - 11, hy + 11.1];
function clip_r(d) = d/2 + 0.1;
function clip_m(d) = d/2 - clip_sq;
function clip_h(d) = sqrt(pow(clip_r(d), 2) - pow(clip_m(d), 2));

// ---------- Blades ----------
pitch = 9;                     // across (v4 5.5)
rows  = [for (i = [0 : 4]) 4.25 - i * pitch];   // 4.25 ... -31.75 (1.5 mm off the handle saddle)
bore = 3.2;
mouth = 2.9;                   // picked from the snap / keyhole tests (PETG): blades snap in through the keyhole
up_tighten = 0;                // both columns 2.9
// snap_test only: one mouth width per row (both columns), engraved on its back; narrowest (2.6) on the handle side
keyhole_series = part == "keyhole_test";   // keyhole_test: rows 3 and 4 only, 2.9 and 3.0
keyholes = true;               // Ø keyhole_d entry hole at the deep end of every slit (case and tests)
test_mouths = [2.6, 2.7, 2.8, 2.9, 3.0];
snap_series = part == "snap_test" || keyhole_series;
function row_mouth(i, riser = false) = snap_series ? test_mouths[i] : mouth - (riser ? up_tighten : 0);
test_label = "";               // clip_test: label engraved on its back (set from the Makefile)
label_depth = 0.4;
module back_label(t, x, y, size) translate([x, y, -1]) linear_extrude(1 + label_depth) mirror([1, 0])
    text(t, size = size, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
riser_x  = -50;                // riser front face (lid frame)
front_x  = riser_x + 21;       // lower step front face: 21 mm between the columns (v4 15.3)
cover_t   = 2.5;
cover_gap = 0.2;
up_top    = H - cover_t - cover_gap;   // riser top under the body's cover plate (25.3)
UP = [up_top - 3.8, riser_x - 14.5, riser_x];   // [z, deep end x, face x]: 14.5 mm of grip
LO = [UP[0] - 12, front_x - 12, front_x];        // 12 mm below the upper column
step_top = LO[0] + 3.1;
body_end = -riser_x - 0.2;     // closed x where the body floor and cradle stop

// ---------- Hinge ----------
pivot     = [83, H - 5];       // closed frame [x, z]
knuckle_r = 5;
X_hinge   = pivot[0] + knuckle_r;   // lid hinge face (closed x), flush with the arm ends (was +2.8: lid sat 2.2 mm short)
X_arm     = pivot[0] + knuckle_r;   // arm end: the knuckle's rounded top, vertical below the pivot
boss_out  = 1;                  // hinge boss stands 1 mm proud of the wall: 2 mm of arm under the screw head (as v4)
cover_end = -(UP[1] + 2) + 1;    // plate covers the riser seats' snap mouths (they end at closed x 62.5), 1 mm past
lid_step_end = cover_end - 0.1;
screw_clear  = 2.3;
screw_pilot  = 1.7;
screw_depth  = 7;
screw_head_d = 4.4;
screw_head_h = 2.0;
stop_a    = 300;                // 30° past upright: the lid back meets the cover plate end at ~301.5°
tooth_rel = [-7.5, -3.75];
tooth_d   = 2.6;
tooth_y   = [Wl - 0.75, Wi + 1.1];   // 1.1 mm into the arm
groove_clear = 0.3;
pivot_r  = norm([pivot[0] - cover_end, pivot[1]]) + 0.3;                    // plate end corner
relief_r = norm([pivot[0] + riser_x, pivot[1] - (H - up_top)]) + 0.3;       // riser front-bottom corner

// ---------- Magnets ----------
mag_d = 6.2; mag_h = 2.8;
mag_xy = [[72, 22], [72, -22]];   // lid frame
mag_boss_d = 10.6;   // overlaps the end wall by 0.3 (tangent at 10 left a non-manifold edge)

// ---------- Edges ----------
soften = true;
e_bed     = 2;      // 45° chamfer on bed edges
e_top     = 2.5;    // round on the body's top long edges
e_latch   = 6;      // latch-end vertical corners
e_hinge   = 1.5;    // arm-end vertical corners (keeps the screw counterbore whole)
e_end     = 2;      // chamfer across the latch-end top (lid back)
e_hinge_back = 4.5; // hinge-end lid back: keeps the flush-length lid off the table at the 300 deg stop
lid_e_back = 1.0;   // lid back long edges (nested between the walls)
lid_e_up   = 1.0;   // lid's up-facing long edges (parting face, steps)

// ---------- Finish ----------
grip = true;
knurl_x = [-78, 70]; knurl_z = [3, 25];   // full length of both sides, stopping clear of the hinge bosses and stop grooves
knurl_pitch = 2.0; knurl_angle = 60; knurl_groove = 0.85;
knurl_n = ceil(((knurl_x[1] - knurl_x[0]) / 2 + 20) / (knurl_pitch / sin(knurl_angle)));
ticks = false;   // the three latch-end lid ticks (dropped)
tick_x = [60, 64, 68]; tick_w = 1.6; tick_len = 54;
logo = "inlay"; logo_h = 42; logo_depth = 0.4; logo_rot = -90;
inlay_depth = 0.6; inlay_inset = 0;
// handle silhouette inlay on the lid's back, centred across the lid
silhouette = true;
sil_x0 = (-X_hinge + X_latch) / 2 - handle_len / 2;   // centred along the lid back (-69.4); tip points to the latch end
sil_y  = 18;           // off centre: above the centre line with the hinge on the right (top view)
sil_knurl = [3.0, 0.7];   // crosshatch pitch and line width on the knurled grip
// profile measured from the product photo (1304 px = 133 mm), widths pinned to Ø18.21 knurl / Ø17 smooth:
// [distance from bottom, half width]
sil_profile = [[0, 4.2], [0.3, 5.3], [0.7, 6.5], [1.3, 7.4], [1.9, 8.0], [2.6, 8.5], [3.3, 8.9], [4, 9.1],
               [78.5, 9.1], [78.5, 8.5], [102.3, 8.5], [114.0, 5.85],      // knurl, smooth body, taper
               [114.0, 4.5], [120.0, 4.5],                                 // neck
               [120.0, 5.8], [122.3, 5.75], [125.9, 5.0],                  // collar (short cone)
               [125.9, 3.55], [127.6, 3.6], [130.6, 3.0], [132.6, 2.7], [133, 2.4]];   // tip
sil_lines = [78.5, 102.3];    // breaks: knurl/smooth, cylinder/taper
// latch end: vertical flutes either side of a thumb notch across the seam
flutes = false; flute_r = 1.2; flute_depth = 0.8; flute_z = [3.5, 24.5]; flute_y = [-32 : 4 : 32];
notch = false; notch_depth = 1.6; notch_r = 14; notch_scale = [1, 1.4, 0.7];
// latch tabs, as on the original Deburring Tool Case: wedge lips past the latch end, top face flush
// with the seam. One on the body (centre, below the seam), two on the lid (either side, above it).
// Squeeze them apart to open. Undersides at 45 deg so they print without support.
tabs = true;
tab_len = 6;                 // reach past the end face
tab_d   = [7.5, 1.5];        // thickness at the root, at the tip (root - tip = tab_len: 45 deg)
tab_body_w = [13, 7];        // body tab half width, root -> tip
tab_lid_y  = 23.75;          // lid tab centres (y = +-)
tab_lid_w  = [10.25, 5.5];   // lid tab half width, root -> tip (0.5 mm clear of the body tab at the root)

// ================= helpers =================
module to_closed() translate([0, 0, H]) rotate([0, 180, 0]) children();
module to_lid()    to_closed() children();
module xcyl(y, z, r, x0, x1) translate([x0, y, z]) rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0);
module pivot_cyl(r, h = 2 * Wi) translate([pivot[0], 0, pivot[1]]) rotate([90, 0, 0]) cylinder(r = r, h = h, center = true, $fn = 240);
module at_angle(a) translate([pivot[0], 0, pivot[1]]) rotate([0, a, 0]) translate([-pivot[0], 0, -pivot[1]]) children();
module closed_lid() to_closed() lid();

module fillet2d(r, e = 1) translate([-r, -r]) difference() { square(r + e); circle(r, $fn = 48); }
module chamfer2d(c) polygon([[-c, 1], [-c, 0], [0, -c], [1, -c], [1, 1]]);
module edge_cut(p, u, v, w, len) multmatrix([[u[0], v[0], w[0], p[0]], [u[1], v[1], w[1], p[1]], [u[2], v[2], w[2], p[2]], [0, 0, 0, 1]])
    linear_extrude(len) children();

// ================= lid =================
// keyholes: a vertical Ø keyhole_d hole at the slit's deep end. The shank goes in tip-first through it,
// then the blade is pivoted down into the slit (the tip sits 0.3 from the bore end, as in lid_tools)
keyhole_d = 3.12;              // as tested on the keyhole test piece
module snap_slot(c, x0, x1, surf, m) {
    xcyl(0, c[0], bore/2, c[1], c[2] + 1);
    if (keyholes) {
        kx = c[1] + 0.3 + keyhole_d/2;
        translate([kx, 0, c[0]]) cylinder(d = keyhole_d, h = 40, $fn = 48);
        translate([kx, 0, surf - 0.8]) cylinder(d1 = keyhole_d, d2 = keyhole_d + 1.6, h = 0.81, $fn = 48);   // lead-in, as on the slit
        translate([kx, -m/2, c[0]]) cube([x0 - kx + 0.01, m, 40]);   // slit runs into the keyhole
        translate([kx, 0, surf]) rotate([90, 0, 90]) linear_extrude(x0 - kx + 0.01)
            polygon([[-m/2 - 0.8, 0.01], [m/2 + 0.8, 0.01], [m/2, -0.8], [-m/2, -0.8]]);
    }
    translate([x0, -m/2, c[0]]) cube([x1 - x0, m, 40]);
    translate([x0, 0, surf]) rotate([90, 0, 90]) linear_extrude(x1 - x0)
        polygon([[-m/2 - 0.8, 0.01], [m/2 + 0.8, 0.01], [m/2, -0.8], [-m/2, -0.8]]);
}

module lid_main() difference() {
    union() {
        // tray: back, side walls, latch end wall
        translate([-X_hinge, -Wl, 0]) cube([X_hinge + X_latch, 2 * Wl, P]);
        // riser (full height) and lower step
        translate([-X_hinge, -Wl, 0]) cube([X_hinge + riser_x, 2 * Wl, H - 0.1]);
        translate([riser_x - 0.01, -Wl, 0]) cube([front_x - riser_x + 0.01, 2 * Wl, step_top]);
    }
    // tray pocket
    difference() {
        translate([front_x, -Wt, tray_z]) cube([X_latch - end_t - front_x, 2 * Wt, H]);
        // handle saddle (left solid under the handle, bore cut below)
        difference() {
            translate([front_x - 1, clip_y[0] - 1.5, 0]) cube([scoop_x - 8 - front_x + 1, Wt - clip_y[0] + 2.5, P]);
            // notch for the nearest lower blade's hook
            translate([LO[1] + blade_len - 13, clip_y[0] - 2, tray_z]) cube([12, 3, P]);
        }
        // magnet bosses
        for (m = mag_xy) translate([m[0], m[1], 0]) cylinder(d = mag_boss_d, h = P);
    }
    // riser steps down under the cover plate
    translate([-lid_step_end, -Wl - 1, up_top]) cube([lid_step_end + riser_x + 0.01, 2 * Wl + 2, 10]);
    // clear the tray in front of the step so every lower blade can slide out
    translate([front_x - 0.01, rows[4] - bore/2 - 0.4, LO[0] - bore/2 - 0.4]) cube([12, rows[0] - rows[4] + bore + 0.8, 20]);
    // handle bore: flat-topped teardrop so the tunnel through the riser prints without supports
    translate([lid_hx[0], 0, 0]) rotate([90, 0, 90]) linear_extrude(lid_hx[1] - lid_hx[0])
        intersection() {
            hull() { translate([hy, hz]) circle(r = hr); translate([hy, hz + hr * sqrt(2)]) square(0.01, center = true); }
            translate([hy - hr - 1, hz - hr - 1]) square([2 * hr + 2, 2 * hr + 1]);
        }
    // open slot over the tunnel where the riser steps down under the plate (else a 0.55 mm roof)
    translate([-lid_step_end, hy - 4.5, hz + hr - 0.05]) cube([lid_step_end + riser_x + 0.01, 9, 10]);
    // finger scoop under the handle tip
    intersection() {
        translate([scoop_x, hy, tray_z + 8.5]) sphere(d = 20);
        translate([scoop_x - 20, hy - 20, 1.5]) cube([40, 40, 40]);   // floor stays 1.5 (0.9 over the tick inlays)
    }
    // blade seats
    for (i = [0 : 4]) translate([0, rows[i], 0]) {
        snap_slot(LO, LO[1] + 2, front_x + 1, step_top, row_mouth(i));   // slit starts 2 mm in, as on the riser, so the keyhole shows
        snap_slot(UP, UP[1] + 2, riser_x + 1, up_top, row_mouth(i, true));
    }
}

module handle_clips() for (i = [0 : len(clip_x) - 1]) {
    cx = clip_x[i]; d = clip_d[i]; r = clip_r(d); m = clip_m(d); top = hz + clip_h(d);
    difference() {
        translate([cx - clip_len/2, clip_y[0], tray_z - 0.01]) cube([clip_len, clip_y[1] - clip_y[0], top - tray_z]);
        xcyl(hy, hz, r, cx - clip_len/2 - 1, cx + clip_len/2 + 1);
        translate([cx - clip_len/2 - 1, 0, 0]) rotate([90, 0, 90]) linear_extrude(clip_len + 2)
            polygon([[hy - m - 0.7, top + 0.01], [hy + m + 0.7, top + 0.01], [hy + m, top - 0.7], [hy - m, top - 0.7]]);
    }
}
module clip_pockets() for (i = [0 : len(clip_x) - 1]) {   // lid frame
    cx = clip_x[i]; top = hz + clip_h(clip_d[i]);
    translate([cx - clip_len/2 - 0.5, clip_y[0] - 0.5, P - 1]) cube([clip_len + 1, clip_y[1] - clip_y[0] + 1, top - P + 1.5]);
}

module tooth(s, d = tooth_d, y = tooth_y) translate([pivot[0] + tooth_rel[0], 0, pivot[1] + tooth_rel[1]])
    rotate([s > 0 ? -90 : 90, 0, 0]) translate([0, 0, y[0]]) cylinder(d = d, h = y[1] - y[0], $fn = 32);
module stop_groove(s) {
    a_end = stop_a - groove_clear / norm(tooth_rel) * 180 / PI;
    for (a = [0 : 3 : a_end - 3]) hull() {
        at_angle(a)                 tooth(s, tooth_d + 2 * groove_clear, [Wi - 0.5, tooth_y[1] + groove_clear]);
        at_angle(min(a + 3, a_end)) tooth(s, tooth_d + 2 * groove_clear, [Wi - 0.5, tooth_y[1] + groove_clear]);
    }
}

module ticks2d() for (x = tick_x) translate([x, 0]) square([tick_w, tick_len], center = true);
module ticks_cut()  translate([0, 0, -1]) linear_extrude(1 + inlay_depth) ticks2d();
module ticks_part() linear_extrude(inlay_depth) offset(delta = -inlay_inset) ticks2d();

// handle silhouette, lid frame (u along the handle from its bottom, mirrored about its axis)
module sil_shape() translate([sil_x0, sil_y]) polygon(concat([for (p = sil_profile) [p[0], p[1]]], [for (i = [len(sil_profile) - 1 : -1 : 0]) [sil_profile[i][0], -sil_profile[i][1]]]));
module sil2d() difference() {
    sil_shape();
    intersection() {      // knurl crosshatch on the grip
        translate([sil_x0 + 3.5, sil_y - 10]) square([sil_lines[0] - 3.5 - 0.6, 20]);
        for (a = [-30, 30], k = [-30 : 30]) translate([sil_x0 + 40, sil_y]) rotate(a) translate([k * sil_knurl[0], 0]) square([sil_knurl[1], 200], center = true);
    }
    for (u = sil_lines) translate([sil_x0 + u - 0.3, sil_y - 10]) square([0.6, 20]);
}
module sil_cut()  translate([0, 0, -1]) linear_extrude(1 + inlay_depth) sil2d();
module sil_part() linear_extrude(inlay_depth) offset(delta = -inlay_inset) sil2d();

// latch end (closed frame): flutes and the thumb notch, cut from both halves
module latch_cuts() {
    if (flutes) for (y = flute_y)
        hull() for (z = flute_z) translate([-X_latch - flute_r + flute_depth, y, z]) sphere(r = flute_r, $fn = 24);
    if (notch) translate([-X_latch - notch_r + notch_depth, 0, Pc]) scale(notch_scale) sphere(r = notch_r, $fn = 96);
}

// one latch tab in the closed frame, centred at y = yc, on the side sd of the seam (-1 body, +1 lid).
// The root sinks 1 mm into the end face so it fills the flutes behind it.
module latch_tab(yc, w, sd) hull() {
    translate([-X_latch + 1 - 0.01, yc - w[0], sd > 0 ? Pc : Pc - tab_d[0]]) cube([0.01, 2 * w[0], tab_d[0]]);
    for (t = [-1, 1]) translate([-X_latch - tab_len + 1, yc + t * (w[1] - 1), sd > 0 ? Pc : Pc - tab_d[1]]) cylinder(r = 1, h = tab_d[1], $fn = 32);
}
module body_tabs() if (tabs) latch_tab(0, tab_body_w, -1);
module lid_tabs()  if (tabs) for (s = [-1, 1]) latch_tab(s * tab_lid_y, tab_lid_w, 1);

// Lid-only edges (lid frame): back long edges (bed) chamfered, up-facing long edges rounded
module lid_edge_cuts() for (s = [-1, 1]) {
    edge_cut([-X_hinge - 5, s * Wl, 0], [0, s, 0], [0, 0, -1], [1, 0, 0], X_hinge + X_latch + 10) chamfer2d(lid_e_back);
    for (seg = [[front_x, X_latch, P], [riser_x, front_x, step_top], [-lid_step_end, riser_x, up_top], [-X_hinge, -lid_step_end, H - 0.1]])
        edge_cut([seg[0], s * Wl, seg[2]], [0, s, 0], [0, 0, 1], [1, 0, 0], seg[1] - seg[0]) fillet2d(lid_e_up, 0.05);
}

module lid() render() union() { lid_cut(); to_lid() lid_tabs(); }
module lid_cut() difference() {
    union() {
        lid_main();
        handle_clips();
        to_lid() for (s = [-1, 1]) tooth(s);
        // riser end follows the plate's swing arc: hairline seam when closed
        to_lid() intersection() {
            pivot_cyl(pivot_r - 0.25, 2 * Wl);
            translate([cover_end - 6, -Wl, 0]) cube([8, 2 * Wl, cover_t + cover_gap + 0.01]);
        }
    }
    for (s = [-1, 1]) translate([-pivot[0], s * (Wl + 0.01), H - pivot[1]])
        rotate([s * 90, 0, 0]) cylinder(d = screw_pilot, h = screw_depth, $fn = 24);
    for (m = mag_xy) translate([m[0], m[1], P - mag_h]) cylinder(d = mag_d, h = mag_h + 1, $fn = 48);
    if (ticks) ticks_cut();
    if (silhouette) sil_cut();
    to_lid() latch_cuts();
    if (soften) { to_lid() edge_cuts(); lid_edge_cuts(); }
    // hinge-end back edge: bevel so it stays off the table at the fold-back stop
    edge_cut([-X_hinge, -Wl - 1, 0], [-1, 0, 0], [0, 0, -1], [0, 1, 0], 2 * Wl + 2) chamfer2d(e_hinge_back);
}

// ================= body =================
module logo2d() mirror([0, 1]) rotate(logo_rot) resize([0, logo_h], auto = true) import("ref/bambu-lab.svg", center = true);
module logo_cut()  translate([0, 0, -1]) linear_extrude(1 + logo_depth) logo2d();
module logo_part() linear_extrude(logo_depth) offset(delta = -inlay_inset) logo2d();

module knurl_cut() intersection() {
    translate([knurl_x[0], -W, knurl_z[0]]) cube([knurl_x[1] - knurl_x[0], 2 * W, knurl_z[1] - knurl_z[0]]);
    for (side = [-1, 1], th = [-knurl_angle, knurl_angle], k = [-knurl_n : knurl_n])
        translate([(knurl_x[0] + knurl_x[1]) / 2 + k * knurl_pitch / sin(knurl_angle), side * W/2, (knurl_z[0] + knurl_z[1]) / 2])
            rotate([0, th, 0]) rotate([45, 0, 0])
                cube([80, knurl_groove - (th > 0 ? 0.1 : 0), knurl_groove - (th > 0 ? 0.1 : 0)], center = true);
}

// Outer edges (closed frame). Applied to both halves; only removes material.
module edge_cuts() {
    L = 2 * X_hinge + 40;
    for (s = [-1, 1]) {
        edge_cut([-L/2, s * W/2, 0], [0, s, 0], [0, 0, -1], [1, 0, 0], L) chamfer2d(e_bed);
        edge_cut([-L/2, s * W/2, H], [0, s, 0], [0, 0, 1], [1, 0, 0], L) fillet2d(e_top);
        edge_cut([-X_latch, s * W/2, -5], [-1, 0, 0], [0, s, 0], [0, 0, 1], H + 10) fillet2d(e_latch);
        edge_cut([X_arm, s * W/2, -5], [1, 0, 0], [0, s, 0], [0, 0, 1], pivot[1] + 5) fillet2d(e_hinge);
    }
    edge_cut([-X_latch, -W, 0], [-1, 0, 0], [0, 0, -1], [0, 1, 0], 2 * W) chamfer2d(e_bed);    // latch end, bed
    edge_cut([-X_latch, -W, H], [-1, 0, 0], [0, 0, 1], [0, 1, 0], 2 * W) chamfer2d(e_end);     // latch end, top
    edge_cut([X_arm, -W, 0], [1, 0, 0], [0, 0, -1], [0, 1, 0], 2 * W) chamfer2d(e_bed);        // arm ends, bed
    edge_cut([X_hinge, -Wl, 0], [1, 0, 0], [0, 0, -1], [0, 1, 0], 2 * Wl) chamfer2d(e_bed);     // lid riser end, bed
}

module hinge_boss(s) difference() {
    translate([pivot[0], s * (W/2 - 0.01), pivot[1]]) rotate([s > 0 ? -90 : 90, 0, 0]) cylinder(r = knuckle_r - 0.5, h = boss_out + 0.01, $fn = 64);
    translate([pivot[0], 0, pivot[1]]) rotate([s * -90, 0, 0]) translate([0, 0, Wi - 1]) cylinder(d = screw_head_d, h = 10, $fn = 32);
}
module body() render() union() { body_main(); for (s = [-1, 1]) hinge_boss(s); body_tabs(); }
module body_main() difference() {
    union() {
        // floor and latch end wall
        translate([-X_latch, -Wi, 0]) cube([X_latch + body_end, 2 * Wi, floor_t]);
        translate([-X_latch, -Wi, 0]) cube([end_t, 2 * Wi, Pc]);
        // side walls, running on as the hinge arms
        for (s = [-1, 1]) translate([0, s > 0 ? Wi : -W/2, 0]) {
            translate([-X_latch, 0, 0]) cube([X_latch + pivot[0], wall, H]);
            translate([pivot[0], 0, 0]) cube([knuckle_r, wall, pivot[1]]);
            translate([pivot[0], 0, pivot[1]]) rotate([-90, 0, 0]) cylinder(r = knuckle_r, h = wall, $fn = 64);
        }
        // handle cradle: solid from the floor to the parting plane, bore cut below
        translate([-X_latch, clip_y[0] - 1.5, 0]) cube([X_latch + body_end, Wi - clip_y[0] + 1.5, Pc]);
        // cover plate over the riser seats
        translate([body_end - 5, -Wi, 0]) cube([cover_end - body_end + 5, 2 * Wi, cover_t]);
        // magnet bosses
        for (m = mag_xy) translate([-m[0], m[1], 0]) cylinder(d = mag_boss_d, h = Pc);
    }
    xcyl(hy, hz, hr, body_hx[0], body_hx[1] + 1);
    // relief beside the riser blades' hooks (nearest row), under the handle bore (wall to the bore >= 1.8)
    translate([-(UP[1] + blade_len) - 2, clip_y[0] - 3, floor_t]) cube([UP[1] + blade_len + 2 + body_end + 1, 12 - clip_y[0] + 3, Pc + 1 - floor_t]);   // full height: no rib left hanging
    to_closed() clip_pockets();
    // keep clear of the lid's lower step (which stands 1.6 mm below the parting plane)
    translate([-front_x - 0.5, -Wi, H - step_top - 0.3]) cube([X_hinge, 2 * Wi, H]);   // inside the walls only
    // swing clearances, between the arms only
    intersection() {
        union() {
            pivot_cyl(pivot_r);
            intersection() { pivot_cyl(relief_r); translate([body_end - 10, -W, floor_t - 0.5]) cube([10.05, 2 * W, H]); }
        }
        translate([body_end - 10, -Wi, -1]) cube([X_hinge, 2 * Wi, H + 2]);
    }
    // screws: clearance through each arm, head counterbore outside
    for (s = [-1, 1]) translate([pivot[0], 0, pivot[1]]) rotate([s * -90, 0, 0]) {
        translate([0, 0, Wi - 0.5]) cylinder(d = screw_clear, h = 10, $fn = 24);
        translate([0, 0, W/2 + boss_out - screw_head_h]) cylinder(d = screw_head_d, h = 10, $fn = 32);
    }
    for (m = mag_xy) translate([-m[0], m[1], Pc - mag_h]) cylinder(d = mag_d, h = mag_h + 1, $fn = 48);
    for (s = [-1, 1]) stop_groove(s);
    if (logo != "none") logo_cut();
    if (grip) knurl_cut();
    latch_cuts();
    if (soften) edge_cuts();
}

// ================= tools (visual) =================
module blade() color("Silver") {
    sl = blade_len - 9;
    rotate([0, 90, 0]) cylinder(d = shank_d, h = sl);
    translate([sl, 0, 0]) rotate_extrude(angle = 150) translate([4, 0]) circle(d = shank_d * 0.8);
}
module lid_tools() if (show_tools) {
    for (y = rows) { translate([LO[1] + 0.3, y, LO[0]]) blade(); translate([UP[1] + 0.3, y, UP[0]]) blade(); }
    color("DimGray") xcyl(hy, hz, handle_d/2, hb, hb + handle_len);
}

// ================= outputs =================
if (part == "body") body();
else if (part == "lid") lid();
else if (part == "body_inlays") { if (logo == "inlay") logo_part(); }
else if (part == "inlays") { if (ticks) ticks_part(); if (silhouette) sil_part(); }
else if (part == "closed") { color("#e7863b") body(); color("#1f9fb0") closed_lid(); }
else if (part == "assembly") { color("#1f9fb0") lid(); lid_tools(); color("#e7863b") translate([0, W + 10, 0]) body(); }
else if (part == "posed") { color("#e7863b") body(); color("#1f9fb0") at_angle(swing_a) closed_lid(); }
else if (part == "swing_check") intersection() { body(); at_angle(swing_a) closed_lid(); }
else if (part == "closed_check") intersection() { body(); closed_lid(); }
else if (part == "section") intersection() { union() { color("#1f9fb0") lid(); lid_tools(); } translate([-X_hinge - 1, -2, -1]) cube([60, 4, H + 2]); }
else if (part == "snap_test") difference() {
    intersection() { lid(); translate([UP[1] - 4, rows[4] - 5, 0]) cube([front_x - UP[1] + 8, rows[0] - rows[4] + 10, H]); }
    for (i = [0 : 4]) back_label(str(test_mouths[i]), (UP[2] + LO[1]) / 2, rows[i], 3.5);
}
else if (part == "keyhole_test") difference() {
    intersection() { lid(); translate([UP[1] - 4, rows[4] - 5, 0]) cube([front_x - UP[1] + 8, rows[3] - rows[4] + 10, H]); }
    for (i = [3 : 4]) back_label(str(test_mouths[i], " K"), (UP[2] + LO[1]) / 2, rows[i], 3.5);
}
else if (part == "clip_test") difference() {
    intersection() { lid(); translate([min(clip_x) - 5, clip_y[0] - 1, 0]) cube([10, clip_y[1] - clip_y[0] + 2, H]); }
    if (test_label != "") back_label(test_label, min(clip_x), hy, 4);
}
else if (part == "hinge_test_body") intersection() { body(); translate([body_end - 12, -W, -1]) cube([60, 2 * W, H + 2]); }
else if (part == "hinge_test_lid")  intersection() { lid(); translate([-X_hinge - 5, -W, -1]) cube([X_hinge + front_x + 5, 2 * W, H + 2]); }
