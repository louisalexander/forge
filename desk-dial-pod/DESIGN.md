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

