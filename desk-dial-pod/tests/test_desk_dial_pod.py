"""Desk dial monitor pod (desk_dial_pod.scad).

Drives the OpenSCAD CLI headless. Frame: origin at the monitor's front-left corner, y up,
z = 0 the front glass plane (z+ toward the chair). OpenSCAD is right-handed, so x+ is the
viewer's right: for the owner's LEFT-edge install (`side = "left"`, the default) the monitor
occupies x >= 0, -5.65 <= z <= 0, and the pod is outboard toward x-.
Skipped when OpenSCAD isn't installed (CI has none).
"""
import shutil
import struct
import subprocess
from pathlib import Path

import pytest

from conftest import repo_path

SCAD = Path(repo_path("desk_dial_pod.scad"))

pytestmark = pytest.mark.skipif(shutil.which("openscad") is None, reason="OpenSCAD not installed")


def render(part, tmp_path, scad=SCAD, **params):
    """Export one part to STL. None when the part is empty (the interference checks)."""
    out = tmp_path / f"{part}.stl"
    cmd = ["openscad", "--backend=manifold", "--export-format=asciistl", "-o", str(out),
           "-D", f'part="{part}"']
    for k, v in params.items():
        cmd += ["-D", f"{k}={v}"]
    res = subprocess.run(cmd + [str(scad)], capture_output=True, text=True, timeout=600)
    log = res.stdout + res.stderr
    assert "ERROR" not in log and "assert" not in log.lower(), log   # e.g. an unknown part name
    assert "Ignoring unknown" not in log, log                        # a missing module/variable
    if "top level object is empty" in log or not out.exists() or out.stat().st_size == 0:
        return None
    assert res.returncode == 0, log
    return out if _vertices(out) else None


def _vertices(stl):
    data = stl.read_bytes()
    if data[:5] == b"solid" and b"facet" in data[:1000]:
        return [tuple(float(t) for t in line.split()[1:4])
                for line in data.decode().splitlines() if line.strip().startswith("vertex")]
    n = struct.unpack("<I", data[80:84])[0]
    pts = []
    for i in range(n):
        off = 84 + i * 50 + 12
        for j in range(3):
            pts.append(struct.unpack("<3f", data[off + 12 * j: off + 12 * j + 12]))
    return pts


def _volume(stl):
    pts = _vertices(stl)
    v = 0.0
    for i in range(0, len(pts) - 2, 3):
        (ax, ay, az), (bx, by, bz), (cx, cy, cz) = pts[i], pts[i + 1], pts[i + 2]
        v += (ax * (by * cz - bz * cy) - ay * (bx * cz - bz * cx) + az * (bx * cy - by * cx)) / 6
    return abs(v)


def no_interference(part, tmp_path, scad=SCAD, **params):
    """Empty, or only faces that touch (zero volume) — never material inside material."""
    out = render(part, tmp_path, scad=scad, **params)
    return out is None or _volume(out) < 0.01


def bbox(stl):
    pts = _vertices(stl)
    lo = tuple(min(p[i] for p in pts) for i in range(3))
    hi = tuple(max(p[i] for p in pts) for i in range(3))
    return lo, hi


# ── Task 1 ──────────────────────────────────────────────────────────────────────

def test_monitor_envelope_matches_the_measured_edge(tmp_path):
    lo, hi = bbox(render("envelope", tmp_path))
    assert lo[0] == pytest.approx(0) and hi[2] == pytest.approx(0)
    assert lo[2] == pytest.approx(-5.65)


# ── Task 2: bracket ─────────────────────────────────────────────────────────────

def test_bracket_never_enters_the_monitor(tmp_path):
    assert no_interference("bracket_x_monitor", tmp_path)


def test_bracket_lip_stays_two_mm_off_the_glass(tmp_path):
    lo, hi = bbox(render("bracket", tmp_path))
    assert hi[2] <= -2.0 + 1e-6


def test_bracket_lip_is_the_edge_gap(tmp_path):
    lo, hi = bbox(render("bracket", tmp_path))
    assert lo[0] == pytest.approx(-1.0)


def test_strip_pocket_keeps_a_wall_inside_the_rounded_plate(tmp_path):
    # owner, 2026-11-09: the plate's corners were rounded and its back chamfered; the Command strip's
    # pocket must still have plastic all round it, or the pad's edge peels at an open corner
    assert no_interference("strip_wall_breach", tmp_path)


def test_bracket_rail_runs_vertically(tmp_path):
    lo, hi = bbox(render("rail", tmp_path))
    assert (hi[1] - lo[1]) > 3 * max(hi[0] - lo[0], hi[2] - lo[2])


# ── Task 3: pod ─────────────────────────────────────────────────────────────────

def test_pod_face_is_flush_with_the_glass(tmp_path):
    lo, hi = bbox(render("pod", tmp_path))
    assert hi[2] == pytest.approx(0, abs=0.05)


def test_pod_visible_width_is_the_screen_circle_plus_a_three_mm_rim(tmp_path):
    # owner, 2026-11-06: the circle the screen fits inside (ø44.1 since 2026-11-13), with 3 mm of plastic
    # around it -> a 50.1 face, outboard of the 1.0 lip + 0.25 slide clearance (was a fixed 60 mm: ~6 mm of rim)
    lo, hi = bbox(render("pod", tmp_path))
    assert lo[0] == pytest.approx(-(1.0 + 0.25 + 44.1 + 2 * 3), abs=0.3)


def test_the_screen_seat_is_44_1():
    # owner, 2026-11-13: the circle the screen fits inside, 1 mm over the 43.1 that was too tight. NOT the window, which stays a lip over the
    # glass edge (screen_active_d + 1) and is what stops the screen from the front
    assert _scad_number("board_seat_d") == 44.1


def test_the_face_lip_holds_the_glass_from_the_front(tmp_path):
    lip = render("glass_x_face", tmp_path)
    assert lip is not None and _volume(lip) > 50


def test_the_cap_tab_over_the_plug_is_not_a_wafer(tmp_path):
    # the tab that closes the USB-C plug's pocket snapped off at 1.2 mm thick (owner, 2026-11-06)
    tab = render("cap_plug_tab", tmp_path)
    assert tab is not None
    lo, hi = bbox(tab)
    assert hi[2] - lo[2] >= 2.5


def test_the_cap_tab_is_joined_to_the_round_part(tmp_path):
    # the tab snapped off taking the supports off (owner, 2026-11-22): the pod's outside dips into a valley over
    # the joint, and the cap trimmed to it had NOTHING in a 1 mm slice across the joint; beside the ~13 mm neck,
    # a wall of the root left a slot. Now the slice runs the plug's whole length at nearly the tab's thickness
    joint = render("cap_tab_joint", tmp_path)
    assert joint is not None
    assert _volume(joint) > 45
    lo, hi = bbox(joint)
    assert hi[1] - lo[1] >= 22


def test_assembly_never_enters_the_monitor(tmp_path):
    assert no_interference("assembly_x_monitor", tmp_path)


def test_pod_does_not_collide_with_the_bracket(tmp_path):
    assert no_interference("pod_x_bracket", tmp_path)


def test_usb_plug_fits_inside_the_cavity(tmp_path):
    assert no_interference("plug_x_pod", tmp_path)


def test_pod_face_keeps_a_gap_to_the_panel_edge(tmp_path):
    lo, hi = bbox(render("pod_front_slab", tmp_path))
    assert hi[0] <= -1.0 + 1e-6


# ── Handedness: the pod is for the monitor's LEFT edge ──────────────────────────
# Every check above is symmetric under a mirror, so none of them noticed the parts were first
# exported for the RIGHT edge (x+ outboard in a right-handed frame). These pin the side.

def test_exported_parts_are_for_the_left_edge(tmp_path):
    # Seen from the chair (z+ toward the viewer, y up, x+ to the right), the left edge's outboard
    # side is x-. Each check below fails on the right-edge (unmirrored) export.
    env_lo, _ = bbox(render("envelope", tmp_path))
    assert env_lo[0] == pytest.approx(0)                     # the monitor is to the RIGHT of x = 0
    pod_lo, pod_hi = bbox(render("pod", tmp_path))
    assert -pod_lo[0] > pod_hi[0]                            # the round face outboard (x-), the root behind
    br_lo, br_hi = bbox(render("bracket", tmp_path))
    assert br_hi[0] > -br_lo[0]                              # the plate behind the monitor, only the lip outboard
    cap_lo, cap_hi = bbox(render("cap", tmp_path))
    assert -cap_lo[0] > 3 * cap_hi[0]                        # the cap closes the fin's back, outboard (only its
                                                             # plug cover reaches a few mm inboard)
    co_lo, co_hi = bbox(render("coupon", tmp_path))
    assert -co_lo[0] > co_hi[0]                              # the ring is laid out past the fin, outboard


def test_side_right_is_the_mirror_image(tmp_path):
    left = bbox(render("pod", tmp_path))                  # read before the next render overwrites it
    right = bbox(render("pod", tmp_path, side='"right"'))
    assert right[1][0] == pytest.approx(-left[0][0], abs=0.01)
    assert right[0][0] == pytest.approx(-left[1][0], abs=0.01)


# ── Task 4: coupon ──────────────────────────────────────────────────────────────

def test_coupon_is_small(tmp_path):
    # a quick print, about an hour. An absolute ceiling, not a fraction of the pod: the gauge face
    # halved the pod's volume while the coupon (face ring + the real cap) barely changed.
    coupon = render("coupon", tmp_path)
    assert coupon is not None
    assert _volume(coupon) < 31_000   # mm^3; ~28.4 cm^3 since the real adapter (2026-11-12)


def test_the_coupon_face_ring_holds_the_whole_glass_and_board(tmp_path):
    # deep enough that the glass + PCB sit fully inside it, as they will in the pod
    lo, hi = bbox(render("face_ring", tmp_path))
    assert hi[2] - lo[2] >= 1.2 + 4.8 + 1.2 - 0.05


def test_the_interference_check_catches_a_real_overlap(tmp_path):
    # Guard on the guard: a pod whose inner face is pulled 0.5 mm into the panel must register.
    assert not no_interference("assembly_x_monitor", tmp_path, slide_clearance=-1.5)


def test_every_cavity_keeps_a_wall(tmp_path):
    # Board seat, plug cavity and cable tunnel, each grown by 1 mm, must stay inside the pod's
    # outer solid — except the designed openings (screen window, slot, tunnel exit).
    assert no_interference("cavity_breach", tmp_path)


# ── Assembly: the electronics have to get in ────────────────────────────────────

def test_the_board_inserts_from_the_back(tmp_path):
    # A board-sized column from the seat straight out the back must be clear of the pod.
    assert no_interference("insertion_x_pod", tmp_path)


def test_the_back_cap_fits_and_closes_the_opening(tmp_path):
    cap = render("cap", tmp_path)
    assert cap is not None and _volume(cap) > 500
    assert no_interference("cap_x_pod", tmp_path)
    # with zero fit clearance the cap fills the opening exactly (only the pry undercut stays open)
    assert no_interference("back_left_open", tmp_path, cap_clearance=0)


# ── Final-review fixes ──────────────────────────────────────────────────────────

def test_board_and_plug_go_in_together_from_the_back(tmp_path):
    # The board with the right-angle plug already in it, swept straight out the back.
    assert no_interference("insertion_with_plug_x_pod", tmp_path)


@pytest.mark.parametrize("unseat", [0, 1, 3, 6, 12, 20])
def test_the_pod_slides_on_with_no_interference_anywhere(unseat, tmp_path):
    assert no_interference("pod_x_bracket_at", tmp_path, unseat=unseat)


def test_the_magnets_sit_in_their_pockets(tmp_path):
    assert no_interference("rail_magnet_x_bracket", tmp_path)
    assert no_interference("pod_magnet_x_pod", tmp_path)


def test_every_magnet_pocket_keeps_a_wall(tmp_path):
    assert no_interference("rail_magnet_breach", tmp_path)
    assert no_interference("pod_magnet_breach", tmp_path)


def test_seated_the_magnets_face_each_other_and_pull_the_pod_down(tmp_path):
    (rlo, rhi) = bbox(render("rail_magnet", tmp_path))
    (plo, phi) = bbox(render("pod_magnet_seated", tmp_path))
    # facing across the slide: pod magnet behind the rail's, gap = slide clearance + both recesses
    assert rlo[2] - phi[2] == pytest.approx(0.25 + 0.2 + 0.2, abs=0.02)
    # same column across the rail
    assert (plo[0] + phi[0]) / 2 == pytest.approx((rlo[0] + rhi[0]) / 2, abs=0.01)
    # the pod's magnet rests ABOVE the rail's, so their pull to line up presses the pod onto its stop
    assert (plo[1] + phi[1]) / 2 - (rlo[1] + rhi[1]) / 2 == pytest.approx(0.25, abs=0.02)


# ── The screen screws onto the cap (2026-11-03) ─────────────────────────────────
# The display has three brass M2 standoffs on its back. The glass covers the holes from the front,
# so the screws come in from the back of the cap, through three posts, into the standoffs.

import math
import re


def _scad_number(name):
    m = re.search(rf"^{name}\s*=\s*([-\d.]+)\s*;", SCAD.read_text(), re.M)
    return float(m.group(1)) if m else None


def _scad_list(name):
    m = re.search(rf"^{name}\s*=\s*(\[\[.*?\]\]);", SCAD.read_text(), re.M)
    return [(float(x), float(y)) for x, y in re.findall(r"\[([-\d.]+),\s*([-\d.]+)\]", m.group(1))] if m else []


def test_the_screw_holes_match_the_owners_triangle():
    # Owner, calipers across the OUTSIDE of the ø3.5 standoffs: 40.5 / 40.5 / 27.2.
    holes = _scad_list("mount_holes")
    assert len(holes) == 3
    sides = sorted(math.dist(a, b) + 3.5 for a, b in ((holes[0], holes[1]), (holes[1], holes[2]), (holes[2], holes[0])))
    assert sides[0] == pytest.approx(27.2, abs=0.2)
    assert sides[1] == pytest.approx(40.5, abs=0.2) and sides[2] == pytest.approx(40.5, abs=0.2)


def test_the_cap_posts_land_on_the_standoffs(tmp_path):
    assert no_interference("post_gap", tmp_path)        # nothing between each post's face and its brass


def test_the_cap_and_pod_clear_everything_on_the_board(tmp_path):
    # the XIAO, its USB-C, the coin-cell holder and the standoffs (posts only TOUCH the standoffs)
    assert no_interference("components_x_cap", tmp_path)
    assert no_interference("components_x_pod", tmp_path)
    assert no_interference("board_x_cap", tmp_path)
    assert no_interference("board_x_pod", tmp_path)


def test_the_screws_pass_freely_and_seat_on_the_cap(tmp_path):
    # shank through its clearance hole, head down in its counterbore: nothing in the way
    assert no_interference("screws_x_parts", tmp_path)


def test_a_screw_too_long_for_the_standoff_is_refused(tmp_path):
    # the tip would pass the PCB front and press on the glass; the model must refuse to build
    out = tmp_path / "x.stl"
    res = subprocess.run(["openscad", "--backend=manifold", "-o", str(out), "-D", 'part="cap"', "-D", "screw_engage=5",
                          str(SCAD)], capture_output=True, text=True, timeout=600)
    assert "hit the glass" in (res.stdout + res.stderr)


def test_the_plug_has_room_and_points_at_the_monitor(tmp_path):
    assert no_interference("plug_x_cap", tmp_path)
    assert no_interference("plug_slot_wall", tmp_path)
    lo, hi = bbox(render("plug", tmp_path))
    pod_lo, pod_hi = bbox(render("pod", tmp_path))
    env_lo, _ = bbox(render("envelope", tmp_path))
    # left edge: the monitor is at x >= 0, so "toward the monitor" is toward x+, and the plug's far
    # end must sit inboard of the board (whose centre is ~30 mm outboard)
    assert hi[0] > -10 and lo[0] > pod_lo[0] + 40


def test_the_desk_cable_plugs_up_into_the_socket_and_runs_into_the_clip(tmp_path):
    # owner, 2026-11-09: a right-angle adapter in the XIAO, its socket facing down out of the root's
    # bottom. The desk cable's grip reaches up through the opening; the cable bends inboard into the clip
    assert no_interference("cable_x_pod", tmp_path)
    assert no_interference("cable_x_cap", tmp_path)
    assert no_interference("cable_x_bracket", tmp_path)
    assert no_interference("opening_breach", tmp_path)     # opening + I2C channel keep a wall, open only downward
    assert no_interference("plug_slot_wall_extra", tmp_path)


def test_plugging_in_pushes_the_adapter_onto_plastic_not_the_xiao(tmp_path):
    # the root directly above the adapter block is solid: the push of plugging the desk cable in lands
    # there, never on the XIAO's surface-mount USB-C receptacle
    solid = render("adapter_ceiling", tmp_path)
    assert solid is not None
    box = _volume(render("adapter_ceiling_box", tmp_path))
    assert _volume(render("adapter_ceiling", tmp_path)) == pytest.approx(box, rel=0.01)


def test_the_cable_stays_behind_the_panel_at_the_clip(tmp_path):
    # the clip hangs below the plate wholly behind the monitor (x >= 0 on the left edge), so it can't be
    # seen from the chair
    assert _scad_number("channel_x") + 9 / 2 + 2 <= 0      # clip's outboard wall, built frame


def test_an_adapter_too_long_for_the_pod_is_refused(tmp_path):
    out = tmp_path / "x.stl"
    res = subprocess.run(["openscad", "--backend=manifold", "-o", str(out), "-D", 'part="pod"', "-D", "adp_plug_to_socket=40",
                          str(SCAD)], capture_output=True, text=True, timeout=600)
    assert "stick out of the bottom" in (res.stdout + res.stderr)


def test_rail_length_is_adjustable_and_has_a_floor(tmp_path):
    # owner, 2026-11-09: the rail's length is its own knob (rail_len), plus the ramp below it
    lo, hi = bbox(render("rail", tmp_path, rail_len=20, rail_ramp=6))
    assert hi[1] - lo[1] == pytest.approx(20 + 6, abs=0.05)
    out = tmp_path / "x.stl"
    res = subprocess.run(["openscad", "--backend=manifold", "-o", str(out), "-D", 'part="bracket"', "-D", "rail_len=10",
                          str(SCAD)], capture_output=True, text=True, timeout=600)
    assert "shorter than rail_len_min" in (res.stdout + res.stderr)


# ── Two-piece pod (2026-11-10): the round gauge and the root print separately ──

def test_the_two_pod_pieces_make_the_whole_pod_and_never_overlap(tmp_path):
    assert no_interference("split_overlap", tmp_path)
    whole = _volume(render("pod", tmp_path))
    rnd = _volume(render("pod_round", tmp_path, split_gap=0))
    root = _volume(render("pod_root", tmp_path, split_gap=0, seam_reveal=0))
    assert rnd + root == pytest.approx(whole, rel=1e-4)
    # with the glue gap the root's seat stands off the shell: a little less root, never more
    assert _volume(render("pod_root", tmp_path, seam_reveal=0)) < root
    # and the seam's shadow line (#227) takes a little more, only near the outside
    assert _volume(render("pod_root", tmp_path)) < _volume(render("pod_root", tmp_path, seam_reveal=0))


def test_the_round_piece_is_just_the_round_gauge(tmp_path):
    lo, hi = bbox(render("pod_round", tmp_path))
    assert hi[1] - lo[1] == pytest.approx(50.1, abs=0.1)     # the face circle, top to bottom
    assert hi[0] - lo[0] == pytest.approx(50.1, abs=0.1)     # and across: nothing of the root sticks out


def test_the_slot_magnet_and_cable_exits_are_all_in_the_root(tmp_path):
    assert no_interference("slot_x_round", tmp_path)


def test_the_pieces_are_exported_on_their_print_faces(tmp_path):
    lo, hi = bbox(render("pod_round_print", tmp_path))
    assert lo[2] == pytest.approx(0, abs=0.05) and hi[2] == pytest.approx(25.6, abs=0.05)   # face down
    lo, hi = bbox(render("pod_root_print", tmp_path))
    assert lo[2] == pytest.approx(0, abs=0.01)                                              # standing on its top
    # up to the root's bottom, or a little past it where the stem (#227) sweeps into the round, never past the gauge
    assert 50.1 / 2 + 17.3 - 0.1 <= hi[2] <= 50.1 + 0.05


# ── I2C cable (2026-11-10): a permanent 24 AWG 4-conductor run, pressed into a groove ──

def test_the_i2c_groove_grips_the_cable(tmp_path):
    # the cable seated in its groove overlaps the plastic: that squeeze is the grip
    assert _volume(render("i2c_grip", tmp_path)) > 5
    # with no squeeze and a slot as wide as the cable, the model refuses: the groove wouldn't hold
    res = subprocess.run(["openscad", "--backend=manifold", "-o", str(tmp_path / "x.stl"), "-D", 'part="pod"',
                          "-D", "i2c_snap_w=4.3", str(SCAD)], capture_output=True, text=True, timeout=600)
    assert "must be narrower than the cable" in (res.stdout + res.stderr)


def test_both_cables_fit_the_clip_side_by_side(tmp_path):
    assert no_interference("cables_x_each_other", tmp_path)
    assert no_interference("cable_x_bracket", tmp_path)
    assert no_interference("cable_x_pod", tmp_path)


def test_the_fittings_coupon_is_small(tmp_path):
    lo, hi = bbox(render("fittings_coupon", tmp_path))
    assert all(h - l < 60 for l, h in zip(lo, hi))


# ── Looks (#227, 2026-11-12): window bevel, two-colour accent ring, stem, seam shadow line ──

def test_the_accent_ring_is_its_own_part_and_adds_back_to_the_round(tmp_path):
    # the two-colour export: body + ring never overlap and together are exactly the round piece
    assert no_interference("accent_x_body", tmp_path)
    ring = render("pod_accent", tmp_path)
    assert ring is not None and _volume(ring) > 10
    rnd = _volume(render("pod_round", tmp_path))
    body = _volume(render("pod_round_body", tmp_path))
    assert body + _volume(ring) == pytest.approx(rnd, rel=1e-4)


def test_the_accent_ring_is_three_face_layers_on_the_print_bed(tmp_path):
    # face down, the ring is the first accent_t of the print: an AMS swap for 3 layers, then done
    lo, hi = bbox(render("pod_accent_print", tmp_path))
    assert lo[2] == pytest.approx(0, abs=0.02) and hi[2] == pytest.approx(0.48, abs=0.02)
    lo2, hi2 = bbox(render("pod_round_body_print", tmp_path))
    assert lo2[2] == pytest.approx(0, abs=0.05) and hi2[2] == pytest.approx(25.6, abs=0.05)   # same frame


def _scad_eval(expr, tmp_path):
    """Evaluate an expression in the model's scope (after all its assignments) via an .echo export."""
    out = tmp_path / "eval.echo"
    subprocess.run(["openscad", "-o", str(out), "-D", 'part="none"', "-D", f"__v = echo(__v = {expr}) 0", str(SCAD)],
                   capture_output=True, text=True)
    m = re.search(r"__v = ([-\d.e]+)", out.read_text())
    return float(m.group(1))


def test_the_window_bevel_opens_the_face_but_not_the_lip(tmp_path):
    # at the face the window is wider by the bevel all round (45 deg, the whole skin); the lip that holds
    # the glass (the window at the glass) is unchanged
    assert _scad_eval("window_bevel", tmp_path) == pytest.approx(_scad_eval("face_t", tmp_path))
    assert _scad_eval("win_d", tmp_path) == pytest.approx(32.4 + 1)
    lip = render("glass_x_face", tmp_path)
    assert lip is not None and _volume(lip) > 50


def test_the_stem_clears_the_desk_cable_opening(tmp_path):
    # the sweep under the socket block must leave the grip's way in open
    assert no_interference("cable_x_pod", tmp_path)
    grip_edge = _scad_eval("cable_x + desk_plug_w / 2 + desk_plug_fit", tmp_path)
    assert _scad_eval("stem_x0", tmp_path) >= grip_edge + 1


def test_the_cable_opening_is_centred_on_the_measured_socket_not_the_block(tmp_path):
    # owner, 2026-11-13: the adapter's socket is off-centre in its block. Centring the opening on the
    # block left a 4.65 mm gap on the socket's mouth side and hid its far edge behind the wall
    assert _scad_eval("usb_mouth_x - cable_x", tmp_path) == pytest.approx(12.0)
    # the opening still ends inside the far side of the adapter pocket
    assert _scad_eval("adp_socket_x + open_w / 2 - (adp_w + adp_fit)", tmp_path) < 0.5


def test_the_pry_point_lets_a_flathead_under_the_caps_lip(tmp_path):
    # owner, 2026-11-13: the old notch gave a blade nothing to lever on. A slot through the pod's bottom
    # rim reaches down past the cap's lip to the undercut behind it
    assert _scad_eval("pry_lip + pry_hook_h <= pry_slot_d ? 1 : 0", tmp_path) == 1
    assert _scad_eval("pry_w", tmp_path) >= 6
    assert no_interference("cap_x_pod", tmp_path)


def test_seat_ribs_centre_the_screen_on_the_window(tmp_path):
    # owner, 2026-11-13: the seat band went to 44.1 so the screen comes out without breaking the round,
    # and must still be perfectly centred: six ribs whose tips sit on the ø43.1 circle round the window
    # centre. A disc just inside that circle is clear; one just over it is gripped by every rib
    assert _scad_eval("seat_rib_d", tmp_path) == pytest.approx(43.1)
    assert no_interference("rib_probe_x_pod", tmp_path, probe_d=43.1 - 0.05)
    gripped = render("rib_probe_x_pod", tmp_path, probe_d=43.1 + 0.2)
    assert gripped is not None and _volume(gripped) > 0.01
    # all six touch, evenly: the overlap is symmetric about the window centre
    cx = _scad_eval("cx", tmp_path)
    lo, hi = bbox(gripped)
    assert abs((lo[0] + hi[0]) / 2) == pytest.approx(cx, abs=0.05)   # the export is mirrored for the left edge
    assert (lo[1] + hi[1]) / 2 == pytest.approx(0, abs=0.05)
