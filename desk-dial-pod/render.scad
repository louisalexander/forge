// README pictures (make images): the pod in its print colours, charcoal PLA with the rose gold accent ring.
//   view = "full"  the whole pod (round piece + root)
//   view = "round" the round piece alone, so its face and accent ring can be seen
include <desk_dial_pod.scad>
part = "none";
view = "full";
charcoal = "#5a5c63";   // a shade lighter than the filament, so the renders show the form
rose_gold = "#c9927e";
color(charcoal) pod_round_body();
color(rose_gold) pod_accent();
if (view == "full") color(charcoal) pod_root();
