// Desk Accent (#221) enclosure: OpenSCAD port of desk_accent_case.py (build123d).
// Both files describe the same geometry. If you change a dimension, change it in both, or
// regenerate the STLs from one and treat the other as stale.
//
// A slim inline bar stuck under the G9's bottom edge, in front of the stand neck, window DOWN.
//   body   : opaque PLA (black). Prints floor-down as modelled.
//   lid    : opaque PLA. A plate that SNAPS flush into the top of the body (a bead on the body's
//            long walls clicks into a groove round the lid edge). Exported flat face down. The
//            flat face takes the adhesive against the monitor. Pry notch in the LED-end wall.
//   window : CLEAR PLA, printed on the TEXTURED PEI plate. The frosted face goes DOWN.
//
// Export one part:  openscad -D 'PART="body"' -o desk_accent_body.stl desk_accent_case.scad
// PART: "all" (assembly preview), "body", "lid", "window".
PART = "all";

$fn = 64;

// ---- parts ----
STICK_L = 54.0; STICK_W = 10.1; STICK_H = 3.2;   // 8x WS2812B stick (measured 54 x 10.1)
STICK_PCB = 1.6;
// Stick mounting holes: dia ~3.1, 27 mm apart. HOLE_Y and LED_Y are offsets from the bar's
// centreline, ESTIMATED from a photo. Re-measure if the pins miss the holes.
HOLE_PITCH = 27.0; HOLE_Y = 3.0; LED_Y = -2.0;
PIN_D = 2.8; SHOULDER_D = 5.0;
XIAO_L = 21.0; XIAO_W = 17.8; XIAO_PCB = 1.2;    // Seeed XIAO ESP32S3
USB_W = 9.4; USB_H = 3.6;

// ---- case ----
CLR = 0.4; WALL = 1.6;
LIP_T = 0.8; WIN_T = 1.2; FLOOR = LIP_T + WIN_T;
APER_L = STICK_L + 1.0; APER_W = 7.0;            // light aperture over the LED row
WIN_L = APER_L + 3.0; WIN_W = STICK_W + 2 * CLR; // window pocket spans the stick channel
FIT = 0.15;
LED_GAP = 4.0;        // LED face to window top
LEDGE = 0.9;
WIRE_GAP = 3.0;
LID_T = 2.0; SEAT = 0.8;
BEAD = 0.3; BEAD_H = 0.6; GROOVE = 0.4;          // snap: bead on the walls, groove on the lid
XIAO_PAD = 1.0; STOP_H = 2.5;

IN_W = XIAO_W + 2 * CLR;
IN_L = STICK_L + WIRE_GAP + XIAO_L + 3 * CLR;
IN_H = LED_GAP + STICK_H + 1.5;
OUT_L = IN_L + 2 * WALL; OUT_W = IN_W + 2 * WALL;
LID_Z = FLOOR + IN_H;            // lid underside (body frame)
OUT_H = LID_Z + LID_T;           // body top = lid top (flush)
x0 = -IN_L / 2;
stick_cx = x0 + CLR + STICK_L / 2;
xiao_cx = x0 + CLR + STICK_L + WIRE_GAP + CLR + XIAO_L / 2;
xiao_far = xiao_cx - XIAO_L / 2;
side_w = IN_W / 2 - STICK_W / 2 - CLR;
ledge_top = FLOOR + LED_GAP + (STICK_H - STICK_PCB);
usb_z = FLOOR + XIAO_PAD + XIAO_PCB + USB_H / 2 - 0.3;
shoulder_len = LID_Z - (FLOOR + LED_GAP + STICK_H);
pin_len = shoulder_len + STICK_PCB + 1.5;
hold_len = LID_Z - (FLOOR + XIAO_PAD + XIAO_PCB);

// box centred in x/y at (cx, cy), bottom at z (= build123d Align CENTER, CENTER, MIN)
module bx(cx, cy, z, l, w, h) { translate([cx - l / 2, cy - w / 2, z]) cube([l, w, h]); }

module body() {
    difference() {
        union() {
            difference() {
                bx(0, 0, 0, OUT_L, OUT_W, OUT_H);
                bx(0, 0, FLOOR, IN_L, IN_W, OUT_H);                          // cavity
                bx(stick_cx, LED_Y, -0.5, APER_L, APER_W, LIP_T + 1);        // light aperture
                bx(stick_cx, 0, LIP_T, WIN_L, WIN_W, WIN_T + 0.01);          // window pocket
            }
            for (s = [-1, 1]) {
                // side guides, wall to stick edge
                bx(stick_cx, s * (IN_W / 2 - side_w / 2), FLOOR, STICK_L + 2 * CLR, side_w, LED_GAP + STICK_H);
                // ledges under the stick's long edges (LEDs hang below the PCB)
                bx(stick_cx, s * (STICK_W / 2 + CLR - LEDGE / 2), ledge_top - 1.0, STICK_L + 2 * CLR, LEDGE, 1.0);
                // snap beads on the long walls, middle 60 % of the length
                bx(0, s * (IN_W / 2 - BEAD / 2), LID_Z + LID_T / 2 - BEAD_H / 2, IN_L * 0.6, BEAD, BEAD_H);
            }
            // lid seat ring, open along the long walls over the XIAO bay (hold-down posts pass there)
            difference() {
                bx(0, 0, LID_Z - SEAT, IN_L, IN_W, SEAT);
                bx(0, 0, LID_Z - SEAT - 0.01, IN_L - 2 * SEAT, IN_W - 2 * SEAT, SEAT + 0.02);
                bx(xiao_cx, 0, LID_Z - SEAT - 0.01, XIAO_L + 2 * CLR, IN_W, SEAT + 0.02);
            }
            // XIAO cradle: pad + two corner stops at the far edge (centre open for the wires)
            bx(xiao_cx, 0, FLOOR, XIAO_L + 2 * CLR, IN_W, XIAO_PAD);
            for (s = [-1, 1])
                bx(xiao_far - CLR - 1.0, s * (IN_W / 2 - 2.0), FLOOR, 2.0, 4.0, XIAO_PAD + STOP_H);
        }
        bx(-OUT_L / 2 + WALL / 2, 0, OUT_H - 1.2, WALL + 1, 6.0, 2.0);           // pry notch
        translate([OUT_L / 2 - WALL / 2, 0, usb_z]) cube([WALL + 2, USB_W, USB_H], center = true); // USB-C
    }
}

module window() { bx(0, 0, 0, WIN_L - 2 * FIT, WIN_W - 2 * FIT, WIN_T); }

// lid frame: z = 0 is the lid's underside (= body LID_Z); posts and pins hang below it
module lid() {
    union() {
        difference() {
            bx(0, 0, 0, IN_L - 2 * FIT, IN_W - 2 * FIT, LID_T);
            for (s = [-1, 1])   // groove the beads click into
                bx(0, s * (IN_W / 2 - FIT - GROOVE / 2), LID_T / 2 - (BEAD_H + 0.2) / 2,
                   IN_L * 0.6 + 2.0, GROOVE + 0.01, BEAD_H + 0.2);
        }
        for (s = [-1, 1]) {
            px = stick_cx + s * HOLE_PITCH / 2;
            // shoulder clamps the stick onto its ledges; the pin goes through its mounting hole
            translate([px, HOLE_Y, -shoulder_len]) cylinder(d = SHOULDER_D, h = shoulder_len + 0.01);
            translate([px, HOLE_Y, -pin_len]) cylinder(d = PIN_D, h = pin_len - shoulder_len + 0.01);
            // XIAO hold-downs on the board's long-edge pad strips
            bx(xiao_cx - 2.0, s * (XIAO_W / 2 - 0.6), -hold_len, 4.0, 1.0, hold_len + 0.01);
        }
    }
}

if (PART == "body") body();
else if (PART == "lid") translate([0, 0, LID_T]) rotate([180, 0, 0]) lid();   // flat face on the bed
else if (PART == "window") window();
else {
    body();
    translate([0, OUT_W + 8, hold_len]) lid();
    translate([stick_cx, -(OUT_W + 6), 0]) window();
}
