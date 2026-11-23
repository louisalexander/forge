// README images (make images): same look as the other projects in this repo.
use <freezer_bin.scad>

view = "bin";          // bin | stack | joint | break

$fn = 48;

body  = "#e9e7e2";
other = "#8d9499";

// Left half only, so a cut through the wall shows how the parts meet.
module half() {
    intersection() { children(); translate([-400, -400, -40]) cube([400, 800, 800]); }
}

// A slice straight through the left wall at one rim joint, in absolute coordinates so it spans
// both bins: the flange, the gap, and the wall of the bin above sitting inside it. Kept inside
// the solid bands -- the rim above z=142, and the floor's solid border within 12 mm of the wall
// -- so the section reads as material rather than as a row of holes.
module joint_clip() {
    intersection() { children(); translate([-106, 50, 141]) cube([18, 26, 29]); }
}

if (view == "bin") color(body) bin();

if (view == "break") color(body) break_test();

if (view == "stack")
    for (i = [0 : 2])
        translate([0, 0, i * stack_pitch()])
            color(i % 2 == 0 ? body : other) bin();

if (view == "joint") {
    color(body)  joint_clip() bin();
    color(other) joint_clip() translate([0, 0, stack_pitch()]) bin();
}
