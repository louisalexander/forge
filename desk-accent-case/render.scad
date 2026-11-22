// README pictures (make images): the stacked case (the current pick), its parts laid out, in print colours.
include <desk_accent_case_stacked.scad>
PART = "none";
color("#55575e") body();
color("#55575e") translate([0, OUT_W + 6, WIRE_CLR + STICK_PCB + 1.0]) carrier();
color("#55575e") translate([0, 2 * OUT_W + 12, hold_c]) lid();
color("#d8ecf2", 0.8) translate([0, -(OUT_W + 4), 0]) window();
