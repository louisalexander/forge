// README pictures (make images): the knob and its round-head housing in their print colours.
include <desk_dial_knob_housing.scad>
part = "none";
charcoal = "#5a5c63";   // a shade lighter than the filament, so the renders show the form
rose_gold = "#c9927e";
at_knob() { color("#cfe9f0", 0.9) knob_floor(); color("#202124") knob_body(); }
color(charcoal) body();
color(rose_gold) accent_ring();
color("#e8f4f7", 0.8) diffuser_ring();
color("#f2f0ea") light_cup();
color(charcoal) back_cap();
