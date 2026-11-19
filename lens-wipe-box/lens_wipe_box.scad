// Zeiss lens-wipe holder
// Styled after "TeabagHolder": open-top rounded box, fluted outer walls,
// chamfered foot, U-shaped finger slot in each end wall.
//
// Packets stand on edge, stacked along the length (Y) of the box.
// Units: mm.

/* [Packet] */
packet_w      = 55;    // packet width  (across box, X)
packet_h      = 50;    // packet height (vertical, Z)
clearance     = 1.5;   // gap each side of packet
packet_t      = 3.5;   // packet thickness (stack direction)
outer_length  = 100;   // overall box length (Y); inner stack length is derived
packet_proud  = 0;     // how far packets stick up above the rim (negative = rim above packets)

/* [Shell] */
wall          = 2.4;   // solid wall thickness (inside the flutes)
floor_t       = 2.5;   // floor thickness
corner_r      = 8;     // outer corner radius (plan view)

/* [Flutes] */
flute_pitch   = 2.4;   // spacing of vertical grooves
flute_w       = 1.0;   // groove width
flute_d       = 0.7;   // groove depth
foot_h        = 1.8;   // chamfered foot height
foot_inset    = 1.0;   // foot chamfer inset

/* [End slots] */
slot_frac     = 0.62;  // slot width as fraction of inner width
slot_bottom   = 0.30;  // slot bottom height as fraction of inner height (above floor)
slot_top_r    = 5;     // fillet where slot meets rim
rim_chamfer   = 0.8;   // inner rim chamfer

/* [Style] */
style         = "modern"; // [classic, rugged, modern]
// modern: sloped file-holder profile, thin walls, floating base, finger scoop
m_wall        = 2.0;   // wall thickness
m_corner_r    = 5;     // plan-view corner radius
m_front_h     = 20;    // front wall height (overall, from desk)
m_gap_h       = 2;     // shadow-gap base height
m_gap_inset   = 1.2;   // shadow-gap inset
m_scoop_w     = 34;    // finger scoop width (front wall)
m_scoop_d     = 6;     // finger scoop depth
m_feet_d      = 8.5;   // pocket for stick-on rubber feet (0 = none)
m_feet_depth  = 0.8;
// rugged: chamfered corners, recessed side panels, hex bolts, ribs
r_corner_ch   = 6;     // plan-view corner chamfer
r_edge_ch     = 1.5;   // rim / foot chamfer
r_panel_d     = 1.0;   // side panel recess depth
r_panel_inset = 5;     // panel border width
r_bolt_d      = 6;     // hex bolt across-flats
r_ribs        = 2;     // horizontal ribs in each panel

/* [Export] */
part = "box";          // [box, fit_test]
fit_test_h = 12;       // height of the fit-test ring

$fn = 64;

// ---------- derived ----------
shell_t = style == "modern" ? m_wall : wall + flute_d;   // total side thickness
inner_w = packet_w + 2*clearance;
inner_l = outer_length - 2*shell_t;
capacity = floor(inner_l / packet_t);
inner_h = packet_h - packet_proud;               // wall height above floor
outer_w = inner_w + 2*shell_t;
outer_l = inner_l + 2*shell_t;
outer_h = floor_t + inner_h;
inner_r = max(corner_r - wall - flute_d, 1);

slot_w  = inner_w * slot_frac;
slot_z0 = floor_t + inner_h * slot_bottom;      // bottom of the U
slot_r  = min(slot_w/2, 14);

echo(str("Outer size: ", outer_w, " x ", outer_l, " x ", outer_h, " mm"));
echo(str("Inner size: ", inner_w, " x ", inner_l, " x ", inner_h, " mm"));
echo(str("Capacity: ", capacity, " packets (",
         inner_l - capacity*packet_t, " mm slack)"));

// ---------- 2D helpers ----------
module rrect(w, l, r) {
    offset(r = r) square([w - 2*r, l - 2*r], center = true);
}

// Rounded rectangle with vertical flutes cut around the perimeter.
module fluted_outline(w, l, r) {
    difference() {
        rrect(w, l, r);
        flute_ring(w, l, r);
    }
}

module flute(at, ang) {
    translate(at) rotate(ang) square([flute_d*2, flute_w], center = true);
}

module flute_ring(w, l, r) {
    sx = w/2 - r;   // corner-centre offsets
    sy = l/2 - r;
    // straight sides
    for (side = [[2*sx, [0,  l/2],  90, 0], [2*sx, [0, -l/2], -90, 0],
                 [2*sy, [ w/2, 0],   0, 1], [2*sy, [-w/2, 0], 180, 1]]) {
        len = side[0];
        n   = max(floor(len / flute_pitch), 1);
        step = len / n;
        for (i = [0 : n - 1]) {
            t = -len/2 + step*(i + 0.5);
            p = side[3] == 0 ? [t, side[1][1]] : [side[1][0], t];
            flute(p, side[2]);
        }
    }
    // corners
    arc = PI * r / 2;
    nc  = max(round(arc / flute_pitch), 1);
    for (c = [[ sx,  sy,   0], [-sx,  sy,  90],
              [-sx, -sy, 180], [ sx, -sy, 270]])
        for (j = [0 : nc - 1]) {
            a = c[2] + 90 * (j + 0.5) / nc;
            flute([c[0] + r*cos(a), c[1] + r*sin(a)], a);
        }
}

// ---------- 3D parts ----------
module outer_body(h) {
    // chamfered foot
    hull() {
        linear_extrude(0.01)
            rrect(outer_w - 2*foot_inset - 2*flute_d, outer_l - 2*foot_inset - 2*flute_d,
                  max(corner_r - foot_inset - flute_d, 0.5));
        translate([0, 0, foot_h])
            linear_extrude(0.01)
                rrect(outer_w - 2*flute_d, outer_l - 2*flute_d, corner_r - flute_d);
    }
    // fluted walls
    translate([0, 0, foot_h])
        linear_extrude(h - foot_h)
            fluted_outline(outer_w, outer_l, corner_r);
}

module cavity(h) {
    translate([0, 0, floor_t])
        linear_extrude(h)
            rrect(inner_w, inner_l, inner_r);
    // inner rim chamfer
    translate([0, 0, outer_h - rim_chamfer])
        hull() {
            linear_extrude(0.01) rrect(inner_w, inner_l, inner_r);
            translate([0, 0, rim_chamfer + 0.01])
                linear_extrude(0.01)
                    rrect(inner_w + 2*rim_chamfer, inner_l + 2*rim_chamfer, inner_r + rim_chamfer);
        }
}

// 2D U-slot profile in the XZ plane, with filleted top corners.
module slot_profile() {
    big = outer_w * 2;
    offset(r = -slot_top_r) offset(delta = slot_top_r)
    union() {
        hull() {
            translate([-slot_w/2 + slot_r, slot_z0 + slot_r]) circle(slot_r);
            translate([ slot_w/2 - slot_r, slot_z0 + slot_r]) circle(slot_r);
            translate([-slot_w/2, outer_h + 5]) square([slot_w, 1]);
        }
        translate([-big/2, outer_h]) square([big, 20]);
    }
}

module end_slots() {
    rotate([90, 0, 0])
        linear_extrude(outer_l + 10, center = true)
            slot_profile();
}

module box() {
    difference() {
        outer_body(outer_h);
        cavity(outer_h);
        end_slots();
    }
}

module fit_test() {
    // Bottom ring of the box: checks packet fit and flute look without a full print.
    difference() {
        outer_body(fit_test_h);
        translate([0, 0, floor_t]) linear_extrude(fit_test_h) rrect(inner_w, inner_l, inner_r);
        // open the floor to save plastic, leave a ledge
        translate([0, 0, -1]) linear_extrude(floor_t + 2) rrect(inner_w - 10, inner_l - 10, max(inner_r - 5, 1));
    }
}

// ---------- rugged style ----------
module chrect(w, l, c) {
    polygon([[-w/2 + c, -l/2], [w/2 - c, -l/2], [w/2, -l/2 + c], [w/2, l/2 - c],
             [w/2 - c, l/2], [-w/2 + c, l/2], [-w/2, l/2 - c], [-w/2, -l/2 + c]]);
}

// Chamfered-corner block with chamfered top and bottom edges.
module r_shell(h) {
    e = r_edge_ch;
    hull() {
        linear_extrude(0.01) chrect(outer_w - 2*e, outer_l - 2*e, r_corner_ch);
        translate([0, 0, e]) linear_extrude(h - 2*e) chrect(outer_w, outer_l, r_corner_ch);
        translate([0, 0, h - 0.01]) linear_extrude(0.01) chrect(outer_w - 2*e, outer_l - 2*e, r_corner_ch);
    }
}

function r_panel_l() = outer_l - 2*r_corner_ch - 2*r_panel_inset;
function r_panel_z0() = r_edge_ch + r_panel_inset;
function r_panel_z1(h) = h - r_edge_ch - r_panel_inset;

module hex_bolt(h) {
    // hex head with a chamfered top
    hull() {
        cylinder(d = r_bolt_d / cos(30), h = h - 0.4, $fn = 6);
        cylinder(d = r_bolt_d / cos(30) - 0.8, h = h, $fn = 6);
    }
}

// Things cut from / added to each long face, built on the +X face then mirrored.
module r_panel_cut(h) {
    pl = r_panel_l(); z0 = r_panel_z0(); z1 = r_panel_z1(h); d = r_panel_d;
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([outer_w/2, 0, 0])
            hull() {   // recess with 45° walls
                translate([-d, -pl/2 + d, z0 + d]) cube([0.01, pl - 2*d, z1 - z0 - 2*d]);
                translate([0, -pl/2, z0]) cube([1, pl, z1 - z0]);
            }
}

module r_panel_add(h) {
    pl = r_panel_l(); z0 = r_panel_z0(); z1 = r_panel_z1(h); d = r_panel_d;
    bo = r_bolt_d/2 + 2.5;   // bolt offset from panel edge
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([outer_w/2 - d, 0, 0]) {
            // corner bolts, flush with the outer face
            for (y = [-pl/2 + bo, pl/2 - bo], z = [z0 + bo, z1 - bo])
                translate([0, y, z]) rotate([0, 90, 0]) rotate(30) hex_bolt(d);
            // horizontal stiffening ribs between the bolt columns
            rl = pl - 4*bo;
            for (i = [1 : r_ribs]) {
                z = z0 + (z1 - z0) * i / (r_ribs + 1);
                translate([0, 0, z]) hull() {
                    translate([0, -rl/2, -1.5]) cube([0.01, rl, 3]);
                    translate([d - 0.01, -rl/2 + d, -0.9]) cube([0.01, rl - 2*d, 1.8]);
                }
            }
        }
}

// Angular slot: flared trapezoid with a flat bottom, lightly rounded for printing.
module r_slot_profile() {
    big = outer_w * 2;
    bw = slot_w * 0.6;          // bottom width
    offset(r = 1.5) offset(delta = -1.5)
    offset(r = -2) offset(delta = 2)
    union() {
        polygon([[-bw/2, slot_z0], [bw/2, slot_z0],
                 [slot_w/2, slot_z0 + (slot_w - bw)/2 + 4],
                 [slot_w/2, outer_h + 5], [-slot_w/2, outer_h + 5],
                 [-slot_w/2, slot_z0 + (slot_w - bw)/2 + 4]]);
        // chamfered lead-in at the rim
        polygon([[-slot_w/2 - 3, outer_h + 0.01], [slot_w/2 + 3, outer_h + 0.01],
                 [slot_w/2, outer_h - 3], [-slot_w/2, outer_h - 3]]);
        translate([-big/2, outer_h]) square([big, 20]);
    }
}

module r_cavity(h) {
    translate([0, 0, floor_t]) linear_extrude(h) chrect(inner_w, inner_l, max(r_corner_ch - wall - flute_d, 1));
    translate([0, 0, outer_h - rim_chamfer]) hull() {
        linear_extrude(0.01) chrect(inner_w, inner_l, max(r_corner_ch - wall - flute_d, 1));
        translate([0, 0, rim_chamfer + 0.01]) linear_extrude(0.01)
            chrect(inner_w + 2*rim_chamfer, inner_l + 2*rim_chamfer, max(r_corner_ch - wall - flute_d, 1) + rim_chamfer);
    }
}

module rugged_box() {
    difference() {
        union() {
            difference() { r_shell(outer_h); r_panel_cut(outer_h); }
            r_panel_add(outer_h);
        }
        r_cavity(outer_h);
        rotate([90, 0, 0]) linear_extrude(outer_l + 10, center = true) r_slot_profile();
    }
}

module rugged_fit_test() {
    difference() {
        r_shell(fit_test_h);
        translate([0, 0, floor_t]) linear_extrude(fit_test_h) chrect(inner_w, inner_l, max(r_corner_ch - wall - flute_d, 1));
        translate([0, 0, -1]) linear_extrude(floor_t + 2) chrect(inner_w - 10, inner_l - 10, 1);
    }
}

// ---------- modern style ----------
// Front of the box is -Y (low wall), back is +Y (full height).
module m_outline(w, l, r) { rrect(w, l, r); }

// Side profile: slopes from m_front_h at the front to outer_h at the back.
module m_profile_clip(h_back) {
    rotate([90, 0, 90])
        linear_extrude(outer_w + 10, center = true)
            polygon([[-outer_l/2 - 1, -1], [outer_l/2 + 1, -1],
                     [outer_l/2 + 1, h_back], [-outer_l/2 - 1, m_front_h]]);
}

module m_body(h) {
    // shadow-gap plinth
    linear_extrude(m_gap_h + 0.01)
        m_outline(outer_w - 2*m_gap_inset, outer_l - 2*m_gap_inset, m_corner_r - m_gap_inset);
    translate([0, 0, m_gap_h]) linear_extrude(h - m_gap_h) m_outline(outer_w, outer_l, m_corner_r);
}

module m_scoop() {
    // shallow circular dip in the front wall top
    R = (m_scoop_w*m_scoop_w/4 + m_scoop_d*m_scoop_d) / (2*m_scoop_d);
    translate([0, -outer_l/2 + shell_t/2, m_front_h - m_scoop_d + R])
        rotate([90, 0, 0]) cylinder(r = R, h = shell_t + 4, center = true, $fn = 180);
}

module m_feet() {
    if (m_feet_d > 0) {
        fx = outer_w/2 - m_gap_inset - m_feet_d/2 - 3;
        fy = outer_l/2 - m_gap_inset - m_feet_d/2 - 3;
        for (x = [-fx, fx], y = [-fy, fy])
            translate([x, y, -0.01]) cylinder(d = m_feet_d, h = m_feet_depth + 0.01);
    }
}

module modern_box() {
    difference() {
        intersection() {
            m_body(outer_h);
            m_profile_clip(outer_h);
        }
        translate([0, 0, floor_t]) linear_extrude(outer_h)
            m_outline(inner_w, inner_l, max(m_corner_r - shell_t, 0.5));
        m_scoop();
        m_feet();
    }
}

module modern_fit_test() {
    difference() {
        m_body(fit_test_h);
        translate([0, 0, floor_t]) linear_extrude(fit_test_h)
            m_outline(inner_w, inner_l, max(m_corner_r - shell_t, 0.5));
        translate([0, 0, -1]) linear_extrude(floor_t + 2) m_outline(inner_w - 10, inner_l - 10, 1);
    }
}

if (part == "box") {
    if (style == "rugged") rugged_box();
    else if (style == "modern") modern_box();
    else box();
} else if (part == "fit_test") {
    if (style == "rugged") rugged_fit_test();
    else if (style == "modern") modern_fit_test();
    else fit_test();
}
