# Desk accent case: design log

A slim case for a Seeed XIAO ESP32S3 and an 8× WS2812B stick (54 × 10.1 mm), stuck under a monitor's bottom
edge so the LEDs light the stand plate below.

## 2026-11-09: the first case (side by side)

- The XIAO and the stick sit side by side in one bar (`desk_accent_case.scad`), with a twin build123d model
  (`desk_accent_case.py`).
- **Opaque body and lid**, so only the window glows, not the whole case.
- **Window:** clear PLA printed on the textured PEI plate, frosted face down against the body's 0.8 mm lip.
  It drops in from inside, so it can't fall out when the case hangs face down.
- Clear PLA barely diffuses, so the LEDs sit 4 mm back from the window.
- The stick's holes (Ø ~3.1, 27 mm apart) locate it on the lid's pins.

## 2026-11-10: stacked (the current pick)

- `desk_accent_case_stacked.scad`: the XIAO sits on a carrier shelf directly above the LED stick, for a
  shorter case, **57.2 × 21.0 × 18.0 mm**.
- Rounded pill corners and flutes to match the dock beside the monitor, tapering from the narrow LED channel up
  to full width (about 25° from vertical, so no supports).
- `LED_GAP = 3.0` from the LED faces to the window. Raise it to 4.0 (+1 mm height) if the glow looks spotty.

## 2026-11-21: moved to forge

Moved from the private repo. `PART = "none"` was added so `render.scad` can draw its own coloured views.
