#!/usr/bin/env python3
"""Flat Bambu Studio profiles for printing the freezer bin on a P2S (0.4 nozzle) in SUNLU PETG 2.0.

  python3 print_profile.py OUTDIR                   -> OUTDIR/machine.json, process.json, filament.json
  python3 print_profile.py --project SEED.3mf OUT   -> OUT: SEED's merged project settings, tidied

Starts from the profiles Bambu Studio ships, with inheritance resolved, and applies the overrides
below. Bambu Studio's CLI merges these into the project settings that pack_plates.py embeds.

On the filament: Bambu ships "SUNLU PETG" but only for the A1, A1M and X1C, and nothing at all for
PETG 2.0. So this takes the P2S PETG profile for the machine-specific keys that have to be right
(retraction, overhang speed buckets, z-hop, volumetric limit, extruder slot counts) and lays
SUNLU's own material numbers over the top. Every value that differs from Bambu's is listed in
FILAMENT_SET with its reason. Run a temperature tower if you want to do better than the midpoint
of a vendor range.
"""
import json
import os
import sys

PROFILES = "/Applications/BambuStudio.app/Contents/Resources/profiles/BBL"
MACHINE = "Bambu Lab P2S 0.4 nozzle"
PROCESS = "0.20mm Standard @BBL P2S"
FILAMENT = "Bambu PETG Matte @BBL P2S 0.4 nozzle"   # skeleton: P2S-specific PETG keys
FILAMENT_NAME = "SUNLU PETG 2.0 @BBL P2S 0.4 nozzle"

# Process overrides. Only the two that earn their place: each other candidate was A/B sliced and
# dropped when it did not pay (see DESIGN.md).
PROCESS_SET = {
    # ~2.3 mm of bed in front of and behind the bin, and a flat 200 x 246 PETG bottom on textured
    # PEI does not need one.
    "brim_type": "no_brim",
    "curr_bed_type": "Textured PEI Plate",
}

# Tried and rejected, kept here so the next person does not re-litigate them:
#   reduce_crossing_wall = 1   costs 42 min (10h00 -> 10h42) and 0 g. It reroutes travel round
#                              perimeters rather than reducing it -- measured, travel went UP
#                              8.5% and retractions 3%. Turn it on if the first print strings
#                              inside the cells; the filament already uses Spiral Lift z-hop,
#                              which is the cheaper defence.
#   wall_generator = arachne   no measurable effect on a part this thin-walled: sparse infill in
#                              the honeycomb zone 9.07% -> 8.91%, gap infill 0.00% either way,
#                              and 1.2% more extrusion. Left on the system default, classic.
#   seam_position = aligned    already the system default.
MACHINE_SET = {}   # the filament profile already asks for Spiral Lift z-hop

# SUNLU's own numbers, taken from the SUNLU PETG profile Bambu ships, except where noted.
# Density 1.27 is real unfilled PETG; Bambu PETG Matte is 1.37 because it is filled, which is why
# this prints lighter than any figure quoted against that profile.
FILAMENT_SET = {
    "filament_vendor": "SUNLU",
    "filament_density": "1.27",
    "filament_cost": "22.99",
    "filament_flow_ratio": "0.95",
    "filament_max_volumetric_speed": "12",      # SUNLU's limit, below Bambu PETG's 13-15
    "nozzle_temperature": "245",
    "nozzle_temperature_initial_layer": "250",
    "nozzle_temperature_range_low": "230",
    "nozzle_temperature_range_high": "270",
    # SUNLU publishes 70-80 C for the bed; Bambu's SUNLU profile says 60. 70 is the low end of the
    # vendor range and the safer one: PETG on textured PEI can bond hard enough to damage the
    # sheet. A 200 x 246 part with no brim wants the adhesion, so not lower. Drop to 60 if it
    # grips too well when cold.
    "hot_plate_temp": "70",
    "hot_plate_temp_initial_layer": "70",
    "textured_plate_temp": "70",
    "textured_plate_temp_initial_layer": "70",
    "fan_max_speed": "30",                      # PETG: less fan than Bambu's 60/30
    "fan_min_speed": "10",
    "overhang_fan_speed": "90",                 # but full fan on the hex roofs, which all bridge
    "overhang_fan_threshold": "10%",
    "slow_down_layer_time": "12",
}


def load(kind, name, sub=""):
    path = f"{PROFILES}/{kind}/{sub}{name}.json"
    d = json.load(open(path))
    if "inherits" in d:
        base = load(kind, d["inherits"], sub)
        base.update(d)
        d = base
    return d


def flat(kind, name, overrides):
    d = load(kind, name)
    d.pop("inherits", None)
    d["from"] = "system"
    d.update(overrides)
    return d


def filament():
    """P2S PETG skeleton with SUNLU's material numbers laid over it.

    Bambu's per-machine filament profiles use one entry per extruder slot for some keys, so each
    override is replicated to the width of the value it replaces.
    """
    d = load("filament", FILAMENT)
    d.pop("inherits", None)
    d["from"] = "system"
    d["name"] = FILAMENT_NAME
    d["filament_settings_id"] = FILAMENT_NAME
    d["compatible_printers"] = [MACHINE]
    for k, v in FILAMENT_SET.items():
        old = d.get(k)
        d[k] = [v] * len(old) if isinstance(old, list) else v
    return d


def project(seed, out):
    """Take the project settings Bambu Studio's CLI merged, and mark what differs from system."""
    import zipfile
    d = json.loads(zipfile.ZipFile(seed).read("Metadata/project_settings.config"))
    diff = d.get("different_settings_to_system", [""] * 3)
    diff[0] = ";".join(sorted(PROCESS_SET))
    diff[-1] = ";".join(sorted(MACHINE_SET))
    d["different_settings_to_system"] = diff
    json.dump(d, open(out, "w"), indent=1, sort_keys=True)
    print(f"{out}: project settings for {FILAMENT_NAME}")


def main():
    if sys.argv[1] == "--project":
        return project(sys.argv[2], sys.argv[3])
    outdir = sys.argv[1]
    os.makedirs(outdir, exist_ok=True)
    for fname, data in (
        ("machine.json", flat("machine", MACHINE, MACHINE_SET)),
        ("process.json", flat("process", PROCESS, PROCESS_SET)),
        ("filament.json", filament()),
    ):
        json.dump(data, open(f"{outdir}/{fname}", "w"), indent=1, sort_keys=True)
    print(f"{outdir}: machine.json, process.json, filament.json ({FILAMENT_NAME})")


if __name__ == "__main__":
    main()
