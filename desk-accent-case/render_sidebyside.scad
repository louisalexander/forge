// README picture (make images): the earlier side-by-side case, its parts laid out, in print colours.
include <desk_accent_case.scad>
PART = "none";
color("#55575e") body();
color("#55575e") translate([0, OUT_W + 8, hold_len]) lid();
color("#d8ecf2", 0.8) translate([stick_cx, -(OUT_W + 6), 0]) window();
