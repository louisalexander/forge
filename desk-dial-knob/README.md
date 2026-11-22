# Desk dial knob

| The knob in its round head, on the neck and plate | From behind: the back cap and the plate |
|---|---|
| ![Knob and housing](img/assembly.png) | ![Knob housing from behind](img/back.png) |


The Adafruit 5880 encoder and its knob, under the right side of the desk. A **round head** holds the knob
on a 45° face. It hangs from a slim **neck** off a **plate** gel-taped under the desk (no holes). A short **JST-SM
4-pin pigtail** leaves the back of the plate, zip-tied under it; the pod's cable carries the other half. The knob is a black PETG puck whose first 1.5 mm is translucent. The
NeoPixel's light reaches it through a white light cup and a translucent diffuser in the face, so a thin line of
colour shows at its base, inside a rose gold ring. The round head replaced a first,
boxy housing. Design decisions: [`DESIGN.md`](DESIGN.md).

Model: `desk_dial_knob_housing.scad`. Re-export with `make`, check with `make test` (pytest), re-render the
pictures with `make images`. It pairs with [`desk-dial-pod`](../desk-dial-pod/): the pod's cable carries the
other half of the pigtail.

## Print (Bambu Studio, P2S + AMS)

**Charcoal PLA everywhere it can be.** The knob comes two ways:
- **Snap knob (try first; the `mockup_knob_*` files):** a **charcoal PLA body** that matches the housing,
  snapped onto a **clear PETG floor**. They print apart, and the joint is a hub round the shaft, inside the
  dark centre. The glow enters the floor's underside between r 12 and 21 and shows at its edge, so the floor
  stays a plain 1.5 mm disc out there and nothing touches the light. The shaft runs through the PETG hub,
  and the hub's outside is a D, so the body turns the shaft.
- **Fused knob (the fallback; `knob_floor` + `knob_body`):** one AMS print, clear PETG floor and black PETG
  body. It's the same shape, but the body can't be PLA, because PETG and PLA don't fuse.

One other part isn't charcoal:
- **The light cup is white PETG** (matte white; ivory PLA also works), because it's the inside of the light box. White bounces the LED's light round
  to the far side of the knob, and charcoal would swallow the glow. It's hidden inside the head.

**Nothing is glued.** Every part is either printed as one AMS object or held mechanically: the cap
screws on, the cup clamps the diffuser, the snap knob clicks together, and the knob pushes onto the shaft. Each STL comes already turned
onto its print face.

| Plate | Objects (`desk_dial_kh_*.stl`) | Filament (AMS) |
|---|---|---|
| 0 · mock-up | `mockup` | anything, 0.28 mm, face down. Print it first and tape it up to check the fit |
| 1 · charcoal | `body` + `accent_ring` **as one object**, plus `back_cap`, `cable_clip`, `mockup_knob_body` | charcoal PLA, rose gold PLA for the ring |
| 2 · white | `light_cup` | matte white PETG (or ivory PLA) |
| 3 · clear | `diffuser_ring` + `mockup_knob_floor` | translucent PETG only |
| (fallback) | `knob_floor` + `knob_body` **as one object** | translucent PETG floor, black PETG body |

**One object, two parts** (plate 1, and the fallback knob): select both STLs, drag them into Bambu Studio together and
answer **Yes** to "load as a single object with multiple parts". Then give each part its filament in the
object list. They share a frame, so they land in place.

**Plate 1 · charcoal PLA**, textured PEI, 0.20 mm, no supports, no brim.
- **Body** face down. The face is the first layer, so it takes the plate's matte texture, like the pod.
  The neck, plate and tie bar rise at 45° from there, and nothing needs supports. The tape face prints as a
  45° slope, which is fine for the gel tape.
- **The rose gold ring** is the face's first 3 layers (0.6 mm), so the AMS only swaps for those. Charcoal
  into rose gold is dark into light: raise that pair's flush volume (about ×1.5) or the ring's first layer
  comes out muddy.
- **Back cap** disc down. **Cable clip** flat side down.
- **Snap knob body** (`mockup_knob_body`) **top down**, so the knob's top gets the same matte plate
  finish as the housing's face. The knurl rises straight up, and the pocket and groove are inside.

**Plate 2 · matte white PETG**, 0.20 mm, the normal PETG profile (textured PEI). The light cup prints **plug down**:
the tapered plug on its back is its own support. It's opaque, so the light bounces forward instead of leaking out the sides. It has its own plate, because
PETG and PLA never share one. Ivory PLA works too, if you'd rather.
- **The wire grooves are on the bed face**, so their roofs hang over the plate. They're shaped to print
  without supports: every groove (the T and the neck groove) is the same ø4.5 teardrop, a round bottom with
  45° sides up to a 1.8 mm flat top, which is a short bridge. No supports and no brim. Keep **elephant foot compensation** on (Bambu's default, 0.15) and a clean plate.
  Overhangs in PETG like a bit of fan: if the roofs droop, raise the overhang fan to 60–80%.

**Plate 3 · clear PETG**, textured PEI (PETG can weld itself to smooth PEI; if you only have smooth, use
glue stick as a release), 0.20 mm, 100% infill, no dark filament on the plate, so nothing tints it.
- **Diffuser** lip down.
- **Snap knob floor** (`mockup_knob_floor`) floor down. The hub with its four slotted fingers rises from
  it. The textured plate frosts the floor's underside, which spreads the glow.

**Fallback knob**, PETG, same plate settings, floor down. The clear floor prints first, so there's **one**
filament change, clear to black, and no black can bleed into the clear.

**Never put PETG and PLA in the same object.** They also shouldn't share a plate: they need different
temperatures.

## Before printing: measure (every `[OWNER] caliper` in the `.scad`)

- **The shaft:** `shaft_d`, `shaft_flat`, the D-flat's length (≥ `bore_depth` 7.5), and
  **`shaft_above_board`** (board front → shaft tip, 22 assumed). It sets how deep the board sits, and so how
  deep the head is (≈66 mm below the desk at 22). The model refuses a shaft that's too short for the light
  cup, or one whose bushing would hit the knob.
- `enc_body_h`, `bushing_d`, `bushing_h`; `board_hole_d`.
- **`board_back_h`** (3.5 assumed): the tallest thing on the board's **back**. The two STEMMA QT sockets are
  about 2.9 mm, and the encoder's soldered pins may stick out further. Clip the pins if they're longer. The
  cup has a relief under the board, so the back gets 3.5 mm of room.
- **The connector: a JST-SM 4-pin pigtail pair** (the latching LED-strip kind, 2.5 mm contacts, 22 AWG
  leads). The female pigtail goes in the housing; solder the male half to the pod's 24/4 cable. It's far
  sturdier than STEMMA QT, but it's a dangling joint, so the zip tie and the cable clip take every tug.
  Want a wall socket instead? `connector = "m8"` (M8 4-pin, ~31 × 20 × 14 block) or `"gx12"` brings the
  connector block back (then also export and print `block_cover`).

## Placement: print the mock-up first

`knob_out` / `knob_down` (20 / 29.5) place the knob's centre past the desk's front edge and below its
underside. Any pair works as long as there's ≥ 15 mm (`finger_room`) between the knurl and the desk
corner for a pinch. The checks run at 20 / 29.5 (≈39 mm past the edge, ≈66 below at the head's back
rim) and at 30 / 19.5 (≈49 past, ≈56 below). Tape the mock-up up, sit down, and pick.

## Assemble

1. Solder the male JST-SM pigtail to the pod's cable (match the colours noted at the pod: 3V3, GND, SDA, SCL;
   heat-shrink each joint).
2. **The pigtail, plate → head:** feed the female pigtail's bare ends up through the hole in the plate's
   underside (behind the tie bar), along the plate and down the neck, until they come out of the head's open
   back. Zip-tie the leads to the bar under the plate (a 3.6 mm tie through its tunnel), leaving the plug
   about 10 cm past the plate's back.
3. **Wire the board, then screw it down.** (Soldered wiring, `wiring = "solder"`.) The 5880's pads run along one edge: **VIN · 3V · GND · SCL · SDA ·
   INT**. Use the middle four, and leave VIN and INT empty. Push the leads through the cup's slot from behind
   (the slot is on the neck side), then solder them into **3V / GND / SCL / SDA** from the board's back, so
   each lead drops straight off its pad into the slot. Lay the board on the posts with that pad edge over the
   slot. The NeoPixel ends up on the opposite edge, toward the chair, away from the wires. Screw it down
   **from the front** (4 × M2.5 × 6), drawing the slack back through the slot. The heads hold the board, so
   pulling the knob can't move it. White nylon or low-profile heads keep the glow even.

   **Or plug in a STEMMA QT cable instead of soldering** (what the first build did). The board's two QT
   sockets sit mid-edge on its back, on the left and right edges (a quarter turn from the pads). Plug the
   cable into either one and lay the board on the posts with the NeoPixel **toward the chair**
   (`board_spin = 0`, the default) or **toward the neck** (`180`). The plug drops into the pocket at that
   side's edge, and the cable goes straight back through the hole there. Behind the cup, bundle the four
   wires 2 × 2 and press them into the T-shaped groove in the plug's face: straight across the middle to
   the centre, then straight up the middle into the neck groove. It's straight, the same teardrop as the neck groove, so
   it prints plug down with no long bridges. The cup is
   solid on the neck side: `wiring = "qt"` is the default. Soldering to the pads instead? Set
   `wiring = "solder"` and re-export; that cup has the pad slot and no side pockets. Keep
   the QT plug in the head and feed the cable's **other** end down the neck: the plug won't pass the ø4.4
   channel.
4. Push the diffuser's front disc into the face hole from inside, until its lip sits in the pocket behind the
   face. Slide the cup (with the board) in from the back along the knob's axis, shaft through the diffuser.
   The three bosses centre it. Lay the leads in the groove in the plug on its back. It runs straight out to
   the head wall on the neck side, then forward along the wall into the neck.
5. Close the head with the back cap (3 × M2.5 × 8 into the bosses). The cup's tapered plug seats in the
   cone inside the cap's rim, 0.2 mm tight, so tightening the screws centres the cup with no wiggle and clamps
   it onto the diffuser's lip. The notch in the ring lets the wires through.
6. **Snap knob:** the floor's hub (the four slotted fingers) clicks into the **charcoal knob body**, not the
   diffuser. The diffuser stays in the face, and its ø8 hole only lets the shaft through; the knob floor spins
   1.5 mm in front of it. Line up the hub's flat with the flat in the body's pocket and press the floor in until it
   clicks flat against the body: the barb has caught the groove. Then push the knob onto the shaft (flat to
   flat) until it stops. With the shaft inside, the fingers can't flex, so it can't come apart on the shaft.
   Off the shaft, pry it apart at the rim with a fingernail. **Fused knob:** just push it on.

## Install

Clean the desk's underside with isopropyl. Cover the plate's top with nano gel tape, press it up for 30 s,
and let it settle for an hour before using the knob.

**Test the tape on the mock-up first.** Pressing the knob levers the plate's front edge away from the desk:
a 10 N press is about 400 N·mm of peel there. Tape the mock-up up and hang about 1.5 kg from where the knob
sits, for a day. If it creeps or peels, use 3M VHB tape instead (it's removable with floss and heat, but
not reusable). Plug the pigtails together, then stick the cable clip
just behind the plug on the pod's side and press the cable into it, so the cable's weight never hangs on the
joint or the housing.
