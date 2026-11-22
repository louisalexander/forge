"""Desk dial knob + under-desk housing (desk_dial_knob_housing.scad).

Spec: docs/superpowers/specs/2026-11-14-desk-dial-knob-housing-design.md.
Frame: desk underside z = 0, desk front edge x = 0, x+ toward the chair, y across the desk (y = 0 the
knob's centre plane). The knob parts render in the KNOB frame: z = 0 the floor's underside, axis +z.
Skipped when OpenSCAD isn't installed (CI has none).
"""
import math
import shutil
import subprocess
from pathlib import Path

import pytest

from conftest import repo_path
from scadtest import _vertices, _volume, bbox, no_interference, render

SCAD = Path(repo_path("desk_dial_knob_housing.scad"))

pytestmark = pytest.mark.skipif(shutil.which("openscad") is None, reason="OpenSCAD not installed")

PLACEMENTS = [{}, {"knob_out": 30, "knob_down": 19.5}]   # the drawn split, and the more-out one


def r(part, tmp_path, **params):
    return render(part, tmp_path, scad=SCAD, **params)


def clear(part, tmp_path, **params):
    return no_interference(part, tmp_path, scad=SCAD, **params)


def refused(tmp_path, part, **params):
    """True when OpenSCAD logs an assertion failure for these parameters."""
    cmd = ["openscad", "--backend=manifold", "-o", str(tmp_path / "x.stl"), "-D", f'part="{part}"']
    for k, v in params.items():
        cmd += ["-D", f"{k}={v}"]
    res = subprocess.run(cmd + [str(SCAD)], capture_output=True, text=True, timeout=600)
    return "assertion" in (res.stdout + res.stderr).lower()


# ── Task 1: the knob ────────────────────────────────────────────────────────────
def test_knob_is_40_by_11(tmp_path):
    lo, hi = bbox(r("knob", tmp_path))
    assert hi[0] - lo[0] == pytest.approx(40, abs=0.1)
    assert hi[1] - lo[1] == pytest.approx(40, abs=0.1)
    assert (lo[2], hi[2]) == (pytest.approx(0, abs=0.01), pytest.approx(11, abs=0.01))


def test_floor_is_the_first_1_5_mm(tmp_path):
    lo, hi = bbox(r("knob_floor", tmp_path))
    assert (lo[2], hi[2]) == (pytest.approx(0, abs=0.01), pytest.approx(1.5, abs=0.01))
    assert bbox(r("knob_body", tmp_path))[0][2] == pytest.approx(1.5, abs=0.01)


def test_floor_and_body_never_overlap(tmp_path):
    assert clear("knob_floor_x_body", tmp_path)


def test_d_bore_is_the_shaft_plus_fit(tmp_path):
    floor = [v for v in set(_vertices(r("knob", tmp_path)))
             if abs(v[2] - 7.5) < 0.02 and math.hypot(v[0], v[1]) < 3.6]
    xs, ys = [v[0] for v in floor], [v[1] for v in floor]
    assert max(ys) - min(ys) == pytest.approx(6.20, abs=0.02)    # the round side: 6.0 + 0.20
    assert max(xs) - min(xs) == pytest.approx(4.65, abs=0.02)    # across the flat: 4.5 + 0.15


def test_refuses_a_flat_outside_the_shaft(tmp_path):
    assert refused(tmp_path, "knob", shaft_flat=6.5)
# ── Revision 2 (spec §7), Task 1: the body — round head, neck, plate ────────────
@pytest.mark.parametrize("placement", PLACEMENTS)
def test_body_never_enters_the_desk(tmp_path, placement):
    assert r("body", tmp_path, **placement) is not None
    assert clear("body_x_desk", tmp_path, **placement)


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_knob_never_enters_the_desk(tmp_path, placement):
    assert clear("knob_x_desk", tmp_path, **placement)


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_pinch_finger_room(tmp_path, placement):
    # the knob's envelope grown radially by finger_room (15) must stay out of the desk ...
    assert clear("finger_x_desk", tmp_path, **placement)


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_finger_room_clear_of_the_body(tmp_path, placement):
    # ... and out of the neck and plate, now that they come up to the desk corner
    assert clear("finger_x_body", tmp_path, **placement)


def test_finger_room_check_catches_a_cramped_knob(tmp_path):
    assert not clear("finger_x_desk", tmp_path, knob_out=10, knob_down=22)   # the v1 drawing: 2.7 mm


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_knob_clears_the_body(tmp_path, placement):
    assert clear("knob_x_body", tmp_path, **placement)


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_pressing_the_knob_clears_the_body(tmp_path, placement):
    assert clear("knob_pressed_x_body", tmp_path, **placement)   # push-switch travel 0.5 along n


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_tape_face_is_flat_and_big_enough(tmp_path, placement):
    lo, hi = bbox(r("tape_face", tmp_path, **placement))
    assert hi[2] == pytest.approx(-1.0, abs=0.01) and hi[2] - lo[2] < 0.25    # flat, under 1 mm of tape
    assert hi[0] - lo[0] >= 45 and hi[1] - lo[1] >= 45


def _radii(stl):
    return [math.hypot(v[0], v[1]) for v in _vertices(stl)]


def test_head_is_56_across(tmp_path):
    # the head in the face frame: a disc of r 28 round the knob's axis (the ring round the knob)
    assert max(_radii(r("head_on_face", tmp_path))) == pytest.approx(28, abs=0.1)


def test_accent_ring_inlays_into_the_body(tmp_path):
    assert r("accent_ring", tmp_path) is not None
    assert clear("accent_x_body", tmp_path)


def test_body_prints_face_down(tmp_path):
    # one print, the face (with the accent inlay) as the first layer
    lo, hi = bbox(r("body_print", tmp_path))
    assert lo[2] == pytest.approx(0, abs=0.01)
    assert bbox(r("accent_ring_print", tmp_path))[0][2] == pytest.approx(0, abs=0.01)
    assert clear("accent_x_body_print", tmp_path)


# ── Light path ──────────────────────────────────────────────────────────────────
def test_diffuser_covers_the_glow_band(tmp_path):
    rad = _radii(r("diffuser_ring_print", tmp_path))
    assert min(rad) < 12
    assert any(abs(x - 21.0) < 0.05 for x in rad)
    assert max(rad) == pytest.approx(22.5, abs=0.05)


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_nothing_opaque_in_the_light_path(tmp_path, placement):
    assert clear("light_path_x_opaque", tmp_path, **placement)


def test_light_path_check_catches_an_opaque_post(tmp_path):
    assert not clear("light_path_x_opaque", tmp_path, debug_post=1)


def test_diffuser_is_captured_not_fused(tmp_path):
    assert clear("diffuser_x_body", tmp_path)
    assert clear("diffuser_x_cup", tmp_path)
    assert not clear("diffuser_lip_x_front_wall", tmp_path)   # the lip can't pull out through the face


def test_diffuser_has_print_clearance_in_the_face(tmp_path):
    assert clear("diffuser_grown_x_body", tmp_path)


def test_accent_starts_at_the_face_hole(tmp_path):
    rad = _radii(r("accent_on_face", tmp_path))
    hole = _radii(r("face_hole_on_face", tmp_path))
    assert min(rad) == pytest.approx(max(hole), abs=0.02)


# ── Task 2: board, light cup, back cap ──────────────────────────────────────────
@pytest.mark.parametrize("shaft", [20, 22, 26])
def test_shaft_tip_lands_at_the_bore_floor(tmp_path, shaft):
    tip = bbox(r("board_on_face", tmp_path, shaft_above_board=shaft))[1][2]
    assert tip == pytest.approx(1.5 + 7.5, abs=0.02)
    assert bbox(r("knob_on_face", tmp_path, shaft_above_board=shaft))[0][2] == pytest.approx(1.5, abs=0.01)


def test_refuses_a_shaft_too_short_for_the_light_box(tmp_path):
    assert refused(tmp_path, "assembly", shaft_above_board=12)


def test_refuses_a_bushing_that_would_hit_the_knob(tmp_path):
    assert refused(tmp_path, "assembly", shaft_above_board=18)


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_board_clears_everything(tmp_path, placement):
    assert r("board_envelope", tmp_path, **placement) is not None
    assert clear("board_x_everything", tmp_path, **placement)


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_cup_fits_and_is_located(tmp_path, placement):
    assert r("light_cup", tmp_path, **placement) is not None
    assert clear("cup_x_body", tmp_path, **placement)
    assert not clear("cup_grown_x_body", tmp_path, **placement)   # 0.3 bigger and it meets the bosses


@pytest.mark.parametrize("shaft", [20, 22, 26])
def test_stack_slides_out_the_back(tmp_path, shaft):
    # the cup with the board on it goes in from the back, along the axis: swept 30 mm back, never meets the body
    assert clear("stack_sweep_x_body", tmp_path, shaft_above_board=shaft)


@pytest.mark.parametrize("shaft", [20, 22, 26])
def test_cap_closes_the_head(tmp_path, shaft):
    assert r("back_cap", tmp_path, shaft_above_board=shaft) is not None
    assert clear("cap_x_body", tmp_path, shaft_above_board=shaft)   # it presses the cup: test_cap_presses_the_cup


def test_cap_screws_stay_out_of_the_light(tmp_path):
    assert r("cap_screws", tmp_path) is not None
    assert clear("cap_screws_x_light", tmp_path)


# ── Task 3: wires, GX12 block, cover ────────────────────────────────────────────
@pytest.mark.parametrize("placement", PLACEMENTS)
def test_wires_reach_the_socket(tmp_path, placement):
    # a ø2.4 bundle from behind the board's pad edge, round the cup, down the neck, along the plate,
    # into the block: nothing solid in the way
    assert r("wire_path", tmp_path, **placement) is not None
    assert clear("wire_x_solids", tmp_path, **placement)


CONNECTORS = ["\"m8\"", "\"gx12\""]   # the socket options (the default is the pigtail)


@pytest.mark.parametrize("connector", CONNECTORS)
@pytest.mark.parametrize("placement", PLACEMENTS)
def test_socket_fits(tmp_path, placement, connector):
    assert clear("conn_x_everything", tmp_path, connector=connector, **placement)


@pytest.mark.parametrize("connector", CONNECTORS)
def test_wires_drop_clear_of_either_socket(tmp_path, connector):
    assert clear("wire_x_socket_zone", tmp_path, connector=connector)


def test_m8_block_is_small(tmp_path):
    # owner, 2026-11-14: "make the box with the connector smaller". M8 4-pin, nut outside: the block
    # below the chamfer into the plate is at most 21 wide, and the whole block hangs <= 15 + the chamfer
    lo, hi = bbox(r("block_below_plate", tmp_path, connector='"m8"'))
    assert hi[1] - lo[1] <= 21 and hi[2] - lo[2] <= 15 - 5


def test_socket_faces_the_wall(tmp_path):
    # the socket's hole is in the body's back face, the end nearest the wall
    hole = bbox(r("conn_hole", tmp_path, connector='"m8"'))
    body = bbox(r("body", tmp_path, connector='"m8"'))
    assert hole[0][0] <= body[0][0] + 3.01   # the block sits 3 in from the plate's rounded back edge


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_ltc4311_fits_when_asked_for(tmp_path, placement):
    assert clear("ltc_x_everything", tmp_path, ltc_room="true", connector='"m8"', **placement)


def test_no_ltc4311_room_by_default(tmp_path):
    # owner, 2026-11-14: the LTC4311 goes at the start of the bus (the pod), per Adafruit's guide; the
    # block only holds the socket unless ltc_room = true
    assert r("block_cover", tmp_path, connector='"m8"') is not None
    assert r("ltc_posts", tmp_path, connector='"m8"') is None


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_cover_closes(tmp_path, placement):
    assert r("block_cover", tmp_path, connector='"m8"', **placement) is not None
    assert clear("cover_x_body", tmp_path, connector='"m8"', **placement)


def test_cable_clip_grips_the_cable(tmp_path):
    assert r("cable_clip", tmp_path) is not None
    assert clear("cable_x_clip", tmp_path)
    assert not clear("cable_lifted_x_clip", tmp_path)


# ── Task 4: exports, mock-up ────────────────────────────────────────────────────
# knob_body_print and accent_ring_print are AMS parts in their partner's frame (the floor; the body)
PRINT_PARTS = ["knob_floor_print", "body_print", "light_cup_print", "back_cap_print",
               "diffuser_ring_print", "cable_clip_print", "mockup_print"]


@pytest.mark.parametrize("part", PRINT_PARTS)
def test_every_print_part_exports_on_the_bed(tmp_path, part):
    out = r(part, tmp_path)
    assert out is not None
    assert bbox(out)[0][2] == pytest.approx(0, abs=0.01)


def test_mockup_is_the_housing_outline(tmp_path):
    lo_m, hi_m = bbox(r("mockup_print", tmp_path))
    lo_b, hi_b = bbox(r("outline_print", tmp_path))   # the body + its back cap
    for i in range(3):
        assert hi_m[i] - lo_m[i] == pytest.approx(hi_b[i] - lo_b[i], abs=0.05)


def _watertight(stl):
    """Every edge shared by exactly two triangles, in opposite directions (what slicers call manifold).
    Zero-area slivers (two corners rounding to one point in the float32 STL) are skipped, as slicers do."""
    import collections
    pts = _vertices(stl)
    key = lambda p: tuple(round(c, 4) for c in p)
    edges = collections.Counter()
    for i in range(0, len(pts), 3):
        a, b, c = key(pts[i]), key(pts[i + 1]), key(pts[i + 2])
        if len({a, b, c}) < 3:
            continue
        for u, w in ((a, b), (b, c), (c, a)):
            edges[(u, w)] += 1
    bad = [e for e, n in edges.items() if n != 1 or edges.get((e[1], e[0]), 0) != 1]
    return len(bad)


@pytest.mark.parametrize("part", PRINT_PARTS + ["knob_body_print", "accent_ring_print"])
def test_every_print_part_is_watertight(tmp_path, part):
    # owner, 2026-11-14: Bambu Studio flagged desk_dial_kh_knob_body.stl — 52 non-manifold edges
    assert _watertight(r(part, tmp_path)) == 0


def _island_starts(stl):
    """Points where a layer would start in mid-air: a vertex (or a flat patch at one height) above the bed
    whose neighbours are all higher and that carries no upward-facing triangle (a hole's floor does)."""
    import collections
    pts, idx, nb, up = [], {}, collections.defaultdict(set), collections.defaultdict(bool)
    raw = _vertices(stl)
    for i in range(0, len(raw) - 2, 3):
        tri = []
        for p in raw[i:i + 3]:
            k = tuple(round(c, 4) for c in p)
            if k not in idx:
                idx[k] = len(pts)
                pts.append(k)
            tri.append(idx[k])
        a, b, c = (pts[j] for j in tri)
        u, v = [b[n] - a[n] for n in range(3)], [c[n] - a[n] for n in range(3)]
        cr = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        length = math.sqrt(sum(x * x for x in cr)) or 1
        for j in tri:
            nb[j] |= set(tri) - {j}
            up[j] |= cr[2] / length > 0.05
    seen, starts = set(), []
    for v, p in enumerate(pts):
        if v in seen or p[2] < 0.05:
            continue
        grp, stack, lower = {v}, [v], False
        while stack:
            for w in nb[stack.pop()]:
                if abs(pts[w][2] - p[2]) < 1e-3:
                    if w not in grp:
                        grp.add(w)
                        stack.append(w)
                elif pts[w][2] < p[2]:
                    lower = True
        seen |= grp
        if not lower and not any(up[g] for g in grp):
            starts.append(p)
    return starts


@pytest.mark.parametrize("part", PRINT_PARTS + ["accent_ring_print"])
def test_no_print_part_starts_in_mid_air(tmp_path, part):
    # owner, 2026-11-15: Bambu Studio: "floating regions" on the body + accent object — the cap bosses'
    # cone tips started 0.7 mm off the head wall, and slivers stood where the face hole meets the accent pocket
    assert _island_starts(r(part, tmp_path)) == []


# ── Final review fixes (rev 2) ───────────────────────────────────────────────────
def test_board_is_screwed_from_the_front(tmp_path):
    # I1: screws from the front through the board's 2.7 holes bite the cup's posts, and their heads stop
    # the board sliding toward the face when the knob is pulled
    assert r("board_screws_bite_cup", tmp_path) is not None
    assert r("board_pulled_x_screw_heads", tmp_path) is not None


def test_wires_drop_clear_of_the_socket(tmp_path):
    # I2: the channel drops into the block past the socket's body + 5 mm of solder cups and heat-shrink
    assert clear("wire_x_socket_zone", tmp_path, connector='"gx12"')


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_channel_keeps_a_wall(tmp_path, placement):
    # I3: the wire channel grown by 0.8 mm stays inside the body's outline everywhere
    assert clear("channel_wall_breach", tmp_path, **placement)


def test_cap_screw_holes_stay_inside_the_cap(tmp_path):
    # I5 (re-graded): the cap's screw holes don't break out of its rim
    assert clear("cap_hole_breakout", tmp_path)


def test_head_back_rim_is_a_full_wall(tmp_path):
    # I5 (re-graded): no knife edge at the head's back: its back face is the full wall
    rad = _radii(r("head_back_face", tmp_path))
    assert min(rad) <= 25.65 and max(rad) >= 27.5   # in to the cavity, out to near the rim


@pytest.mark.parametrize("shaft", [20, 22, 26])
def test_cap_presses_the_cup(tmp_path, shaft):
    # I7 (re-graded): the cap's ring stands 0.2 proud, so the cup is always clamped, never rattling
    assert not clear("cap_x_cup", tmp_path, shaft_above_board=shaft)


# ── The print STL is the assembled part, every cut included (owner, 2026-11-16) ────────────
@pytest.mark.parametrize("part", ["body", "accent_ring", "light_cup", "back_cap", "diffuser_ring"])
def test_print_part_is_the_assembled_part(tmp_path, part):
    # back_cap_print was built from the bare cap, before the wires' notch was cut: the printed cap had none
    assembled = _volume(r(part, tmp_path))
    printed = _volume(r(f"{part}_print", tmp_path))
    assert printed == pytest.approx(assembled, rel=1e-3, abs=0.05)


# ── The real 5880 (Adafruit's board file, 2026-11-16): pads, LED, the parts on its back ─────
def test_led_faces_the_chair_by_default(tmp_path):
    # owner, 2026-11-16: the LED up or down the knob's axis, never off to one side. Default board_spin 0: the
    # pads face the neck (face -x) and the NeoPixel the chair (+x)
    lo, hi = bbox(r("led_on_face", tmp_path))
    assert lo[0] > 8 and hi[0] < 13 and abs(lo[1] + hi[1]) < 0.01


def test_led_can_face_the_neck_instead(tmp_path):
    lo, hi = bbox(r("led_on_face", tmp_path, board_spin=180))
    assert hi[0] < -8 and lo[0] > -13 and abs(lo[1] + hi[1]) < 0.01


def test_qt_cup_is_solid_on_the_neck_side(tmp_path):
    # owner, 2026-11-16: with the QT cable there's no solder slot and no neck-side hole through the cup,
    # just the side pockets and the groove on its back
    assert r("cup_at_neck_slot", tmp_path) is not None
    assert r("cup_at_neck_slot", tmp_path, wiring='"solder"') is None


def test_side_qt_plugs_route_round_the_cups_back_to_the_neck(tmp_path):
    # board_spin 0 or 180 (owner, 2026-11-16): the sockets are on the ±y edges. Either plug drops through a
    # hole at its edge and the cable lies flat in a groove round the cup's back into the neck groove
    assert r("qt_plug_side", tmp_path) is not None
    assert clear("qt_plug_side_x_cup", tmp_path)
    assert clear("qt_plug_side_x_cap", tmp_path)


def _poor_overhangs(stl, min_deg=44, cap_w=2.0):
    """Downward faces above the bed shallower than min_deg (0 = a flat ceiling). A flat cap narrower than
    cap_w (a teardrop's top) bridges fine and is allowed, and so is a sliver under 0.05 wide (export noise:
    the cone's top ring is 0.02 inside the plate's edge). Returns (x, y, z, angle) of the offenders."""
    raw, bad = _vertices(stl), []
    for i in range(0, len(raw) - 2, 3):
        a, b, c = raw[i:i + 3]
        u, v = [b[n] - a[n] for n in range(3)], [c[n] - a[n] for n in range(3)]
        cr = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        n = math.sqrt(sum(x * x for x in cr)) or 1
        cz = (a[2] + b[2] + c[2]) / 3
        longest = max(math.dist(p, q) for p, q in ((a, b), (b, c), (c, a)))
        if cr[2] / n > -0.5 or cz < 0.05 or n / longest < 0.05:   # n / longest: the triangle's height
            continue
        ang = math.degrees(math.acos(-cr[2] / n))
        on_t = (max(abs(p[1]) for p in (a, b, c)) <= cap_w / 2 + 1e-3        # the neck groove and the stem
                or max(abs(p[0]) for p in (a, b, c)) <= cap_w / 2 + 1e-3)    # the bar across the middle
        flat_cap = ang < 1 and on_t
        if ang < min_deg and not flat_cap:
            bad.append((round(a[0], 1), round(a[1], 1), round(cz, 2), round(ang)))
    return bad


def test_cup_has_no_poor_overhang(tmp_path):
    # owner, 2026-11-16, "improve the chance of print success": printed plug down, every face that hangs
    # over the bed is 44° or steeper; the only flats are the grooves' narrow teardrop caps. (The round-rim
    # groove printed as spaghetti twice: its roof was a curved 4.8 bridge)
    assert _poor_overhangs(r("light_cup_print", tmp_path)) == []


def test_every_wire_groove_in_the_cup_has_one_shape(tmp_path):
    # owner, 2026-11-16: "why not make everything that nice round shape". The T's cross-section is the neck
    # groove's teardrop: the same width and the same depth
    (bx0, _, bz0), (bx1, _, bz1) = bbox(r("qt_bar_section", tmp_path))
    (_, ny0, nz0), (_, ny1, nz1) = bbox(r("neck_section", tmp_path))
    assert bx1 - bx0 == pytest.approx(ny1 - ny0, abs=0.05)
    assert (bz0, bz1) == (pytest.approx(nz0, abs=0.05), pytest.approx(nz1, abs=0.05))


def test_side_groove_is_a_t_through_the_middle(tmp_path):
    # the owner's sketch: straight across between the side holes, then straight up the middle to the neck
    assert r("qt_groove_centre", tmp_path) is not None   # the groove crosses the cup's centre
    assert r("qt_groove_stem", tmp_path) is not None     # and runs from there toward the neck
    assert r("qt_groove_rim", tmp_path) is None          # and nothing runs round the rim any more


def test_cable_groove_misses_the_board_screws(tmp_path):
    # the groove passes under the board's corner posts: their screw holes stop short of it
    assert r("qt_groove", tmp_path) is not None
    assert clear("qt_groove_x_screw_holes", tmp_path)


def test_wires_drop_straight_from_the_pads_through_the_cup(tmp_path):
    # 3V, GND, SCL, SDA: the middle four of the six pads, 2.54 apart, ø1.78. A ø1.6 lead goes straight back
    # from each, through the cup's slot and plug, without touching it
    assert r("pad_leads", tmp_path, wiring='"solder"') is not None
    assert clear("pad_leads_x_cup", tmp_path, wiring='"solder"')


def test_board_back_parts_clear_the_cup(tmp_path):
    # the STEMMA QT sockets (~2.9 tall) and the encoder's soldered pins stand off the board's back
    assert r("board_back_envelope", tmp_path) is not None
    assert clear("board_back_x_cup", tmp_path)


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_a_22_awg_bundle_fits_the_whole_route(tmp_path, placement):
    # four 22 AWG pigtail leads (ø1.6 each) bundle to ~ø3.9: the probe is that size end to end
    assert clear("wire_x_solids", tmp_path, wire_r=1.95, **placement)
    assert clear("wire_x_solids", tmp_path, wire_r=1.95, wiring='"solder"', **placement)   # pads → slot too


# ── The cup keys into the cap (owner, 2026-11-15): no wiggle ────────────────────
@pytest.mark.parametrize("shift", ["[0.1, 0, 0]", "[0, 0.1, 0]", "[-0.1, 0, 0]"])
def test_cup_is_keyed_into_the_cap(tmp_path, shift):
    # with the cap just seated (backed off by its press), the cup touches it, and 0.1 mm sideways it can't move
    assert clear("cap_seated_x_cup", tmp_path)
    assert not clear("cap_seated_x_cup_shifted", tmp_path, cup_shift=shift)


@pytest.mark.parametrize("shaft", [20, 22, 26])
def test_cup_plug_keeps_the_wire_groove(tmp_path, shaft):
    # the plug fills the gap behind the cup: the wires lie in a groove through it, then the cap's notch
    assert clear("wire_x_solids", tmp_path, shaft_above_board=shaft)


# ── No right angles where possible (owner, 2026-11-14) ──────────────────────────
@pytest.mark.parametrize("placement", PLACEMENTS)
def test_tape_face_corners_are_rounded(tmp_path, placement):
    # gel tape starts peeling at a sharp corner
    assert clear("tape_corner_probe", tmp_path, **placement)


def test_block_edges_are_rounded(tmp_path):
    assert clear("block_edge_probe", tmp_path, connector='"m8"')


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_inside_corners_are_filled(tmp_path, placement):
    # the neck's back meets the plate at 45°, the block's front at 90°: both carry the knob's press
    assert r("neck_corner_probe", tmp_path, **placement) is not None
    assert r("block_corner_probe", tmp_path, connector='"m8"', **placement) is not None


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_cap_clears_the_fillets(tmp_path, placement):
    assert clear("cap_x_body", tmp_path, **placement)


# ── Pigtail (owner, 2026-11-14): a JST-SM 4-pin pigtail out of the plate's back, no connector block ──
def test_pigtail_has_no_block(tmp_path):
    assert r("block_below_plate", tmp_path) is None
    assert r("block_cover", tmp_path) is None


@pytest.mark.parametrize("placement", PLACEMENTS)
def test_pigtail_leaves_through_the_plate_back(tmp_path, placement):
    # the wire probe runs from behind the board out past the plate's back end, through nothing solid
    lo, _ = bbox(r("wire_path", tmp_path, **placement))
    assert lo[0] < -72
    assert clear("wire_x_solids", tmp_path, **placement)


def test_pigtail_is_tied_down(tmp_path):
    # a zip tie through the bar under the plate holds the pigtail: a tug never reaches the solder joints
    assert r("tie_bar", tmp_path) is not None
    assert clear("tie_x_wires", tmp_path)          # the tie's slot doesn't cut the wires' path
    assert r("tie_slot_open", tmp_path) is None    # a 3.6 × 1.6 zip tie passes through the bar


@pytest.mark.parametrize("connector", CONNECTORS)
def test_block_cover_prints_on_the_bed(tmp_path, connector):
    out = r("block_cover_print", tmp_path, connector=connector)
    assert bbox(out)[0][2] == pytest.approx(0, abs=0.01) and _watertight(out) == 0


# ── Snap-together knob (owner, 2026-11-15): clear PETG floor + charcoal PLA body, printed apart ───
# Knob frame: z = 0 the floor's underside, axis +z. The joint lives round the shaft, inside r 8: the glow
# enters the floor's underside at r 12-21 and shows at its edge, so nothing may change out there.
def test_snap_floor_keeps_the_light_ring_clear(tmp_path):
    assert clear("snap_floor_x_light_ring", tmp_path)     # the floor beyond r 8 is still a plain 1.5 disc
    assert clear("snap_body_x_light_ring", tmp_path)      # the body's underside beyond r 8 is untouched


def test_snap_halves_seat_without_clashing(tmp_path):
    assert r("snap_floor", tmp_path) is not None and r("snap_body", tmp_path) is not None
    assert clear("snap_floor_x_body", tmp_path)


def test_snap_barb_holds_the_floor_on(tmp_path):
    # pulled 0.6 mm off, the barb meets the groove's catch face: it can't just fall off
    assert not clear("snap_floor_pulled_x_body", tmp_path)


def test_snap_halves_turn_together(tmp_path):
    # the hub's outside is a D: turned 5° in the body's pocket, it bears on the pocket's flat
    assert not clear("snap_floor_turned_x_body", tmp_path)


def test_snap_knob_has_the_fused_knobs_outline_and_bore(tmp_path):
    lo_s, hi_s = bbox(r("snap_knob", tmp_path))
    lo_k, hi_k = bbox(r("knob", tmp_path))
    for i in range(3):
        assert lo_s[i] == pytest.approx(lo_k[i], abs=0.02) and hi_s[i] == pytest.approx(hi_k[i], abs=0.02)
    assert clear("shaft_x_snap_knob", tmp_path)            # the shaft still slides in to the bore's floor


@pytest.mark.parametrize("part", ["mockup_knob_floor_print", "mockup_knob_body_print"])
def test_snap_prints_on_the_bed_watertight(tmp_path, part):
    out = r(part, tmp_path)
    assert bbox(out)[0][2] == pytest.approx(0, abs=0.01)
    assert _watertight(out) == 0


def test_refuses_a_snap_that_would_crack_the_petg(tmp_path):
    assert refused(tmp_path, "snap_floor", barb=0.8)
