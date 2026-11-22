// Desk Accent (#221) enclosure: STACKED variant (OpenSCAD).
// The LED stick sits at the bottom, LEDs down, and the XIAO ESP32S3 sits on a carrier shelf
// directly above it. That makes it 57.2 x 21.0 x 18.0 mm, against 82.4 x 21.8 x 12.7 for the
// side-by-side brick in desk_accent_case.scad.
// Styling: rounded pill corners, a taper from the narrow LED channel up to full width (the
// outline follows what's inside), and vertical flutes like the CalDigit dock beside the monitor.
//
// Parts, all exported in PRINT orientation:
//   body    : opaque PLA (black). Floor down. Taper is ~25 deg from vertical, so no supports.
//   carrier : opaque PLA. Plate on the bed, stick pins pointing up.
//   lid     : opaque PLA. Flat (adhesive) face on the bed; posts and stops pointing up.
//   window  : CLEAR PLA on the TEXTURED PEI plate. The frosted face goes DOWN when assembled.
// Assembly, bottom to top:
//   1. window into the floor pocket from inside, frosted face down;
//   2. stick LEDs-down on its ledges, input (DIN) end at the USB end;
//   3. carrier onto the steps, its pins through the stick's holes;
//   4. XIAO on the carrier, USB-C through the end wall; the 3 wires rise through the slot at
//      the USB end (5V->5V, GND->GND, DIN->D0);
//   5. snap the lid in (pry notch at the far end).
//
// Differs from the build123d preview in one way: the XIAO's back-edge stops hang from the LID
// instead of standing on the carrier, so the carrier has a flat face to print on.
//
// Export:  openscad -D 'PART="body"' -o desk_accent_stacked_body.stl desk_accent_case_stacked.scad
// PART: "all" (exploded preview), "body", "carrier", "lid", "window".
PART = "all";

$fn = 48;

// ---- parts ----
STICK_L = 54.0; STICK_W = 10.1; STICK_H = 3.2; STICK_PCB = 1.6;   // 8x WS2812B (measured L/W)
// Mounting holes 27 mm apart (measured). HOLE_Y / LED_Y (offsets from the bar's centreline) are
// ESTIMATED from a photo; re-measure if the pins miss or the light opening misses the LEDs.
HOLE_PITCH = 27.0; HOLE_Y = 3.0; LED_Y = -2.0;
PIN_D = 2.8; SHOULDER_D = 5.0;
XIAO_L = 21.0; XIAO_W = 17.8; XIAO_PCB = 1.2; XIAO_TOP = 3.4;
USB_W = 9.4; USB_H = 3.6;

// ---- case ----
CLR = 0.4; WALL = 1.2; FIT = 0.15;
LIP_T = 0.8; WIN_T = 1.2; FLOOR = LIP_T + WIN_T;
LED_GAP = 3.0;        // LED faces to window top (4.0 if the glow looks spotty: +1 mm height)
LEDGE = 0.9;
WIRE_CLR = 1.5;       // stick back to carrier underside (solder joints / wires)
CARRIER_T = 1.2;
WIRE_SLOT = 3.0;      // carrier stops short of the USB end so the wires can rise
LID_T = 2.0; SEAT = 0.8;
BEAD = 0.3; BEAD_H = 0.6; GROOVE = 0.4;   // snap: bead on the body walls, groove on the lid
STOP_H = 2.0;
RC = 4.0;             // pill corner radius
ZT = 8.0;             // the taper ends here
FLUTE_W = 1.2; FLUTE_D = 0.4; FLUTE_P = 3.0;

CH_W = STICK_W + 2 * CLR;          // stick channel width
IN_W = XIAO_W + 2 * CLR;           // upper cavity width
IN_L = STICK_L + 2 * CLR;
OUT_L = IN_L + 2 * WALL; OUT_W = IN_W + 2 * WALL;
WB = CH_W + 2 * WALL + 0.3;        // bottom face width
RB = min(RC, WB / 2 - 0.5);
RI = RC - WALL;
APER_L = IN_L - 3.0; APER_W = 7.0; // 1.5 mm end lips hold the window
WIN_L = IN_L;
led_z = FLOOR + LED_GAP;
stick_bot = led_z + (STICK_H - STICK_PCB);
stick_back = stick_bot + STICK_PCB;
carrier_z = stick_back + WIRE_CLR;
xiao_z = carrier_z + CARRIER_T;
LID_Z = xiao_z + XIAO_PCB + XIAO_TOP + 0.5;
OUT_H = LID_Z + LID_T;
xiao_cx = IN_L / 2 - CLR - XIAO_L / 2;
xiao_far = xiao_cx - XIAO_L / 2;
usb_z = xiao_z + XIAO_PCB + USB_H / 2 - 0.3;
car_l = IN_L - 2 * FIT - WIRE_SLOT;
car_cx = -IN_L / 2 + FIT + car_l / 2;
hold_x = LID_Z - (xiao_z + XIAO_PCB);
hold_c = LID_Z - (carrier_z + CARRIER_T);
n_flutes = floor((OUT_L - 2 * RC - 2) / FLUTE_P);

// box centred in x/y, bottom at z
module bx(cx, cy, z, l, w, h) { translate([cx - l / 2, cy - w / 2, z]) cube([l, w, h]); }
// rounded rectangle (2D), centred
module rr(l, w, r) { translate([-l / 2 + r, -w / 2 + r]) offset(r = r) square([l - 2 * r, w - 2 * r]); }
// rounded slab, centred in x/y, bottom at z
module rslab(cx, z, l, w, r, h) { translate([cx, 0, z]) linear_extrude(h) rr(l, w, r); }

module outer() {
    hull() {                                   // taper: bottom face to full width at ZT
        rslab(0, 0, OUT_L, WB, RB, 0.01);
        rslab(0, ZT - 0.01, OUT_L, OUT_W, RC, 0.01);
    }
    rslab(0, ZT, OUT_L, OUT_W, RC, OUT_H - ZT);
}

module body() {
    difference() {
        union() {
            // All cavity cutters are unioned and subtracted ONCE. Subtracting them one by one left
            // non-manifold edges where their end faces share the inner end-wall plane (Bambu
            // Studio flagged 3 on the first export).
            difference() {
                outer();
                union() {
                    // stick channel, 0.2 shorter than the cavity (0.3 end clearance on the 54 mm
                    // stick) so its end faces never share the end-wall plane with the cavity's
                    bx(0, 0, FLOOR, IN_L - 0.2, CH_W, carrier_z - FLOOR + 0.5);
                    rslab(0, carrier_z, IN_L, IN_W, RI, OUT_H);            // upper cavity (steps at carrier_z)
                    bx(0, LED_Y, -0.5, APER_L, APER_W, LIP_T + 1);         // light aperture over the LED row
                    bx(0, 0, LIP_T, WIN_L, CH_W, WIN_T + 0.5);             // window pocket
                }
            }
            for (s = [-1, 1]) {
                bx(0, s * (CH_W / 2 - LEDGE / 2), stick_bot - 1.0, IN_L, LEDGE, 1.0);              // stick ledges
                bx(0, s * (IN_W / 2 - BEAD / 2), LID_Z + LID_T / 2 - BEAD_H / 2, IN_L * 0.6, BEAD, BEAD_H); // snap beads
            }
            difference() {                                           // lid seat ring
                rslab(0, LID_Z - SEAT, IN_L, IN_W, RI, SEAT);
                rslab(0, LID_Z - SEAT - 0.01, IN_L - 2 * SEAT, IN_W - 2 * SEAT, RI - SEAT, SEAT + 0.02);
                // open from the XIAO's back edge to the USB end wall: the hold-downs and stops pass
                // here, and no ring sliver is left at the end for the USB-C cut to nick
                bx((xiao_far - CLR + IN_L / 2 + 1) / 2, 0, LID_Z - SEAT - 0.01,
                   IN_L / 2 + 1 - (xiao_far - CLR), IN_W + 1, SEAT + 0.02);
            }
        }
        // USB-C through the end wall (starts 1 mm inside the cavity, where nothing else is)
        translate([IN_L / 2 - 1, -USB_W / 2, usb_z - USB_H / 2]) cube([WALL + 2, USB_W, USB_H]);
        bx(-OUT_L / 2 + WALL / 2, 0, OUT_H - 1.2, WALL + 1, 6.0, 2.0);                            // pry notch
        for (i = [0 : n_flutes - 1], s = [-1, 1])                                                 // flutes
            bx(-(n_flutes - 1) * FLUTE_P / 2 + i * FLUTE_P, s * OUT_W / 2, ZT + 0.6,
               FLUTE_W, 2 * FLUTE_D, OUT_H - ZT - 1.2);
    }
}

// carrier frame: z = 0 is its underside (= body carrier_z); pins hang below
module carrier() {
    rslab(car_cx, 0, car_l, IN_W - 2 * FIT, max(RI - FIT, 0.5), CARRIER_T);
    for (s = [-1, 1]) {
        px = s * HOLE_PITCH / 2;
        translate([px, HOLE_Y, -WIRE_CLR]) cylinder(d = SHOULDER_D, h = WIRE_CLR + 0.01);          // clamps the stick
        translate([px, HOLE_Y, -WIRE_CLR - STICK_PCB - 1.0]) cylinder(d = PIN_D, h = STICK_PCB + 1.01);  // through its hole
    }
}

// lid frame: z = 0 is its underside (= body LID_Z); posts hang below
module lid() {
    difference() {
        rslab(0, 0, IN_L - 2 * FIT, IN_W - 2 * FIT, RI - FIT, LID_T);
        for (s = [-1, 1])
            bx(0, s * (IN_W / 2 - FIT - GROOVE / 2), LID_T / 2 - (BEAD_H + 0.2) / 2,
               IN_L * 0.6 + 2.0, GROOVE + 0.01, BEAD_H + 0.2);
    }
    for (s = [-1, 1]) {
        bx(xiao_cx - 2.0, s * (XIAO_W / 2 - 0.6), -hold_x, 4.0, 1.0, hold_x + 0.01);       // press the XIAO's edges
        bx(-IN_L / 2 + 8.0, s * (IN_W / 2 - 3.0), -hold_c, 3.0, 2.0, hold_c + 0.01);       // press the carrier's free end
        // XIAO back-edge stops: 3 wide, kept 1 mm off the wall so they clear the lid seat ring
        bx(xiao_far - CLR - 1.0, s * (IN_W / 2 - 2.5), -hold_c, 2.0, 3.0, hold_c + 0.01);
    }
}

module window() { bx(0, 0, 0, WIN_L - 2 * FIT, CH_W - 2 * FIT, WIN_T); }

if (PART == "body") body();
else if (PART == "carrier") translate([0, 0, CARRIER_T]) rotate([180, 0, 0]) carrier();  // plate down, pins up
else if (PART == "lid") translate([0, 0, LID_T]) rotate([180, 0, 0]) lid();              // flat face down
else if (PART == "window") window();
else if (PART == "none") {}   // render.scad draws its own dressed views
else {
    body();
    translate([0, OUT_W + 6, WIRE_CLR + STICK_PCB + 1.0]) carrier();
    translate([0, 2 * OUT_W + 12, hold_c]) lid();
    translate([0, -(OUT_W + 4), 0]) window();
    echo(str("outer ", OUT_L, " x ", OUT_W, " x ", OUT_H, " | base ", WB, " | flutes ", n_flutes, "/side"));
}
