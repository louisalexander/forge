# Lens-Wipe Dispenser Tower Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A parametric OpenSCAD dispenser tower for Zeiss lens wipes with a tilted internal floor, finger pocket, one-at-a-time pull slot and heat-sink fins, exported to STL.

**Architecture:** One new file, `lens_wipe_tower.scad`. Derived dimensions are computed up top and guarded by `assert()`s. Separate modules handle the fins, chamber, ramp floor, slot/pocket, window and feet. `part` selects `tower` or `fit_test`. The Makefile gets two new STL targets and a preview image.

**Tech Stack:** OpenSCAD 2026.10 (manifold backend), make.

**Spec:** `/Users/pk/code/forge/lens-wipe-box/DESIGN.md`

## Global Constraints
- Packet 55 × 50 × 3.5 mm; 27 packets; 1.5 mm side clearance; floor tilt 15°.
- 55 mm side across the front; pull forward along the 50 mm side.
- Finger pocket ~30 mm wide; front-edge lift ≈ 13 mm.
- Fins with 45° chamfered undersides; no part may need supports (no flat overhang > ~1 mm).
- The existing `lens_wipe_box.scad` stays untouched.
- Not a git repo, so there are no commit steps.

## Review Focus
1. Second packet escaping with the first: slot vertical height must be > 1 packet and < 2 packets (tilted thickness 3.5/cos15° ≈ 3.62 mm). Assert in Task 1.
2. Packet snagging on the slot's lower lip: the slot bottom must sit at or below the ramp surface at the front wall. Assert in Task 1.
3. Stack not fitting the chamber depth when tilted: chamber depth ≥ 50·cos15° + clearance. Assert in Task 1.
4. Unprintable overhang under the floor ramp or the fins: check visually in the section render in Task 2.
5. Non-manifold output that slicers reject: `Status: NoError` on every export in Task 2.

---

### Task 1: Tower geometry (`lens_wipe_tower.scad`)

**Files:** Create `lens_wipe_tower.scad`

**Interfaces:**
- Produces: `part = "tower" | "fit_test"`, `fit_test_h`; echoes `Outer size`, `Capacity`, `Front lift`, `Slot height`.

- [ ] **Step 1: Write asserts first** (they act as the tests): `slot_h > pkt_tilt && slot_h < 2*pkt_tilt`; `front_lift >= 12`; `chamber_d >= packet_l*cos(tilt) + 2`; `capacity == 27`.
- [ ] **Step 2: Implement the modules:** `body_shell()` (rounded rect plus fins with 45° undersides and plain base/rim bands), `chamber()`, `ramp_floor()` (solid under the back, side ledges under the front), `pull_slot()`, `finger_pocket()`, `fill_window()`, `feet()` and `top_cut()` (rim at 15°).
- [ ] **Step 3: Run** `openscad --backend=manifold -o /tmp/x.stl lens_wipe_tower.scad`. Expected: no assert failure, `Status: NoError`.

### Task 2: Export targets and visual verification

**Files:** Modify `Makefile`

- [ ] **Step 1:** Add the `lens_wipe_tower.stl`, `lens_wipe_tower_fit_test.stl` and `tower_preview.png` targets to `all`.
- [ ] **Step 2:** Run `make`. Expected: all targets build with `Status: NoError`.
- [ ] **Step 3:** Render an iso view, a front view and a half-section side view. Check the ramp angle, the finger pocket opening, that the slot lines up with the bottom packet edge, and that nothing needs support.
