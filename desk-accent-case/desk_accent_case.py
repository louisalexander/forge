# Desk Accent (#221) enclosure — build123d source (run with `from build123d import *` in scope,
# e.g. via the CAD MCP server). Set PART to "all" (assembly preview) or one part to export it in
# its PRINT orientation. Units: mm.
#
# A slim inline bar stuck under the G9's bottom edge, in front of the stand neck, window DOWN.
#   body   — opaque PLA (black). Prints floor-down as modelled.
#   lid    — opaque PLA. A plate that SNAPS flush into the top of the body (bead on the body's
#            long walls → groove round the lid edge). Exported flat face down. Its flat face
#            takes a Command strip / VHB pad against the monitor. Pry notch in the front end wall.
#   window — CLEAR PLA. Print on the TEXTURED PEI plate; that frosted face goes DOWN against the
#            body's 0.8 mm lip. It drops in from inside, so it can't fall out hanging face-down.
# Opaque body on purpose: only the window should glow, not the whole case. Clear PLA barely
# diffuses, hence the 4 mm LED→window throw plus the frosted texture.
PART = "all"

# ---- parts ----
STICK_L, STICK_W, STICK_H = 54.0, 10.1, 3.2       # 8x WS2812B stick (measured 54 x 10.1)
STICK_PCB = 1.6
# Stick mounting holes (measured 2026-11-10): Ø ~3.1, 27 mm apart centre-to-centre (~13 mm from
# each short end), in the LED-free band along ONE long edge. HOLE_Y / LED_Y are offsets from the
# bar's centreline, estimated from a photo (IMG_6382): holes ~2 mm in from their edge, LED row
# shifted ~2 mm toward the other edge. Re-measure if the first print's window looks off-centre.
HOLE_PITCH, HOLE_D = 27.0, 3.1
HOLE_Y = +3.0
LED_Y = -2.0
PIN_D, SHOULDER_D = 2.8, 5.0     # lid pins locate the stick; shoulders clamp it onto the ledges
XIAO_L, XIAO_W, XIAO_PCB = 21.0, 17.8, 1.2        # Seeed XIAO ESP32S3
XIAO_TOP = 3.4                                    # tallest part above the PCB (shield / USB-C)
USB_W, USB_H = 9.4, 3.6                           # opening around the USB-C receptacle

# ---- case ----
CLR, WALL = 0.4, 1.6
LIP_T = 0.8                    # outer floor lip the window rests on
WIN_T = 1.2                    # clear window thickness
FLOOR = LIP_T + WIN_T          # 2.0
APER_L, APER_W = STICK_L + 1.0, 7.0         # light aperture over the 5 mm LED row (at LED_Y)
# Window pocket spans the whole stick channel so no side guide overhangs it (it must drop in from
# inside). It's 3 mm longer than the aperture, so the end lips alone stop it falling out.
WIN_L, WIN_W = APER_L + 3.0, STICK_W + 2 * CLR
FIT = 0.15                     # press-fit clearance per side (window, lid)
LED_GAP = 4.0                  # LED face → window top
LEDGE = 0.9                    # ledges the stick's long edges rest on (clears the off-centre LED row)
WIRE_GAP = 3.0                 # stick → XIAO, for the three wires (5V, GND, DIN→D0)
LID_T = 2.0                    # snap-in lid plate (flush with the wall tops)
SEAT = 0.8                     # ledge ring the lid rests on
BEAD, BEAD_H = 0.3, 0.6        # snap bead on the long walls (proud of the wall) / its height
GROOVE = 0.4                   # matching groove round the lid edge (a bit deeper than the bead)
XIAO_PAD = 1.0                 # cradle floor under the XIAO
STOP_H = 2.5                   # cradle corner stops above the pad (board is 1.2)

IN_W = XIAO_W + 2 * CLR
IN_L = STICK_L + WIRE_GAP + XIAO_L + 3 * CLR
IN_H = LED_GAP + STICK_H + 1.5                    # floor → lid underside
OUT_L, OUT_W = IN_L + 2 * WALL, IN_W + 2 * WALL
LID_Z = FLOOR + IN_H                              # lid underside (body frame)
OUT_H = LID_Z + LID_T                             # body top = lid top (flush)
x0 = -IN_L / 2
stick_cx = x0 + CLR + STICK_L / 2
xiao_cx = x0 + CLR + STICK_L + WIRE_GAP + CLR + XIAO_L / 2
xiao_far = xiao_cx - XIAO_L / 2                   # board edge away from the USB-C end
A = (Align.CENTER, Align.CENTER, Align.MIN)

# ---- body ----
body = Box(OUT_L, OUT_W, OUT_H, align=A)
body -= Pos(0, 0, FLOOR) * Box(IN_L, IN_W, OUT_H, align=A)
# aperture centred on the LED row (LED_Y); window pocket centred on the channel
body -= Pos(stick_cx, LED_Y, -0.5) * Box(APER_L, APER_W, LIP_T + 1, align=A)
body -= Pos(stick_cx, 0, LIP_T) * Box(WIN_L, WIN_W, WIN_T + 0.01, align=A)
side_w = IN_W / 2 - STICK_W / 2 - CLR
for s in (-1, 1):
    y = s * (IN_W / 2 - side_w / 2)
    body += Pos(stick_cx, y, FLOOR) * Box(STICK_L + 2 * CLR, side_w, LED_GAP + STICK_H, align=A)
    # Ledges carry the PCB's long edges with the LEDs hanging below, so their top sits at
    # LED_GAP + the LED height (STICK_H - STICK_PCB): LED faces end up LED_GAP above the window.
    ly = s * (STICK_W / 2 + CLR - LEDGE / 2)
    ledge_top = FLOOR + LED_GAP + (STICK_H - STICK_PCB)
    body += Pos(stick_cx, ly, ledge_top - 1.0) * Box(STICK_L + 2 * CLR, LEDGE, 1.0, align=A)
# lid seat: a ring the lid plate rests on, just below its underside
ring = Box(IN_L, IN_W, SEAT, align=A) - Box(IN_L - 2 * SEAT, IN_W - 2 * SEAT, SEAT, align=A)
# no ring along the long walls over the XIAO bay — the lid's hold-down posts pass there
ring -= Pos(xiao_cx, 0, 0) * Box(XIAO_L + 2 * CLR, IN_W, SEAT, align=A)
body += Pos(0, 0, LID_Z - SEAT) * ring
# snap beads on both long walls, middle 60 % of the length, at the lid groove's height
for s in (-1, 1):
    body += Pos(0, s * (IN_W / 2 - BEAD / 2), LID_Z + LID_T / 2 - BEAD_H / 2) * \
        Box(IN_L * 0.6, BEAD, BEAD_H, align=A)
# pry notch at the top of the front (LED-end) wall
body -= Pos(-OUT_L / 2 + WALL / 2, 0, OUT_H - 1.2) * Box(WALL + 1, 6.0, 2.0, align=A)
# XIAO cradle: pad + two corner stops at the far edge (centre left open for the stick's wires)
body += Pos(xiao_cx, 0, FLOOR) * Box(XIAO_L + 2 * CLR, IN_W, XIAO_PAD, align=A)
for s in (-1, 1):
    body += Pos(xiao_far - CLR - 1.0, s * (IN_W / 2 - 2.0), FLOOR) * \
        Box(2.0, 4.0, XIAO_PAD + STOP_H, align=A)
usb_z = FLOOR + XIAO_PAD + XIAO_PCB + USB_H / 2 - 0.3
body -= Pos(OUT_L / 2 - WALL / 2, 0, usb_z) * Box(WALL + 2, USB_W, USB_H)

# ---- clear window ----
window = Box(WIN_L - 2 * FIT, WIN_W - 2 * FIT, WIN_T, align=A)

# ---- lid (lid frame: z=0 is its underside = body LID_Z) ----
lid = Box(IN_L - 2 * FIT, IN_W - 2 * FIT, LID_T, align=A)
for s in (-1, 1):   # groove round the long edges that the beads click into
    lid -= Pos(0, s * (IN_W / 2 - FIT - GROOVE / 2), LID_T / 2 - (BEAD_H + 0.2) / 2) * \
        Box(IN_L * 0.6 + 2.0, GROOVE + 0.01, BEAD_H + 0.2, align=A)
# stick pins: shoulder down to the stick's back (clamps it on the ledges), pin through each hole
stick_back_z = FLOOR + LED_GAP + STICK_H
shoulder_len = LID_Z - stick_back_z
pin_len = shoulder_len + STICK_PCB + 1.5
for s in (-1, 1):
    px = stick_cx + s * HOLE_PITCH / 2
    lid += Pos(px, HOLE_Y, -shoulder_len) * Cylinder(SHOULDER_D / 2, shoulder_len, align=A)
    lid += Pos(px, HOLE_Y, -pin_len) * Cylinder(PIN_D / 2, pin_len - shoulder_len + 0.01, align=A)
# XIAO hold-downs: press on the board's long-edge pad strips (clear of the shield/antenna)
xiao_top_z = FLOOR + XIAO_PAD + XIAO_PCB
hold_len = LID_Z - xiao_top_z
for s in (-1, 1):
    lid += Pos(xiao_cx - 2.0, s * (XIAO_W / 2 - 0.6), -hold_len) * Box(4.0, 1.0, hold_len, align=A)

print(f"outer {OUT_L:.1f} x {OUT_W:.1f} x {OUT_H:.1f} mm | lid {IN_L-2*FIT:.1f} x {IN_W-2*FIT:.1f} x {LID_T} "
      f"| window {WIN_L - 2 * FIT:.1f} x {WIN_W - 2 * FIT:.1f} x {WIN_T} | holds {hold_len:.1f} pins {pin_len:.1f}")

if PART == "body":
    result = body
elif PART == "lid":
    result = Pos(0, 0, LID_T) * Rot(180, 0, 0) * lid      # flat (adhesive) face on the bed
elif PART == "window":
    result = window
else:
    result = Compound([body, Pos(0, OUT_W + 8, hold_len) * lid, Pos(stick_cx, -(OUT_W + 6), 0) * window])
