// Desk dial — monitor pod + Command-strip bracket (#213).
// Spec: docs/superpowers/specs/2026-11-02-desk-dial-pod-design.md
//
// Frame: origin = the monitor's front corner on the pod's side, at the bracket's vertical centre.
//   The model is BUILT with x+ = outboard (away from the panel), y+ = up, z = 0 = the front glass
//   plane, z- = toward the monitor's back; the monitor occupies x <= 0, -edge_thickness <= z <= 0.
//   OpenSCAD is right-handed, so with y up and z toward the viewer, x+ is the viewer's RIGHT:
//   built that way the pod is for the monitor's RIGHT edge. `side` mirrors every part at the
//   selector, so on side = "left" (the default, the owner's install) the exported world has the
//   monitor at x >= 0 and the pod outboard toward x-. Never flip a printed part instead: turned
//   upside down the slot's closed end is at the bottom and the pod slides off the rail.
//
// Export one part:  openscad --backend=manifold -o pod.stl -D 'part="pod"' desk_dial_pod.scad
// Parts: pod | pod_round | pod_root | bracket | coupon | assembly | envelope   (+ test-only intersections)
//   pod_round_print / pod_root_print: the two pod pieces turned onto their print faces (what make exports)

part = "assembly";
unseat = 0;               // test-only: how far above seated the pod sits in pod_x_bracket_at
probe_d = 43;             // test-only: the disc rib_probe_x_pod tries against the seat ribs
side = "left";             // which monitor edge the pod sits on, seen from the chair: "left" | "right"

// ── Measured on the owner's Odyssey OLED G9 (G95SD) ──────────────────────────
edge_thickness = 5.65;   // front glass -> back cover at the left edge, eye level (owner, ruler)
                         // [OWNER] confirm the back stays this deep ~30 mm inboard (bracket footprint)

// ── Fit (tune from the coupon) ────────────────────────────────────────────────
edge_gap            = 1.0;   // bracket lip thickness = gap between panel edge and pod
lip_depth           = 2.5;   // lip reach forward of the back plane; <= edge_thickness - 2 (off the glass)
slide_clearance     = 0.25;  // per side, dovetail slot over rail
magnet_fit          = 0.15;  // per side, magnet in its pocket (glued, so a slip fit)
board_seat_d        = 44.1;  // the circle the screen (glass + PCB) fits inside: the seat band at the front of
                             // the cavity. Owner, 2026-11-13: +1 mm (was 43.1) — too tight on the two-colour
                             // round, which came apart taking the screen out. Earlier: 2026-11-06 the owner set
                             // 43.1; coupons (2026-11-03) 43.58 loose, 42.5 too tight, 42.95 loose -> 42.90.
seat_len            = 4;     // depth of that band behind the face; the rest of the bore is loose
// Crush ribs (owner, 2026-11-13: "perfectly centred"). The band is now clear of the screen; these ribs
// stand out of it and do the gripping. Their tips sit on one circle round the screen centre, so they
// centre it exactly, but only the narrow tips touch: they give a little instead of straining the ring
seat_rib_d          = 43.1;  // the circle the rib tips sit on: the old band's snug size. Loose: lower by 0.05
seat_ribs           = 6;     // evenly spaced
seat_rib_w          = 1.6;   // the rib's base width (a triangle, its tip rounded)
seat_rib_lead       = 1.0;   // lead-in at the back of each rib, so the screen starts on them square
cap_clearance       = 0.15;  // per side, back cap in its opening (friction fit)
// Pry point, bottom centre (owner, 2026-11-13: the old shallow notch in the cap gave a flathead nothing
// to lever on). A slot through the pod's bottom rim lets the blade in, and an undercut in the cap's edge,
// behind a lip, takes its tip: hook under the lip, rock the handle on the slot's front edge, the cap lifts
pry_w      = 7;     // across (x): a 3-6 mm flathead
pry_slot_d = 3.5;   // the rim slot, from the back face forward
pry_lip    = 1.5;   // the cap's lip behind the undercut (what the tip lifts)
pry_hook   = 1.5;   // how far the undercut reaches into the cap, past its edge
pry_hook_h = 1.5;   // the undercut's height (z): room for the blade's tip

// ── Electronics: Seeed Round Display for XIAO v1.1 with the XIAO ESP32S3 plugged in ─────────
// Depths are the owner's calipers (2026-11-03), measured from the FRONT of the cover glass. Positions
// on the board are Seeed's v1.1 Eagle board file (wiki download), checked against the owner's
// measurement of the screw triangle. Board coordinates (bx, by) are Eagle's top layer, which is the
// BACK of the board (the XIAO side) seen from behind; in this build frame a board point sits at
// (cx + bx, by). After the left-edge mirror that puts the XIAO's USB-C toward the monitor with the
// image upright: Seeed's own orientation (USB-C right, power switch lower left, seen from the front).
board_d           = 42.98;  // PCB ø (owner). Retailer listings said ø39, which would never have fit
glass_d           = 43;     // cover glass ø; it covers the three screw holes (owner)
screen_active_d   = 32.4;   // 1.28" round panel
lcd_t             = 4.8;    // glass front -> PCB front (owner)
pcb_t             = 1.2;    // [assumed] PCB thickness; only sets where the coin-cell holder starts
standoff_depth    = 8.3;    // glass front -> top of the brass M2 standoffs on the back (owner)
usb_depth         = 16.57;  // glass front -> USB-C centreline (owner)
board_stack_depth = 18.0;   // glass front -> deepest point of anything: the USB-C shell (owner)
// Three brass M2 threaded standoffs (board file J8 / J6 / J7). Owner: the triangle across their
// OUTSIDE edges is 40.5 / 40.5 / 27.2 with ø3.5 standoffs, i.e. 37.0 / 37.0 / 23.7 centre to
// centre; the board file gives 36.99 / 36.99 / 23.62. Test-pinned.
mount_holes  = [[0, 19.431], [11.811, -15.621], [-11.811, -15.621]];
standoff_od  = 3.5;
xiao_c       = [-9.652, 0];        // XIAO centre: midpoint of its two header sockets (board file J4/J5)
xiao_size    = [21, 17.8];         // XIAO ESP32S3 PCB; its USB-C is at the bx- end, at the board rim
usb_mouth_bx = -21.0;              // [estimate] USB-C opening: XIAO edge at -20.15 + ~0.85 of connector
coin_c = [7.008, 11.959];  coin_rot = 148.9;  coin_size = [15.3, 8.6];       // CR927 holder footprint (board file BAT1)
coin_top_depth    = 7.8;    // glass front -> top of the coin-cell holder (owner): 0.5 in FRONT of the
                            // standoff tops, so the cap's posts (which start there) can't reach it
// USB-C: a right-angle male->female ADAPTER in the XIAO, its socket facing DOWN out of the bottom of the
// root (owner, 2026-11-09). Any length of desk cable plugs straight up into the pod; nothing hangs off
// the bracket. It must be the SIDE-bend kind (bends within the plug's flat plane, "left/right angle"),
// so with the plug pointing at the monitor the socket points at the floor. The adapter is a block: the
// plug leaves one long side near its closed end, the socket is in the far end. [OWNER] all [est] values
// are estimates until the part arrives (2026-11-11): measure and re-export.
adp_plug_to_socket = 21;  // owner, 2026-11-12: 1 mm longer than the 20 first assumed (the socket stood 1 mm below the
                          // cap's tab on the test fit). The male plug's OUTER edge (the shell's edge farthest from the socket) ->
                          // the socket face (the bottom edge of the female opening). THE measurement that
                          // places the socket: plug centre -> socket face = this - usb_plug_w / 2
adp_above_plug = 1.5;  // [est] how far the block reaches past the plug's outer edge (its closed end)
usb_plug_w     = 8.4;  // USB-C plug shell width (spec 8.25 + tolerance): where the outer edge is
adp_len        = adp_above_plug + adp_plug_to_socket;   // the block, closed end -> socket face
socket_recess  = 1.5;  // the socket face sits this far up inside the root's bottom: the root's bottom rises
                       // to meet a short adapter, so the desk cable's grip never has to reach deep into the pod.
                       // 1.5 leaves a ledge round the opening for the pocket's floor
adp_w          = 18.5; // the block's width along the plug axis (mouth -> the block's far side). Owner, 2026-11-12:
                       // the real adapter reaches 6 mm further toward the monitor than the 12.5 estimate
adp_t          = 8.1;  // the block's thickness (z). Owner, 2026-11-12: 1.1 mm more than the 7 estimate, all of it
                       // on the BACK (cap) side, so the cap's tab hit it on the test fit
adp_socket_x   = 12.0; // the mouth -> the socket's CENTRE (along x). Owner, 2026-11-13: the socket is NOT centred
                       // in the block (that assumption, adp_w / 2, left a 4.65 mm gap on its mouth side and its far
                       // edge behind the opening's wall). From that print: opening edge at mouth - 2.85, + 4.65,
                       // + half the 8.94 USB-C shell = mouth - 12.0
adp_t_front    = 3.5;  // plug centreline -> the block's front face (glass side); the rest of adp_t is behind it
adp_fit        = 0.35; // per side, the block in its pocket (0.15 jammed on the test fit, 2026-11-12). Still snug
                       // enough that the push of plugging in lands on plastic
adp_cap_gap    = 0.4;  // the cap's inside face behind the block (0.2 pressed on the adapter, 2026-11-12)
// the desk cable's male plug (its moulded grip), which has to reach up through the opening to the socket
desk_plug_w    = 13;   // [est] grip width (along x). Was 12: the opening is sized from this, give the cable room
desk_plug_t    = 7.0;  // [est] grip thickness (z). Was 6.5. 7.0 + fit = an 8 mm opening, the most that keeps
                       // a wall to the dovetail slot just in front of it
desk_plug_len  = 15;   // [est] grip length below the socket face, seated
desk_plug_fit  = 0.5;  // per side, the opening round the grip
usb_cable_d    = 4.5;  // [est] the desk cable
// The I2C cable to the knob housing (owner, 2026-11-10): one permanent run of 24 AWG 4-conductor cable
// (UL2464 24/4), soldered to the XIAO, no connector at the pod. It presses in from the root's BACK into a
// groove beside the adapter pocket: a round channel a hair under the cable, behind two lips narrower than
// it, so it snaps in and the jacket is gripped along the groove. A tug lands on plastic, never on the
// solder joints. The jacket stops at the window at the groove's top, where the wires cross into the pocket.
i2c_cable_d    = 4.3;  // the owner's cable, measured
i2c_grip       = 0.2;  // the channel is this much under the cable: it squeezes the jacket (tune: coupon)
i2c_snap_w     = 3.6;  // the slot the cable presses in through, at the root's back (tune: coupon)
i2c_lip        = 1.6;  // the lips' depth: the root's back face -> the channel
i2c_wall       = 1.6;  // between the groove and the adapter pocket, below the window
i2c_window     = 5;    // at the groove's top it opens into the adapter pocket for the bare wires
// M2 screws hold the board to the cap's posts, into the brass standoffs, from the back of the cap
screw_len    = 14;     // M2 x 14 pan head
screw_engage = 2.0;    // thread into the standoff; the tip must stop short of the PCB's front (glass!)
screw_head_d = 3.8;  screw_head_h = 1.6;
post_od      = 4.2;

// ── Shape ─────────────────────────────────────────────────────────────────────
rim           = 3;         // plastic around the screen's circle (board_seat_d) -> the face's outer edge
                           // (owner, 2026-11-06: the ~6 mm of the first gauge print was too much). The
                           // 2 mm edge rounding (round_r) is part of it, so ~1 mm of it reads as flat face
wall          = 2.0;
face_t        = 1.2;       // skin in front of the display
face_shape    = "gauge";   // "gauge" = a round face around the round screen (owner's pick, 2026-11-03);
                           // "tile" = the earlier rounded square, board_d + 2*wall + 30 tall
gauge_d       = board_seat_d + 2 * rim;                  // 50.1: the face is sized by the rim now
visible_width = face_shape == "gauge" ? edge_gap + slide_clearance + gauge_d : 60;   // outboard extent from x = 0
pod_h         = face_shape == "gauge" ? gauge_d : board_d + 2 * wall + 30;
pod_depth     = 25.6;      // front face -> back of the swell. Was 23, which left the cap's tab over the
                           // USB-C plug 1.2 mm thick and it kept snapping off the coupon (owner,
                           // 2026-11-06); the plug's back is fixed by the adapter, so depth is the only lever.
                           // 24.5 -> 25.6 (2026-11-12): the real adapter's back sits 1.1 deeper (22.4), and
                           // this keeps the tab at ~3 mm
round_r       = 2.0;       // 3D edge rounding
plan_r        = face_shape == "gauge" ? gauge_d / 2 - 0.05 : 8;   // corner radius seen from the front (gauge: a circle)
profile_n     = 3;         // superellipse exponent of the top-view profile: 2 = ellipse (tapers more), higher = boxier

// ── Looks (owner, 2026-11-12, #227) ───────────────────────────────────────────
window_bevel  = face_t;    // the screen window's edge is a 45 deg bevel this wide (= the skin, so it runs the
                           // whole edge): the bezel reads thinner and the glass looks set in. The back of the
                           // window, the lip that holds the glass, is unchanged
accent        = true;      // a ring round the window in a second filament (AMS). Exported as its own part
accent_w      = 1.2;       // the ring's width on the face, outward from the bevel's crest
accent_t      = 0.48;      // its depth: 3 layers at the face's 0.16 mm. The bevel's top 0.48 mm is part of it,
                           // so the colour wraps over the window's edge
stem_r        = 20;        // the concave sweep that blends the socket block below the gauge into the round:
                           // the block reads as a stem the gauge grows from, not a box bolted on
seam_reveal   = 0.5;       // a deliberate shadow line at the round/root glue seam: the root steps back this
seam_reveal_d = 1.0;       // much from the shell, this deep from its outside, so the seam (and any glue
                           // squeeze-out) reads as a designed groove. The glue faces behind it are unchanged

// ── Command strip / bracket ───────────────────────────────────────────────────
strip_w = 19;  strip_l = 70;  strip_t = 1.6;   // one medium Command strip pad — verify against the pack
plate_t = 3.0;
plate_h = max(strip_l + 2 * wall, pod_h + 1);   // never shorter than the pod: the cable clip hangs off the
                                                 // plate's bottom edge and must stay BELOW the pod (a ø43 board
                                                 // made the pod 77 tall and its root landed in the clip)
plate_w = strip_w + 2 * wall;
rail_x      = -9;          // rail centre (behind the panel)
rail_depth  = 4;
rail_w_base = 8;           // at the plate
rail_w_tip  = 11;          // wider at the tip = dovetail
rail_len    = -1;          // full-section length of the rail, down from its top (the pod's stop). -1 = run it
                           // down to just below the pod root's bottom (40.6 today), so the whole slot
                           // engages. Shorter is fine: the pod rides on the top part. Min rail_len_min.
rail_len_min = 15;         // never shorter than this: the magnet sits 6 mm down, and the dovetail needs grip
rail_ramp   = 8;           // the taper below the full section, down into the plate (0 = square end)
channel_w   = usb_cable_d + i2c_cable_d + 1;   // cable channel: USB-C + I2C side by side (9.8)
channel_x   = -8;          // clip centre: under the adapter's socket, but wholly behind the panel (x < 0)
// Bracket styling (owner, 2026-11-09: "less clunky, taper and round the edges"). None of these move a
// working surface: the lip's straight run, the strip pocket, the rail under the pod and the clip's
// cable hole are all where they were.
bracket_r     = 4;         // plan-view corner radius of the plate
bracket_taper = 1.5;       // the plate's rear edge is chamfered this much at 45 deg: reads as a thin plate
clip_h        = 16;        // cable clip, hanging below the plate
clip_drop     = 4;         // gap between the plate's strip area and the clip: room for the desk cable to bend
                           // inboard from under the pod's socket (straddling the panel edge) to behind the panel
clip_r        = 2.5;       // the clip's corner rounding (seen from below)
clip_sweep    = 6;         // the clip's bottom recedes this much from the plate to its back bar
clip_gap      = 2;         // the slit in the clip's back bar the cable presses through
strip_r       = 1;         // strip pocket corner radius (keeps a wall inside the plate's rounded corners)

$fn = 96;

// ── Derived ───────────────────────────────────────────────────────────────────
E      = edge_thickness;
gx     = edge_gap + slide_clearance;            // pod inner face
cx     = gx + (visible_width - gx) / 2;         // screen centre x
back_z = -E - plate_t;                          // plate rear face
root_front_z = back_z - slide_clearance;        // pod root may not come forward of this
slot_top  = pod_h / 2 - wall;
rail_top  = slot_top - slide_clearance;
tun_z0 = -pod_depth + wall;
// board stack, front to back (z)
pcb_front_z    = -face_t - lcd_t;
pcb_back_z     = pcb_front_z - pcb_t;
standoff_top_z = -face_t - standoff_depth;
usb_z          = -face_t - usb_depth;
stack_back_z   = -face_t - board_stack_depth;
cap_inner_z    = stack_back_z - 0.5;            // the cap's inside face over the board
// the plug, beside the board toward the monitor
usb_mouth_x  = cx + usb_mouth_bx;
plug_x0      = usb_mouth_x - adp_w;            // the adapter block's far side, toward the monitor
plug_front_z = usb_z + adp_t_front;
plug_back_z  = plug_front_z - adp_t;
plug_cap_z   = plug_back_z - adp_cap_gap;       // the cap's inside face over the adapter
adp_top_y    = usb_plug_w / 2 + adp_above_plug;     // the block's closed end (the plug's centre is at y = 0)
adp_bot_y    = usb_plug_w / 2 - adp_plug_to_socket; // its socket face
cable_x      = usb_mouth_x - adp_socket_x;      // the socket's centre (x): measured, not the block's middle
root_bot_y   = max(-pod_h / 2, adp_bot_y - socket_recess);   // the root's bottom: up to the socket, never below the face
open_w = min(adp_w + 2 * adp_fit, desk_plug_w + 2 * desk_plug_fit);   // the opening under the socket: the grip's
open_t = min(adp_t + 2 * adp_fit, desk_plug_t + 2 * desk_plug_fit);   // size, so whatever is left is a ledge
i2c_d     = i2c_cable_d - i2c_grip;                                  // the groove's channel
i2c_cx    = plug_x0 - adp_fit - i2c_wall - i2c_d / 2;                 // its centre: beside the pocket, past a wall
i2c_cz    = -pod_depth + i2c_lip + i2c_d / 2;                         // and just inside the root's back
root_round = 2;   // the root's edge radius (owner, 2026-11-12: "round all the right angles"). Set here, before
                  // root_x0 uses it; the rounding itself is in root()
root_x0   = min(rail_x - rail_w_tip / 2 - slide_clearance, i2c_cx - i2c_d / 2) - wall - root_round;   // wraps the slot and the
            // I2C groove; + root_round so the rounded back edge never eats the groove's inboard lip (hidden behind the panel)
root_x1      = usb_mouth_x + 2.5;               // the root reaches outboard far enough to box the plug in
// Only the inboard part of the board's back is deep (the XIAO and its USB-C). Outboard of this line there
// is nothing taller than the standoffs, so the cap fills forward to shallow_z there: otherwise the bore
// would run back to where the pod's curved back thins out and leave a knife edge at the outboard rim.
deep_x       = cx + 12;
shallow_z    = standoff_top_z - 2.5;
// the screws: head seat, and the tip that must stay inside the standoff + PCB
screw_seat_z = standoff_top_z - (screw_len - screw_engage);
assert(standoff_top_z + screw_engage < pcb_front_z - 0.3, "screw tip would pass the PCB front and hit the glass");
assert(screw_seat_z < cap_inner_z - 1.0, "screw too short: its head would seat inside the cavity, not on the cap");
assert(-pod_depth < plug_cap_z - 1.0, "no room for the cap behind the plug: deepen the pod");
assert(rail_len < 0 || rail_len >= rail_len_min, str("rail_len ", rail_len, " is shorter than rail_len_min (", rail_len_min, ")"));
assert(i2c_snap_w < i2c_cable_d && i2c_d < i2c_cable_d, "the I2C groove must be narrower than the cable, or it doesn't grip");
assert(adp_socket_x + open_w / 2 <= adp_w + adp_fit + 0.5, "the cable opening runs past the far side of the adapter pocket");
assert(adp_bot_y >= -pod_h / 2, "the adapter is longer than the pod is tall: its socket would stick out of the bottom");
assert(adp_bot_y - root_bot_y <= desk_plug_len - 3, "socket too deep in the pod for the desk cable's grip to reach it");
// ── Magnet catch (replaced the snap bump, 2026-11-03) ──────────────────────────
// Two magnet discs face each other across the slide gap: one in the rail's tip face, one in the slot
// floor. The pod slides down with NO interference anywhere along its travel, and the magnets pull it in
// at the bottom. Why not a snap: a rigid bump on a solid block can't flex, so the first one gave no
// click (the dovetail's play swallowed it) and the bigger one snapped off. And forcing a pod over a
// bump pries the bracket off its Command strip, which holds well only in straight shear.
// The pod's magnet sits magnet_preload ABOVE the rail's when seated, so their pull to line up presses
// the pod DOWN onto its stop (straight shear on the strip) instead of floating it.
magnet_d       = 6;      // N52 disc, 6 x 3 mm
magnet_t       = 3;
magnet_recess  = 0.2;    // each magnet's face sits this far below its surface, so faces never scrape
magnet_preload = 0.25;
magnet_y = slot_top - 6;                                  // rail magnet centre (pod frame = rail frame)
seat_drop = slide_clearance;                              // seated, the slot's top rests on the rail's top
magnet_pod_y = magnet_y + seat_drop + magnet_preload;     // pod magnet centre, in the pod's own frame

module monitor_envelope() {
    translate([-200, -150, -E]) cube([200, 300, E]);
}

module xz_extrude(h) {            // 2D (x, z) profile -> 3D, extruded along y, centred
    rotate([90, 0, 0]) linear_extrude(height = h, center = true) children();
}

// ── Bracket ──────────────────────────────────────────────────────────────────
// magnet pockets, open on the sliding faces; g grows them radially and deeper only (wall checks)
module rail_magnet_pocket(g = 0) {   // from the rail's tip face toward the plate
    translate([rail_x, magnet_y, back_z - rail_depth - 0.01]) rotate([0, 0, 0])
        cylinder(d = magnet_d + 2 * magnet_fit + 2 * g, h = magnet_t + magnet_recess + 0.01 + g, $fn = 48);
}
module pod_magnet_pocket(g = 0) {    // from the slot floor back into the root
    floor_z = back_z - rail_depth - slide_clearance;
    translate([rail_x, magnet_pod_y, floor_z - magnet_t - magnet_recess - g])
        cylinder(d = magnet_d + 2 * magnet_fit + 2 * g, h = magnet_t + magnet_recess + 0.01 + g, $fn = 48);
}
module rail_magnet()       { translate([rail_x, magnet_y, back_z - rail_depth + magnet_recess]) cylinder(d = magnet_d, h = magnet_t, $fn = 48); }
module pod_magnet_seated() { translate([rail_x, magnet_pod_y - seat_drop, back_z - rail_depth - slide_clearance - magnet_recess - magnet_t])
                                 cylinder(d = magnet_d, h = magnet_t, $fn = 48); }

module rail_2d(grow = 0) {        // (x, z) cross-section of the dovetail rail
    offset(delta = grow) polygon([
        [rail_x - rail_w_base / 2, back_z + 0.01],
        [rail_x + rail_w_base / 2, back_z + 0.01],
        [rail_x + rail_w_tip / 2, back_z - rail_depth],
        [rail_x - rail_w_tip / 2, back_z - rail_depth]]);
}

module rail() {                   // full section under the pod, then a ramp down into the plate below it
    rail_low = rail_len < 0 ? root_bot_y - 1 : rail_top - rail_len;   // the full section's bottom
    difference() {
        union() {
            translate([0, (rail_top + rail_low) / 2, 0]) xz_extrude(rail_top - rail_low) rail_2d();
            hull() {
                translate([0, rail_low + 0.005, 0]) xz_extrude(0.01) rail_2d();
                translate([rail_x - rail_w_base / 2, rail_low - rail_ramp, back_z]) cube([rail_w_base, 0.01, 0.01]);
            }
        }
        rail_magnet_pocket();
    }
}

clip_x0 = channel_x - channel_w / 2 - wall;   // the clip's outer walls
clip_x1 = channel_x + channel_w / 2 + wall;
clip_y0 = -plate_h / 2 - clip_drop - clip_h;   // the clip's bottom

// The plate seen from behind, (x, y): a rounded shield that tapers from the plate down into the clip.
// t insets every edge except the lip's, which stays straight and full length for registration.
module plate_plan_2d(t = 0) {
    hull() {
        for (yy = [plate_h / 2 - bracket_r, -plate_h / 2 + bracket_r]) {
            translate([edge_gap - (bracket_r - t), yy]) circle(r = bracket_r - t);
        }
        for (yy = [plate_h / 2 - bracket_r, -plate_h / 2 + bracket_r]) translate([-plate_w + bracket_r, yy]) circle(r = bracket_r - t);
        for (xx = [clip_x0 + clip_r, clip_x1 - clip_r]) translate([xx, clip_y0 + clip_r]) circle(r = clip_r - t * 0.6);
    }
}

module plate() {                  // full outline against the monitor, chamfered back to the inset outline
    hull() {
        translate([0, 0, -E - (plate_t - bracket_taper)]) linear_extrude(plate_t - bracket_taper) plate_plan_2d();
        translate([0, 0, back_z]) linear_extrude(0.01) plate_plan_2d(bracket_taper);
    }
}

// the cable clip seen from below, (x, z): a rounded U-frame behind the plate, its back bar split
module clip_2d() {
    offset(r = 0.6) offset(delta = -0.6) difference() {
        translate([clip_x0, tun_z0 - wall]) offset(r = clip_r) offset(delta = -clip_r)
            square([clip_x1 - clip_x0, back_z + plate_t / 2 - tun_z0 + wall]);
        translate([channel_x - channel_w / 2, tun_z0]) offset(r = 1) offset(delta = -1)
            square([channel_w, back_z - tun_z0 + 0.01]);
        translate([channel_x - clip_gap / 2, tun_z0 - wall - 1]) square([clip_gap, wall + 1.01]);
    }
}

module clip() {                   // its bottom sweeps up toward the back, so it reads as a hook, not a box
    intersection() {
        translate([0, clip_y0 + (clip_h + 1) / 2, 0]) xz_extrude(clip_h + 1) clip_2d();
        rotate([90, 0, 90]) translate([0, 0, -100]) linear_extrude(200) polygon([
            [clip_y0, -E + 1], [clip_y0 + clip_sweep, tun_z0 - wall - 1],
            [-plate_h / 2 + 1, tun_z0 - wall - 1], [-plate_h / 2 + 1, -E + 1]]);
    }
}

module bracket() {
    difference() {
        union() {
            plate();
            // lip: registers the gap against the panel's side frame, never reaching the glass. Its ends
            // follow the plate's rounded corners.
            intersection() {
                translate([0, -plate_h / 2, back_z]) cube([edge_gap, plate_h, plate_t + lip_depth]);
                translate([0, 0, back_z - 1]) linear_extrude(plate_t + lip_depth + 2) plate_plan_2d();
            }
            rail();
            clip();
        }
        strip_pocket();
    }
}

// strip pocket on the monitor-facing side, a hair shallower than the pad so it compresses
module strip_pocket(g = 0) {
    translate([-plate_w + wall, -strip_l / 2, -E - (strip_t - 0.3)])
        linear_extrude(strip_t) offset(delta = g) offset(r = strip_r) offset(delta = -strip_r) square([strip_w, strip_l]);
}

// ── Pod ──────────────────────────────────────────────────────────────────────
module profile_2d() {             // seen from above, (x, z): thin at the panel and at the outer edge,
    // full depth behind the board. A superellipse (n = 3): boxier than an ellipse, so the board seat
    // keeps its wall, while both ends still taper. Widest point sits round_r + 1 behind the face so
    // the edge rounding never trims the visible width.
    c  = round_r + 1;
    ax = (visible_width - gx) / 2;
    az = pod_depth - c;
    n  = profile_n;
    pts = [for (i = [0:179]) let(t = i * 2, cs = cos(t), sn = sin(t),
                                  px = sign(cs) * pow(abs(cs), 2 / n), pz = sign(sn) * pow(abs(sn), 2 / n))
           [cx + ax * px, -c + az * pz]];
    intersection() {
        hull() {
            // inboard edge: full depth back to the root's front. With the 3 mm rim the screen sits ~5 mm
            // closer to the monitor and the XIAO's USB-C end is under this corner; reaching only to the
            // panel's back (-E) left it under 1 mm of wall
            translate([gx, root_front_z]) square([3, -root_front_z]);
            polygon(pts);
        }
        translate([gx, -pod_depth]) square([visible_width, pod_depth]);
    }
}

module plan_2d() {                // seen from the front, (x, y)
    offset(r = plan_r) offset(delta = -plan_r)
        translate([gx, -pod_h / 2]) square([visible_width - gx, pod_h]);
}

module shell_outer(g = 0) {       // g grows it all round (the two-piece split's glue gap)
    minkowski() {
        intersection() {
            xz_extrude(pod_h) offset(delta = -round_r) profile_2d();
            translate([0, 0, -pod_depth - 1]) linear_extrude(pod_depth + 2) offset(delta = -round_r) plan_2d();
        }
        sphere(r = round_r + g, $fn = 24);
    }
}

module root() {                   // behind the panel; carries the dovetail slot and boxes the adapter in. Its
    // bottom rises to socket_recess below the adapter's socket (the round face below it is unchanged)
    // Every edge is rounded (owner, 2026-11-12: "round all the right angles, make it slick"): the block is
    // shrunk by root_round all round, then grown back with a ball, so it keeps its size but every convex
    // edge and corner becomes a root_round arc. Only the outer solid is rounded; the slot, pockets and
    // groove are cut afterwards, so their working faces stay sharp and true.
    minkowski() { root_core(); sphere(r = root_round / cos(180 / 32), $fn = 32); }   // a $fn=32 sphere's poles/equator fall
}                                                 // short by cos(180/32): undo it, so the flat faces land where they did
module root_core(e = root_round) {   // the root shrunk by e all round (what the rounding ball rolls over)
    translate([0, 0, -pod_depth + e]) linear_extrude(pod_depth + root_front_z - 2 * e) offset(r = -e) root_outline_2d();   // r, not delta: a delta offset
    // miters every sliver vertex out into a spike
}
// The root seen from the front (x, y), extruded through its depth: the box, trimmed to the round's circle
// outboard of the panel, plus the stem.
module root_outline_2d() {
    intersection() {
        root_keep_2d();
        translate([root_x0, root_bot_y]) square([root_x1 - root_x0, pod_h / 2 - root_bot_y]);
    }
    stem_2d();
}
// The stem (#227): where the socket block's bottom meets the round, a concave sweep of radius stem_r
// carries one into the other. Kept clear of the desk cable's opening (stem_x0) so the grip still goes in.
stem_x0 = cable_x + max(open_w, desk_plug_w + 2 * desk_plug_fit) / 2 + 1.5;
module stem_2d() {                 // only the web between the block's bottom and the circle, never the circle itself
    offset(r = 0.4) offset(r = -0.4)   // drops the hair-thin slivers the circle's subtraction leaves along the arc
    difference() {                 // (the root behind the round's own back would be a slab the dome doesn't have)
        intersection() {
            offset(r = -stem_r) offset(r = stem_r) union() {
                translate([cx, 0]) circle(r = root_keep_r);
                translate([root_x0 - 10, root_bot_y]) square([root_x1 - root_x0 + 10, root_pocket_top - root_bot_y]);
            }
            translate([stem_x0, -pod_h / 2]) square([cx - stem_x0, root_bot_y + 3 + pod_h / 2]);
        }
        translate([cx, 0]) circle(r = root_keep_r - 0.01);
    }
}
root_fillet      = 4;     // the inside corners seen from the front (where the pocket block meets the circle)
// Seen from the front, the root may only show where the panel hides it (x <= 0). Outboard of the panel edge
// it is only the block round the adapter pocket, which the XIAO's USB-C puts partly outboard of the edge;
// that block gets a rounded outboard corner and the stem below. Before this (owner, 2026-11-12) the root's
// square top corner stood up past the round's curve.
root_keep_r      = gauge_d / 2;                        // the round's silhouette (the stem sweeps into it)
root_pocket_top  = max(adp_top_y + adp_fit + 3,        // the pocket box: the ceiling over the adapter + the I2C window,
                       xiao_size[1] / 2 + 0.5 + wall);  // and high enough to back the XIAO's corners (the shell is thin there)
root_corner_r    = 2;
module root_keep_2d() { offset(r = -root_fillet) offset(r = root_fillet) {   // fillet the inside corners
    translate([root_x0 - 10, -100]) square([10 - root_x0, 200]);      // behind the panel: all of it
    // outboard of the panel: only the pocket block. Trimming a bigger root to the round's circle left a feather
    // edge where it wrapped the dome's tapering back (#227), so above the block the round's own back shows
    offset(r = root_corner_r) offset(delta = -root_corner_r)            // and the pocket box, corner rounded
        translate([root_x0 - 10, root_bot_y]) square([root_x1 - root_x0 + 10, root_pocket_top - root_bot_y]);
} }

// ── The board and what's on its back (envelopes, for the clearance checks) ──
function bpt(b) = [cx + b[0], b[1]];
module board_body(d = board_d) {   // glass + LCD + PCB as one disc, at the real board size (the seat is looser since 2026-11-13)
    translate([cx, 0, pcb_back_z]) cylinder(d = d, h = -face_t - pcb_back_z);
}
module board_components() {       // everything standing off the PCB's back
    // the XIAO on its header sockets, all the way back to the deepest point
    translate([bpt(xiao_c)[0] - xiao_size[0] / 2, -xiao_size[1] / 2, stack_back_z]) cube([xiao_size[0], xiao_size[1], pcb_back_z - stack_back_z]);
    translate([usb_mouth_x, -4.5, usb_z - 1.7]) cube([bpt(xiao_c)[0] - xiao_size[0] / 2 - usb_mouth_x + 0.01, 9, 3.4]);   // USB-C past the XIAO edge
    coin_top_z = -face_t - coin_top_depth;
    translate([bpt(coin_c)[0], coin_c[1], (pcb_back_z + coin_top_z) / 2]) rotate([0, 0, coin_rot])
        cube([coin_size[0], coin_size[1], pcb_back_z - coin_top_z], center = true);
    for (h = mount_holes) translate([bpt(h)[0], h[1], standoff_top_z]) cylinder(d = standoff_od, h = pcb_back_z - standoff_top_z, $fn = 32);
}
module plug_envelope() {          // the adapter block, seated in the XIAO, socket down
    translate([plug_x0, adp_bot_y, plug_back_z]) cube([adp_w, adp_len, adp_t]);
}
// the desk cable: its grip up in the opening against the socket face, then the cable down into the clip.
// In the clip the two cables lie side by side: USB-C on the panel side, I2C outboard of it.
usb_clip_x = channel_x + channel_w / 2 - usb_cable_d / 2 - 0.25;
i2c_clip_x = channel_x - channel_w / 2 + i2c_cable_d / 2 + 0.25;
cable_pts = [[cable_x, adp_bot_y - desk_plug_len, usb_z], [cable_x, adp_bot_y - desk_plug_len - 2, usb_z],
             [usb_clip_x, -plate_h / 2 - clip_drop + 1, usb_z], [usb_clip_x, -plate_h / 2 - clip_drop - clip_h - 3, usb_z]];
// the I2C cable from where it leaves the groove (just below the root) down into the clip. It hangs straight
// down past the desk cable's grip first (the socket moved toward the monitor, 2026-11-13, and the grip
// now sits over the groove's line), then swings in under it
i2c_pts   = [[i2c_cx, root_bot_y - i2c_cable_d / 2 - 0.1, i2c_cz],
             [i2c_cx, adp_bot_y - desk_plug_len - i2c_cable_d / 2 - 0.5, i2c_cz],
             [i2c_clip_x, -plate_h / 2 - clip_drop + 2, usb_z],
             [i2c_clip_x, -plate_h / 2 - clip_drop + 1, usb_z], [i2c_clip_x, -plate_h / 2 - clip_drop - clip_h - 3, usb_z]];
module desk_plug() { translate([cable_x - desk_plug_w / 2, adp_bot_y - desk_plug_len, usb_z - desk_plug_t / 2]) cube([desk_plug_w, desk_plug_len, desk_plug_t]); }
module path_of(pts, d) { for (i = [0 : len(pts) - 2]) hull() for (q = [pts[i], pts[i + 1]]) translate(q) sphere(d = d, $fn = 24); }
module usb_cable_path() { desk_plug(); path_of(cable_pts, usb_cable_d); }
module i2c_cable_path() { path_of(i2c_pts, i2c_cable_d); }
module cable_path() { usb_cable_path(); i2c_cable_path(); }
module socket_opening(g = 0) {    // through the root's bottom, up to the socket face
    translate([cable_x - open_w / 2 - g, root_bot_y - 5, usb_z - open_t / 2 - g])
        cube([open_w + 2 * g, adp_bot_y - root_bot_y + 5 + 0.01, open_t + 2 * g]);
}
module i2c_channel(g = 0) {       // the press-in groove, open to the root's back and out of its bottom
    top = adp_top_y + adp_fit;
    translate([i2c_cx, -pod_h / 2 - 5, i2c_cz]) rotate([-90, 0, 0]) cylinder(d = i2c_d + 2 * g, h = top + pod_h / 2 + 5, $fn = 32);
    translate([i2c_cx - i2c_snap_w / 2 - g, -pod_h / 2 - 5, -pod_depth - 1]) cube([i2c_snap_w + 2 * g, top + pod_h / 2 + 5, i2c_cz + pod_depth + 1]);
    // the window: through the wall into the adapter pocket, for the bare wires
    translate([i2c_cx, top - i2c_window - g, plug_back_z - adp_fit - g])
        cube([plug_x0 - adp_fit - i2c_cx + 0.01, i2c_window + g, i2c_cz + i2c_d / 2 - (plug_back_z - adp_fit) + g]);
}
// the adapter's pocket seen from behind: the block, plus the receptacle end in front of the mouth. Snug on
// every side, and closed above, so plugging the desk cable in pushes the block onto plastic, not the XIAO
module plug_2d(g = 0) {
    translate([plug_x0 - adp_fit - g, adp_bot_y - adp_fit - g]) square([adp_w + 2 * adp_fit + 2 * g, adp_len + 2 * adp_fit + 2 * g]);
    // where the plug leaves the XIAO: its shell and the adapter's collar. 3.5 toward the board and the full
    // plug height + 1.5 (was 2.5 x 10: the collar sat on the cap's step there, 2026-11-12)
    translate([usb_mouth_x - 0.5 - g, -usb_plug_w / 2 - 1.5 - g]) square([3.5 + 2 * g, usb_plug_w + 3 + 2 * g]);
}
module deep_2d(g = 0) { intersection() { board_2d(g); translate([-100, -100]) square([100 + deep_x + 0.05, 200]); } }   // overlaps shallow_2d: no zero-thickness wall
module shallow_2d(g = 0) { difference() { board_2d(g); translate([-100, -100]) square([100 + deep_x, 200]); } }
module board_2d(g = 0) { translate([cx, 0]) circle(d = board_d + 0.6 + 2 * g); }   // loose: drops in from the back
module keyhole_2d(g = 0) { union() { board_2d(g); plug_2d(g); } }   // the back opening: board + plug beside it

module outer_solid() { union() { shell_outer(); root(); } }

module board_cavity(g = 0) {      // grows radially and backward only — the front is the screen window
    // loose bore from the cap (deep over the XIAO, shallow outboard), then a snug seat band just behind
    // the face that grips the glass + PCB
    translate([0, 0, cap_inner_z - 0.01 - g]) linear_extrude(-face_t - seat_len - cap_inner_z + 0.02 + g) deep_2d(g);
    translate([0, 0, shallow_z - 0.01 - g]) linear_extrude(-face_t - seat_len - shallow_z + 0.02 + g) shallow_2d(g);
    translate([cx, 0, -face_t - seat_len - 0.01]) cylinder(d = board_seat_d + 2 * g, h = seat_len + 0.02 - (g > 0 ? face_t : 0));
}
// The XIAO's USB-C end, past the round PCB: its board corners (17.8 wide) and the narrower USB-C shell,
// each + 0.5. Two rectangles, not one box around both: with the 3 mm rim the round face's edge runs
// close here, and the box's empty corners were what thinned the wall.
xiao_end_x = cx + xiao_c[0] - xiao_size[0] / 2;
module xiao_end_2d(g = 0) {
    translate([xiao_end_x - 0.5 - g, -xiao_size[1] / 2 - 0.5 - g]) square([usb_mouth_x + 2.5 - xiao_end_x + 2 * g, xiao_size[1] + 1 + 2 * g]);
    translate([usb_mouth_x - 0.5 - g, -4.5 - 0.5 - g]) square([3 + 2 * g, 10 + 2 * g]);
}
module plug_cavity(g = 0) {
    translate([0, 0, plug_cap_z - 0.01 - g]) linear_extrude(plug_front_z + 0.5 - plug_cap_z + 0.02 + 2 * g) plug_2d(g);
    // the XIAO's USB-C end stands proud of the round PCB at its corners, from the PCB back to the stack back
    translate([0, 0, plug_cap_z - 0.01 - g]) linear_extrude(pcb_back_z - plug_cap_z + 0.02 + g) xiao_end_2d(g);
}
module back_hole() {              // board + plug go in together from the back; the cap closes it
    translate([0, 0, -pod_depth - 1]) linear_extrude(pod_depth + 1 + cap_inner_z + 0.01) board_2d();
    translate([0, 0, -pod_depth - 1]) linear_extrude(pod_depth + 1 + shallow_z + 0.01) shallow_2d();   // the cap fills it
    translate([0, 0, -pod_depth - 1]) linear_extrude(pod_depth + 1 + plug_cap_z + 0.01) plug_2d();
    tab_bridge(0);
}
// The wall between the plug pocket and the screen bore, beside the neck where the keyhole's rectangle meets its
// circle, left a wedge-shaped slot between the cap's tab and its round part (owner, 2026-11-22: the tab snapped
// off there). Through the cap's thickness only (up to plug_cap_z) that wall is cut out of the root and the cap
// fills it, so the tab joins the round part along the plug's whole length (~23 mm, was ~13). The round piece
// keeps its sliver of the wall (shell_outer is left alone), so only the root and the cap change.
module tab_bridge_2d(g = 0) {
    translate([usb_mouth_x - 0.5 - g, adp_bot_y - adp_fit - g]) square([cx - usb_mouth_x + 0.5 + 2 * g, adp_len + 2 * adp_fit + 2 * g]);
}
module tab_bridge(c) {            // c > 0: the cap's (shrunk by c, and c off the round piece); 0: the root's cut
    difference() {
        translate([0, 0, -pod_depth - 1]) linear_extrude(pod_depth + 1 + plug_cap_z + (c > 0 ? 0 : 0.01)) tab_bridge_2d(-c);
        difference() {            // the round shell, except where the cap already is (the board circle)
            shell_outer(c);
            translate([0, 0, -pod_depth - 2]) linear_extrude(pod_depth + 2 + plug_cap_z + 1) board_2d(-c);
        }
    }
}
module cap_footprint_solid(c) {   // the opening's own volume, shrunk by the fit clearance
    difference() {
        union() {
            translate([0, 0, -pod_depth - 1]) linear_extrude(pod_depth + 1 + cap_inner_z) board_2d(-c);
            translate([0, 0, -pod_depth - 1]) linear_extrude(pod_depth + 1 + shallow_z) shallow_2d(-c);
        }
        translate([0, 0, plug_cap_z]) linear_extrude(50) plug_2d(c);     // thin over the plug
    }
    translate([0, 0, -pod_depth - 1]) linear_extrude(pod_depth + 1 + plug_cap_z) plug_2d(-c);
    tab_bridge(c);
}
module screw_holes() {            // clearance through post + cap, and a counterbore for the head from the back
    for (h = mount_holes) translate([bpt(h)[0], h[1], 0]) {
        translate([0, 0, -pod_depth - 2]) cylinder(d = 2.4, h = pod_depth + 2 + standoff_top_z + 0.01, $fn = 24);
        translate([0, 0, -pod_depth - 2]) cylinder(d = screw_head_d + 0.4, h = pod_depth + 2 + screw_seat_z, $fn = 32);
    }
}
module pry_slot() {               // through the pod's bottom rim, open to the back and the bottom
    translate([cx - pry_w / 2, -pod_h / 2 - 1, -pod_depth - 1]) cube([pry_w, pod_h / 2 + 1 - board_d / 2 + 0.01, pry_slot_d + 1]);
}
module pry_undercut() {           // into the cap's edge, behind a lip at its back face
    translate([cx - pry_w / 2, -board_d / 2 - 1, -pod_depth + pry_lip]) cube([pry_w, pry_hook + 1, pry_hook_h]);
}
assert(pry_lip + pry_hook_h <= pry_slot_d, "the blade can't reach the undercut: it ends forward of the rim slot");
// Over the tab's joint the pod's outside dips: the root's rounded outboard back
// edge meets the round shell's receding dome in a valley deeper than the tab is thick (2.8 mm). Trimmed to
// that outside, the cap was cut nearly through there and the tab snapped off when the supports came off
// (owner, 2026-11-22). The cap fills that valley, along the tab's whole length, with the hull of the outside
// there: the tab keeps its full thickness into the round part. The fill never goes behind the back plane.
cap_joint_x = [usb_mouth_x - 3, usb_mouth_x + 9];   // the valley, across the joint (x)
module cap_joint_fill() {
    y0 = adp_bot_y - adp_fit - 1;  y1 = adp_top_y + adp_fit + 1;
    hull() intersection() {
        outer_solid();
        translate([cap_joint_x[0], y0, -pod_depth - 1]) cube([cap_joint_x[1] - cap_joint_x[0], y1 - y0, pod_depth + 1 + plug_cap_z]);
    }
}
module cap() {                    // closes the back flush with the pod's own curve, and carries the screen:
    // the board screws onto its three posts, so cap + screen come out as one unit
    difference() {
        union() {
            intersection() { union() { outer_solid(); cap_joint_fill(); } cap_footprint_solid(cap_clearance); }
            for (h = mount_holes) translate([bpt(h)[0], h[1], cap_inner_z - 0.01])
                cylinder(d = post_od, h = standoff_top_z - cap_inner_z + 0.01, $fn = 32);
        }
        screw_holes();
        pry_undercut();
    }
}
module screws() {                 // the three M2 screws, seated (for the clearance checks)
    for (h = mount_holes) translate([bpt(h)[0], h[1], 0]) {
        translate([0, 0, screw_seat_z]) cylinder(d = 2.0, h = screw_len, $fn = 16);
        translate([0, 0, screw_seat_z - screw_head_h]) cylinder(d = screw_head_d, h = screw_head_h, $fn = 24);
    }
}
module slot() {
    translate([0, (slot_top - pod_h / 2 - 1) / 2, 0]) xz_extrude(slot_top + pod_h / 2 + 1) rail_2d(slide_clearance);
}

win_d = screen_active_d + 1;     // the window at the glass: unchanged, it is the lip that holds the glass
module window() {                // with its 45 deg bevel out to the face
    translate([cx, 0, -face_t - 0.01]) cylinder(d = win_d, h = face_t - window_bevel + 0.02);
    translate([cx, 0, -window_bevel]) cylinder(d1 = win_d, d2 = win_d + 2 * window_bevel, h = window_bevel + 0.001);
    translate([cx, 0, -0.001]) cylinder(d = win_d + 2 * window_bevel + 0.002, h = 1);
}
accent_r = win_d / 2 + window_bevel + accent_w;   // the ring's outer edge
module accent_zone() { translate([cx, 0, -accent_t]) cylinder(r = accent_r, h = accent_t + 1); }
module pod() { union() {
    difference() {
        outer_solid();
        window();
        board_cavity();
        back_hole();
        plug_cavity();
        socket_opening();
        i2c_channel();
        slot();
        pod_magnet_pocket();
        pry_slot();
    }
    seat_ribs();
} }
module seat_ribs() {             // in the seat band only, from the face's back to the band's back end
    z0 = -face_t - seat_len;
    difference() {
        for (i = [0 : seat_ribs - 1]) translate([cx, 0, z0]) rotate([0, 0, 90 + i * 360 / seat_ribs])
            linear_extrude(seat_len) hull() {   // the tip is a r0.3 round whose inner edge is exactly on seat_rib_d
                translate([seat_rib_d / 2 + 0.3, 0]) circle(r = 0.3, $fn = 24);
                translate([board_seat_d / 2 + 0.3, -seat_rib_w / 2]) square([0.01, seat_rib_w]);
            }
        translate([cx, 0, z0 - 0.01]) cylinder(d1 = board_seat_d, d2 = seat_rib_d, h = seat_rib_lead + 0.01, $fn = 96);
    }
}
assert(seat_rib_d < board_seat_d, "the ribs must stand out of the seat band to grip the screen");

// ── Two-piece pod (owner, 2026-11-10) ─────────────────────────────────────────
// Printed in one piece the root (the box behind the panel) hangs ~9 mm in the air when the face is on
// the bed, so it needs supports, and the face can't go on the textured plate without them. So the pod
// splits along the round shell's own surface:
//   pod_round: exactly the round gauge shell. Prints FACE DOWN on the textured plate with no supports:
//              it is a dome, every layer sits inside the one below.
//   pod_root:  the rectangular box, with a curved seat the round shell's inboard back nests in. Keeps the
//              dovetail slot, the magnet, the I2C channel, the socket opening and nearly all of the
//              adapter pocket (only the end where the plug enters the XIAO is in the round piece). Prints
//              standing on its flat TOP with no supports: the slot's closed end is on the bed, the
//              adapter's ceiling becomes a floor, and the seat's faces are vertical or under 45 deg.
// The seat wraps the shell's curved back, so it locates the round piece in every direction. Glue them
// (CA or epoxy) with the back cap pushed in dry: its plug tab crosses the seam and holds the pair true.
split_gap = 0.1;           // the root's seat stands this far off the round shell, all round (glue room)
module pod_round() { intersection() { pod(); shell_outer(); } }
module pod_round_body() { difference() { pod_round(); if (accent) accent_zone(); } }   // two-colour: the main filament
module pod_accent()     { intersection() { pod_round(); accent_zone(); } }              // two-colour: the accent ring
module pod_root()  { difference()  { pod(); shell_outer(split_gap); seam_groove(); } }
// the shadow line (#227): a seam_reveal-wide band off the shell, only within seam_reveal_d of the root's outside
module seam_groove() {
    if (seam_reveal > 0) difference() {
        shell_outer(split_gap + seam_reveal);
        minkowski() { root_core(); sphere(r = (root_round - seam_reveal_d) / cos(180 / 32), $fn = 24); }
    }
}

// ── Fit coupon (v2, 2026-11-03): the parts of the pod that changed, at full size ──
//   1. bracket slice: lip + the top 20 mm of the rail, with its magnet pocket
//   2. pod root slice: the matching 18 mm of slot, with its magnet pocket (glue both magnets first)
//   3. face ring: the real face + window + snug seat band, face_t + seat_len + 2 deep, so the glass
//      presses in exactly as it will in the pod and sits flush against the face
//   4. the real back cap with its three posts: screw the display onto it to try posts and screws
//   5. socket block (2026-11-09): the root round the USB-C adapter's pocket, from the pod's bottom to
//      just above the block. Drop the adapter in from the back, plug the desk cable up into it from below
// In the slicer, split it to objects and lay each piece on its own flat face.
coupon_ring_depth = face_t + seat_len + 2;
module face_ring() {
    intersection() { pod(); translate([cx, 0, -coupon_ring_depth]) cylinder(d = board_d + 2 * wall + 8, h = coupon_ring_depth + 1); }
}
module coupon() {                 // pieces laid out apart so they don't touch
    translate([0, -(rail_top - 10), 0])
        intersection() { bracket(); translate([-100, rail_top - 20, -100]) cube([200, 20, 200]); }
    translate([0, -(slot_top - 7), -40])
        intersection() { pod(); translate([-100, slot_top - 16, -100]) cube([100 + gx + 4, 16 + wall, 200]); }
    translate([25, 0, 0]) face_ring();
    translate([85, 0, 0]) cap();
    translate([0, 0, -80]) socket_block();
}
module socket_block() {
    intersection() { pod(); translate([root_x0 - 1, -pod_h / 2 - 1, -pod_depth - 1])
        cube([usb_mouth_x + 3 - root_x0 + 1, adp_top_y + adp_fit + 3 + pod_h / 2 + 1, pod_depth + 1 + root_front_z]); }
}

// ── Fittings coupon (2026-11-10): the two cable fittings at full size, nothing else ──
//   1. the socket block (the root round the adapter pocket, the socket opening and the I2C groove),
//      standing on its cut top as the root prints: drop the adapter in, plug the desk cable up into it,
//      press the I2C cable into its groove from the back and tug it
//   2. the bottom of the bracket with the cable clip: press both cables in side by side
module clip_slice() {
    intersection() { bracket(); translate([-100, clip_y0 - 1, -100]) cube([200, -plate_h / 2 + 4 - clip_y0 + 1, 200]); }
}
module fittings_coupon() {
    translate([0, 0, adp_top_y + adp_fit + 3]) rotate([-90, 0, 0]) socket_block();
    translate([0, 45, 0]) clip_slice();
}

// ── Selector ─────────────────────────────────────────────────────────────────
// Everything, the test-only intersections included, is mirrored together for the left edge, so
// the parts stay in one consistent world and every interference check still holds.
assert(side == "left" || side == "right", str("side must be \"left\" or \"right\", got ", side));
module handed() { if (side == "left") mirror([1, 0, 0]) children(); else children(); }

// the two pod pieces on their print faces: the round pod face down, the root standing on its top
module print_pose() {
    if      (part == "pod_round_print" || part == "pod_round_body_print" || part == "pod_accent_print") rotate([0, 180, 0]) children();
    else if (part == "pod_root_print")  translate([0, 0, pod_h / 2]) rotate([-90, 0, 0]) children();
    else children();
}

print_pose() handed()
if      (part == "envelope") monitor_envelope();
else if (part == "bracket")  bracket();
else if (part == "rail")     rail();
// the strip pocket grown by a 1 mm wall, minus the bracket: must be empty (the rounded corners keep a wall)
else if (part == "strip_wall_breach") difference() { intersection() { strip_pocket(1); translate([-100, -100, -E - 1.3]) cube([200, 200, 1.29]); } bracket(); strip_pocket(); }
else if (part == "pod")      pod();
else if (part == "pod_round" || part == "pod_round_print") pod_round();
else if (part == "pod_round_body" || part == "pod_round_body_print") pod_round_body();
else if (part == "pod_accent" || part == "pod_accent_print") pod_accent();
else if (part == "accent_x_body") intersection() { pod_round_body(); pod_accent(); }   // test-only: must be empty
else if (part == "pod_root"  || part == "pod_root_print")  pod_root();
// test-only: the two pieces must not overlap, and with no glue gap they must make the whole pod
else if (part == "split_overlap") intersection() { pod_round(); pod_root(); }
else if (part == "slot_x_round")  intersection() { pod_round(); union() { slot(); pod_magnet_pocket(0.8); socket_opening(0.8); i2c_channel(0.8); } }
else if (part == "plug")     plug_envelope();
else if (part == "coupon")   coupon();
else if (part == "face_ring") face_ring();
else if (part == "socket_block") socket_block();
else if (part == "fittings_coupon") fittings_coupon();
else if (part == "clip_slice")   clip_slice();
// the I2C cable seated in its groove, below the window: must NOT be empty (that overlap is the grip)
else if (part == "i2c_grip")     intersection() { pod(); translate([i2c_cx, root_bot_y, i2c_cz]) rotate([-90, 0, 0])
                                     cylinder(d = i2c_cable_d, h = adp_top_y + adp_fit - i2c_window - root_bot_y, $fn = 32); }
else if (part == "cables_x_each_other") intersection() { usb_cable_path(); i2c_cable_path(); }
else if (part == "cap")      cap();
else if (part == "assembly") { pod(); cap(); bracket(); %monitor_envelope(); %board_components(); %plug_envelope(); %cable_path(); }
else if (part == "preview")  { pod(); cap(); bracket(); }        // the shape-variant viewer
// test-only: each must render EMPTY
else if (part == "bracket_x_monitor")  intersection() { bracket(); monitor_envelope(); }
else if (part == "assembly_x_monitor") intersection() { union() { pod(); cap(); bracket(); } monitor_envelope(); }
else if (part == "pod_x_bracket")      intersection() { pod(); bracket(); }
else if (part == "plug_x_pod")         intersection() { plug_envelope(); pod(); }
else if (part == "plug_x_cap")         intersection() { plug_envelope(); cap(); }
else if (part == "components_x_pod")   intersection() { board_components(); pod(); }
else if (part == "components_x_cap")   intersection() { board_components(); cap(); }
else if (part == "board_x_pod")        intersection() { board_body(); pod(); }
else if (part == "rib_probe_x_pod")    intersection() { translate([cx, 0, -face_t - seat_len + seat_rib_lead + 0.2]) cylinder(d = probe_d, h = 1, $fn = 96); pod(); }
else if (part == "board_x_cap")        intersection() { board_body(); cap(); }
else if (part == "screws_x_parts")     intersection() { screws(); union() { pod(); cap(); } }
// each post must cover its standoff's top: no gap between the post face and the brass
else if (part == "post_gap")
    difference() { for (h = mount_holes) translate([bpt(h)[0], h[1], standoff_top_z - 0.3]) cylinder(d = standoff_od - 0.6, h = 0.3, $fn = 32);
                   cap(); screw_holes(); }
// the board alone, swept straight in from the back to just behind the seat band
else if (part == "insertion_x_pod")
    intersection() { pod(); translate([cx, 0, -pod_depth - 5]) cylinder(d = board_d, h = pod_depth + 5 - face_t - seat_len - 0.02); }
else if (part == "cap_x_pod")      intersection() { cap(); pod(); }
// the face's lip in front of the glass: must NOT be empty, it is what stops the screen
else if (part == "glass_x_face")   intersection() { pod(); translate([cx, 0, -face_t - 0.01]) cylinder(d = glass_d, h = face_t + 0.02); }
// the cap over the plug only (the part outside the board circle), for its thickness
// the cap across the tab's joint with the round part (x in the valley, through the tab's thickness): must be solid
else if (part == "cap_tab_joint")  intersection() { cap(); translate([usb_mouth_x + 1, -20, -pod_depth - 1]) cube([1, 40, pod_depth + 1 + plug_cap_z]); }
else if (part == "cap_plug_tab")   intersection() { cap(); translate([0, 0, -50]) linear_extrude(100) difference() { plug_2d(); board_2d(); } }
// the plug pocket runs behind the dovetail slot: keep a 0.8 mm wall between them
else if (part == "plug_slot_wall") intersection() { plug_cavity(0.8); slot(); }
// with zero fit clearance the cap fills its opening exactly (only the pry undercut + screw holes stay open)
else if (part == "back_left_open") difference() { intersection() { outer_solid(); back_hole(); } cap(); board_cavity(); plug_cavity(); socket_opening(); i2c_channel();
                                                 screw_holes(); pry_undercut(); }
// board + plug swept in together from the back
else if (part == "insertion_with_plug_x_pod")
    intersection() { pod(); union() {
        translate([0, 0, -pod_depth - 5]) linear_extrude(pod_depth + 5 - face_t - seat_len - 0.02) board_2d(-0.5);
        translate([0, 0, -pod_depth - 5]) linear_extrude(pod_depth + 5 + plug_front_z) plug_2d(-0.5); } }
else if (part == "cable_x_pod")    intersection() { pod(); cable_path(); }
else if (part == "cable_x_cap")    intersection() { cap(); cable_path(); }
else if (part == "cable_x_bracket") intersection() { bracket(); cable_path(); }
// the opening and the I2C channel, grown 0.8 sideways, must stay in the root (they open only downward)
else if (part == "opening_breach")
    difference() { union() { socket_opening(0.8); i2c_channel(0.8); } outer_solid(); socket_opening(); i2c_channel();
                   plug_cavity(); back_hole(); translate([-100, root_bot_y - 20, -100]) cube([200, 20 + root_round, 200]);   // + the rounded bottom edge: a lead-in
                   translate([-100, -100, -pod_depth - 5]) cube([200, 200, 5 + 0.01]); }   // the groove's open back
// 1.5 mm of root straight above the adapter: must be SOLID (compare its volume) - it takes the plugging force
else if (part == "adapter_ceiling") intersection() { pod(); translate([plug_x0, adp_top_y + adp_fit + 0.01, plug_back_z]) cube([usb_mouth_x - plug_x0, 1.5, adp_t]); }
else if (part == "adapter_ceiling_box") translate([plug_x0, adp_top_y + adp_fit + 0.01, plug_back_z]) cube([usb_mouth_x - plug_x0, 1.5, adp_t]);
// the ledge under the socket face that stops the block being pulled out (empty if the grip is as big as the block)
else if (part == "socket_ledge") intersection() { pod(); translate([plug_x0, adp_bot_y - adp_fit - 1, plug_back_z]) cube([adp_w, 1, adp_t]); }
else if (part == "desk_plug")       desk_plug();
else if (part == "plug_slot_wall_extra") intersection() { union() { socket_opening(0.8); i2c_channel(0.8); } slot(); }
// the pod `unseat` mm above seated, anywhere along the slide: must never touch the bracket
else if (part == "pod_x_bracket_at")       intersection() { translate([0, unseat, 0]) pod(); bracket(); }
else if (part == "rail_magnet")            rail_magnet();
else if (part == "pod_magnet_seated")      pod_magnet_seated();
else if (part == "rail_magnet_x_bracket")  intersection() { rail_magnet(); bracket(); }
else if (part == "pod_magnet_x_pod")       intersection() { translate([0, seat_drop, 0]) pod_magnet_seated(); pod(); }
// each pocket grown 0.8 mm (sideways and deeper) must stay inside its part: a wall all round
else if (part == "rail_magnet_breach")     difference() { rail_magnet_pocket(0.8); bracket(); rail_magnet_pocket();
                                              translate([-50, -100, back_z - rail_depth - 10]) cube([100, 200, 10]); }   // the open face
else if (part == "pod_magnet_breach")      difference() { pod_magnet_pocket(0.8); pod(); pod_magnet_pocket();
                                              translate([0, 0, 0]) slot(); }
else if (part == "cavity_breach")
    difference() {
        union() { board_cavity(1); plug_cavity(1); }
        outer_solid();
        slot(); back_hole(); socket_opening(); i2c_channel();
        translate([cx, 0, -face_t - 0.01]) cylinder(d = board_d + 3, h = face_t + 1);   // window side
    }
else if (part == "pod_front_slab")     intersection() { pod(); translate([-200, -200, -E]) cube([400, 400, E]); }
else if (part == "none") {}   // render.scad draws its own dressed views
else assert(false, str("unknown part: ", part));
