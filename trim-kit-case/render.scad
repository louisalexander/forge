// Product renders for the README (make images). Two-colour look: case in filament 1, inlays in black.
include <trim_case.scad>
part = "none";
view = "closed";      // closed | open | stand
case_c  = "#e9e7e2";
inlay_c = "#1d1d1f";

module lid_dressed() { color(case_c) lid(); color(inlay_c) { if (ticks) ticks_part(); if (silhouette) sil_part(); } }
module body_dressed() { color(case_c) body(); color(inlay_c) if (logo == "inlay") logo_part(); }
module tools() { color("#b9bec4") for (y = rows) { translate([LO[1] + 0.3, y, LO[0]]) blade(); translate([UP[1] + 0.3, y, UP[0]]) blade(); }
                 color("#3a3a3c") xcyl(hy, hz, handle_d/2, hb, hb + handle_len); }

if (view == "closed") { body_dressed(); to_closed() lid_dressed(); }
if (view == "open")   { lid_dressed(); tools(); translate([0, W + 10, 0]) body_dressed(); }
if (view == "stand")  rotate([180, 0, 0]) { body_dressed(); at_angle(stop_a) to_closed() lid_dressed(); }
