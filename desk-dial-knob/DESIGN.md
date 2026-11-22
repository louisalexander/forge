# Desk dial knob: design log

An Adafruit 5880 I2C rotary encoder (seesaw, with a NeoPixel) and its knob, under the right side of a desk.
The full design history lives with the dial's firmware in a private repo. This log carries the decisions that
shape the model.

## 2026-11-14: round head on a neck

- A **round head** holds the knob on a 45° face. It hangs from a slim neck off a plate stuck under the desk
  with reusable gel tape: no holes in the desk. It replaced a first, boxy housing.
- The knob is a black PETG puck whose first 1.5 mm is translucent. The NeoPixel's light reaches it through a
  white light cup and a translucent diffuser in the face, so a thin line of colour shows at its base, inside a
  rose gold accent ring.
- Wiring leaves as a short JST-SM 4-pin pigtail out of the back of the plate, zip-tied to a bar under it.
- `[OWNER] caliper` parameters (shaft, D-flat, encoder heights, board clearance) are measured values.
  Re-measure before printing.

## 2026-11-15 to 16: fit and printing

- **No floating regions:** the cap bosses lean on the head wall with a 45° gusset. The accent cutter is offset
  so it doesn't leave slivers in the face hole.
- **The light cup is keyed into the back cap:** a 45° plug (`plug_h = 3`) seats in a cone in the cap's rim,
  `cap_press = 0.2` tight, so the screws centre the cup with no wiggle.
- **The cable has a way out through every printed part.** The print STLs are built from the assembled parts,
  so they carry the same wire cuts. A test compares their volumes. (A printed cap once lacked the notch.)
- **The real 5880 layout** comes from Adafruit's Eagle board file: pad row VIN · 3V · GND · SCL · SDA · INT
  at 0.1", LED opposite the pads, STEMMA QT sockets mid-edge on the back (~2.9 mm tall). The cup has a relief
  under the board (`board_back_h = 3.5`), and every passage takes a ø3.9 bundle (4 × 22 AWG).

## 2026-11-16: STEMMA QT cable and printable grooves

- `wiring = "qt"` (default) or `"solder"`. With QT, a plug pocket and cable hole sit at each side edge. With
  solder, there's a slot under the pads. `board_spin` is 0 or 180, so the LED faces up or down the knob's axis,
  never sideways.
- The cup prints plug down, so its grooves face the bed. A curved groove round the rim printed as spaghetti
  twice, so the cable runs in a **straight T through the middle**. Every groove is the same ø4.5 **teardrop**
  (45° flanks, 1.8 mm flat cap): no long bridges. A test rejects any downward face shallower than 44°.

## 2026-11-21: moved to forge

Moved from the private repo, with its checks (`tests/`, pytest). `part = "none"` was added so `render.scad`
can draw its own coloured views.
