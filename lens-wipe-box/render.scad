// README images (make images): same look as the other projects in this repo.
use <lens_wipe_tower.scad>
use <lens_wipe_box.scad>
view = "tower";       // tower | box
if (view == "tower") { color("#e9e7e2") tower(); color("#3a3a3c") lid_in_place(); }
if (view == "box")   color("#e9e7e2") modern_box();
