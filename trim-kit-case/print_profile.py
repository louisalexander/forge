#!/usr/bin/env python3
"""Write flat Bambu Studio profiles for printing the trim case on a P2S (0.4 nozzle, PETG Matte).

  python3 print_profile.py OUTDIR                      -> OUTDIR/machine.json, process.json, filament.json
  python3 print_profile.py --project SEED.3mf OUT     -> OUT: SEED's merged project settings, tidied

Starts from the system profiles shipped with Bambu Studio (inheritance resolved) and applies the
settings picked for the two-colour inlays on the bed face. Bambu Studio's CLI merges these into the
project settings that pack_plate.py embeds in the print 3MF.
"""
import json
import os
import sys

PROFILES = "/Applications/BambuStudio.app/Contents/Resources/profiles/BBL"
MACHINE = "Bambu Lab P2S 0.4 nozzle"
PROCESS = "0.20mm Standard @BBL P2S"
FILAMENT = "Bambu PETG Matte @BBL P2S 0.4 nozzle"

# Process overrides: the inlays are 0.6 deep (3 layers) on the bed face, with 0.7 mm features.
PROCESS_SET = {
    "layer_height": "0.2",                  # inlay = exactly 3 layers
    "initial_layer_print_height": "0.2",
    "initial_layer_line_width": "0.42",     # was 0.5: resolves the 0.7 knurl lines and small islands
    "wall_generator": "arachne",            # thin features get real extrusions instead of being dropped
    "elefant_foot_compensation": "0",       # it shrinks each colour's first-layer outline and opens gaps
    "initial_layer_speed": ["25"] * 3,      # was 50
    "initial_layer_infill_speed": ["40"] * 3,   # was 105
    "reduce_crossing_wall": "1",            # avoid crossing walls: travel stays off fresh islands
    "enable_prime_tower": "1",
    "curr_bed_type": "Textured PEI Plate",
}
MACHINE_SET = {
    "z_hop_types": ["Spiral Lift"] * 3,     # was Auto Lift; z_hop stays 0.4
}


def load(kind, name):
    path = f"{PROFILES}/{kind}/{name}.json"
    d = json.load(open(path))
    if "inherits" in d:
        base = load(kind, d["inherits"])
        base.update(d)
        d = base
    return d


def flat(kind, name, overrides):
    d = load(kind, name)
    d.pop("inherits", None)
    d["from"] = "system"
    d.update(overrides)
    return d


COLOURS = ["#FFFFFF", "#000000"]   # filament 1 = case, filament 2 = inlays (remap to your AMS slots)


def project(seed, out):
    """Take the project settings Bambu Studio's CLI merged, set colours, mark what differs from system."""
    import zipfile
    d = json.loads(zipfile.ZipFile(seed).read("Metadata/project_settings.config"))
    d["filament_colour"] = COLOURS
    # 2 filaments -> 2x2 flush matrix (row = from, column = to), in mm³: white→black 170, black→white 670
    d["flush_volumes_matrix"] = ["0", "170", "670", "0"]
    d["flush_volumes_vector"] = ["140"] * 4
    diff = d.get("different_settings_to_system", [""] * 4)
    diff[0] = ";".join(sorted(PROCESS_SET))           # process
    diff[-1] = ";".join(sorted(MACHINE_SET))          # printer
    d["different_settings_to_system"] = diff
    with open(out, "w") as f:
        json.dump(d, f, indent=4)
    print(f"{out}: project settings")


def main():
    if sys.argv[1] == "--project":
        return project(sys.argv[2], sys.argv[3])
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for fname, d in (("machine.json", flat("machine", MACHINE, MACHINE_SET)),
                     ("process.json", flat("process", PROCESS, PROCESS_SET)),
                     ("filament.json", flat("filament", FILAMENT, {}))):
        with open(f"{out}/{fname}", "w") as f:
            json.dump(d, f, indent=1)
    print(f"{out}: machine, process, filament profiles written")


if __name__ == "__main__":
    main()
