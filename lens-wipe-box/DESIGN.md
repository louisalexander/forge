# Lens-wipe dispenser tower: design

## Intent
A desk dispenser for individually wrapped Zeiss lens wipes (55 × 50 × 3.5 mm packets),
bought in 300-packs from Costco. It sits on a desk full of computers and monitors, so it
should look modern and interesting (the plain tray and sloped file-holder were "too
boring"). Wipes lie flat in a stack. You pull the bottom one out the front with a finger.

## Goals
- Holds 27 wipes per fill and loads from the open top.
- The bottom wipe is easy to get a finger under and slide out. Only one comes out at a time.
- Looks like it belongs next to computer hardware.
- Prints without supports on a normal FDM printer.

## Non-goals / anti-goals
- Not sized for the whole 300-pack.
- No moving parts, springs or lids.
- Must not jam, and must not let two wipes slide out together.

## Approaches considered
1. **Upright tower, tilted floor inside (chosen).** The outside stays vertical and the
   floor inside ramps up 15° toward the front. This keeps the footprint small and puts the
   visual interest in the surface styling.
2. Whole tower leans back 15° on a wedge base. More striking, but it overhangs ~25 mm
   behind, takes more desk space and is less stable.
3. Flat stack with a front finger notch only. Rejected because a finger can't get under a
   wipe lying flat on the floor.

## Design
- **Orientation:** packets lie with the 55 mm side across the front and pull out forward
  along the 50 mm side (shorter pull).
- **Chamber:** 58 mm wide (1.5 mm clearance per side). Front-to-back depth is
  50·cos15° + 3 mm. Height fits 27 packets (each tilted packet adds ~3.6 mm) plus ~5 mm slack.
- **Tilted floor:** rises 15° toward the front, lifting the bottom packet's front edge about
  13 mm. The floor is solid under the back of the stack. Under the front it only has narrow
  side ledges, and the centre is cut away to make a ~30 mm wide finger pocket that opens
  through the front wall.
- **Pull slot:** a full-width opening in the front wall at the bottom packet's front edge.
  It is tall enough for one tilted packet (~5 mm) and short enough to hold back the second.
- **Fill window:** a narrow vertical slit up the front so you can see how many are left.
- **Top:** open for loading, with the rim cut at 15° parallel to the floor to echo the tilt.
  *(my call)*
- **Style (revised 2026-11-16): desktop-dock look.** A flat-sided block with a flat top,
  8 mm vertical corner radius and recessed horizontal grooves (45° chamfered tops) in framed
  side panels. The front is plain apart from the fill slit and a small indicator dimple. A
  drop-in lid has front-to-back grooves, and a finger scallop at the back lifts it. The
  original fin style is still available as `style = "fins"`.
- ~~Style: horizontal heat-sink fins~~ (superseded) around the body, with the undersides chamfered at 45°
  so they print without supports. The base and top rim are plain bands. Rounded vertical
  corners. *(my call: it was my recommendation and you can swap it for fluting, hex grille
  or bands)*
- **Feet:** shallow pockets underneath for 8 mm stick-on rubber feet. *(my call)*
- Approximate size: about 69 × 62 mm footprint including fins, about 125 mm tall.

## Files
- New `lens_wipe_tower.scad`: parametric, with all dimensions at the top.
- Makefile targets: `lens_wipe_tower.stl` plus `lens_wipe_tower_fit_test.stl`, the bottom
  ~30 mm (ramp, slot and pocket only) to test the dispensing action before the full print.
- The existing `lens_wipe_box.scad` (tray styles) stays as is.

## Left to the builder
Exact fin pitch and depth, the side ledge width, fillets, and checking that the slot height
lets exactly one packet through. Clearances are parameters you can tune after the fit test.
