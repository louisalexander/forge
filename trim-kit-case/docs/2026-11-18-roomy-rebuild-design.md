# Roomy rebuild: design

## Intent
The current case (`deburr_case.scad`, v4) works: the hinge, stand, magnets, seats and clip are all
proven. But it is cramped:
- The blades sit 5.5 mm apart and are hard to get in and out.
- The handle has 0.5 mm of play in its bore and is hard to slide out.

The user wants the same case idea, bigger, roomier and beefier, with larger bevels. They rejected
new layouts (side rack, standing rack) in favour of the original concept.

## Goals
- Same concept: a U-channel body plus a lid tray. The handle runs along one side, held by one
  smooth-section clip. Two stepped columns of 5 snap-in blades sit at the hinge end.
- Hardware and stand stay the same: M2×8 screw hinge with the hidden tooth-and-groove stop, so it
  stands reclined at about 33° past upright, and 6×3 magnets at the latch end.
- Finish stays the same: the Toolroom knurl and ticks, and the Bambu logo inlay on the bottom.
- Roomier:
  - Blades 9 mm apart across (was 5.5).
  - 21 mm between the two columns along the case (was 15).
  - 12 mm between the columns vertically (was 9.5).
  - Handle bore Ø21.5 (was 19.2), plus a finger scoop past the handle tip to lift it out.
- Bigger and beefier: about 170 × 84 × 28 mm closed (was 153 × 62 × 22), with 3 mm walls.
- Larger bevels:
  - 6 mm plan corners at the latch end.
  - 2.5 mm rounds on the top edges.
  - 2 mm 45° chamfers on the edges that print on the bed.

## Non-goals and anti-goals
- No new layout, no latches, no text.
- It must not lose any proven fit: seat mouth 2.45 (2.35 on the riser column), seat bore 3.25,
  clip squeeze 0.4 on Ø17, M2 pilot 1.7 and clearance 2.3, magnet pocket 6.2 × 2.8.
- It must not print worse: no unsupported overhangs, and round edges never on the bed.

## Approaches
1. **Stretch the imported original meshes** in x, y and z, as v4 does in z. Rejected: it distorts
   the seats and features, about 500 lines of hand-placed coordinates would all shift, and the
   original's square sides limit the bevels.
2. **Clean parametric rebuild** (chosen). A new `trim_case.scad` built from primitives. Every
   dimension derives from a short parameter list, and the proven feature modules are carried over.
   v4 stays untouched until v5 checks out.

## Decided
- Width grows to about 84 mm rather than 80, to fit 5 rows at 9 mm, the Ø21.5 handle bore and the
  walls. The user saw "about 80" and approved a bigger case, so this is my call.
- Same frames as v4 (lid frame = print orientation; closed lid = rotated 180° about y), the same
  part names and the same Makefile and 3MF outputs, so the user's workflow doesn't change.
- Same checks: closed overlap, swing sweep, stop at `stop_a`, table plane, watertight meshes.
- Test prints: the snap, clip and hinge test pieces, regenerated from v5, before a full case.

## Left to the builder
- Exact x, z positions of the pivot, cover plate and swing arcs, derived from the new sizes and
  re-verified with the swing and table checks.
- Exact knurl and tick placement on the new walls.
