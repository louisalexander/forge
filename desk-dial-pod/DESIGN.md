# Desk dial pod: design log

A round pod that sits off the left edge of a monitor at eye level, holding a Seeed round display and a XIAO
ESP32S3. The full design history lives with the dial's firmware in a private repo. This log carries the
decisions that shape the model.

## 2026-11-02: the pod

- A round gauge face (`face_shape = "gauge"`: the ø44.1 screen circle with a 3 mm rim, ø50.1 overall) sits
  flush with the glass, off the monitor's edge.
- It slides onto a bracket stuck to the monitor's back with Command strips: no clamps, no screws in the
  monitor.
- A cap closes the back, flush with the pod's own curve, and carries the screen.
- Test coupons (`coupon`, `fittings_coupon`) tune the screen seat and the cable fittings before the final
  print.

## 2026-11-12: looks

- It prints as two pieces: the round head (face down) and the root (on its top), glued, with magnets locating
  them.
- **Accent ring:** a second filament round the window (`accent = true`, `accent_w = 1.2`,
  `accent_t = 0.48` = three 0.16 mm layers), so the colour wraps over the window's edge. It's exported as its
  own part for a two-colour AMS print.
- A rounded root, a window bevel, a stem blend into the head, and a seam reveal between the pieces.
- The measured USB-C adapter sets the cable pocket.

## 2026-11-21: moved to forge

Moved from the private repo, with its checks (`tests/`, pytest). `part = "none"` was added so `render.scad`
can draw its own coloured views.

## 2026-11-21: print file rebuilt, easy-release supports on the cap

`make print` rebuilds the STLs (now binary) and packs `desk_dial_pod.3mf` with `pack_plate.py` (from
trim-kit-case, extended with per-object settings after a `;`). It embeds the owner's P2S profile
(`print_settings.config`, taken from the previous 3MF). The cap overrides the project's tree supports so they
peel off easily: `support_style = tree_organic`, `tree_support_tip_diameter = 0.6` (was 0.8),
`support_object_xy_distance = 0.6` (was 0.35), `support_interface_spacing = 0.8` (was 0.5),
`support_top_z_distance = 0.3`. Verified with the Bambu Studio CLI: it slices (about 2 h 58 min). Against the
same plate without the overrides, the support interface sections drop from 53 to 19.

## 2026-11-21: measurements confirmed, design locked

The owner confirmed every measurement against the real parts and locked the design, with the fits tuned on the
coupons. Final values:
- display: front of glass → board front 4.8, standoff tops 8.3, USB-C centre 16.57, deepest 18.0
- `usb_mouth_bx = -21.0`
- adapter: `adp_plug_to_socket = 21`, `adp_w = 18.5`, `adp_t = 8.1`, `adp_t_front = 3.5`,
  `adp_socket_x = 12.0`, `adp_above_plug = 1.5`, `adp_fit = 0.35`, `adp_cap_gap = 0.4`
- `socket_recess = 1.5`
- desk cable: `desk_plug_w/t/len = 13/7/15`, `usb_cable_d = 4.5`
- `pcb_t = 1.2`, `edge_thickness = 5.65`, strip 19 × 70 × 1.6, `pod_depth = 25.6`
- fits: `board_seat_d = 44.1`, `seat_rib_d = 43.1`, `seat_len = 4`, `slide_clearance = 0.25`, `edge_gap = 1.0`,
  `i2c_snap_w = 3.6`, `i2c_grip = 0.2`

The coupons are now optional, only for re-tuning on different hardware.

## 2026-11-22: the cap's tab joined solidly to the round part

The tab over the USB-C plug kept snapping off where it meets the round part, when the supports came off.
Two things weakened that joint:
- **A valley in the outside.** The cap is trimmed to the pod's outside shape, and right over the joint the
  outside dips: the root's rounded outboard back edge (`root_round = 2`, at `root_x1`) meets the round shell's
  receding dome in a valley deeper than the tab is thick (`plug_cap_z` to the back, 2.8 mm). A 1 mm slice of
  the old cap across the joint was empty: the tab hung on by a sliver.
- **A short neck.** The tab met the round part only where the keyhole's plug rectangle overlaps the board
  circle (about 13 mm in y). Beside that, a wall of the root (between the plug pocket and the screen bore)
  left a wedge-shaped slot between the tab and the round part.

Fix:
- `cap_joint_fill()`: the cap fills the valley with the hull of the outside over the joint
  (`cap_joint_x = [usb_mouth_x - 3, usb_mouth_x + 9]`, the plug's whole y range, up to `plug_cap_z`). The fill
  never goes behind the back plane.
- `tab_bridge()` / `tab_bridge_2d()`: through the cap's thickness only (up to `plug_cap_z`), the wall is cut
  out of the root and the cap fills the slot. It stays off `shell_outer`, so the round piece is unchanged
  (same volume, 10490.79 mm³) and keeps its ~1 mm sliver of the wall at the slot's far corner. The root
  loses 41 mm³, and its wall now ends square instead of in a thin curved fin.

New check `cap_tab_joint`: a 1 mm slice across the joint must hold more than 45 mm³ over at least 22 mm. It
measures 72 mm³ over 27 mm (the old cap had nothing there). All 59 tests pass and the print file slices
(2 h 59 min). Reprint the root and the cap together; the new cap does not fit an old root.
