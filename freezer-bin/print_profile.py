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
PROCESS = "0.24mm Standard @BBL P2S"
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

# Measured numbers for this exact filament from 3dfilamentprofiles.com (3DFP), which are
# community calibration results rather than a vendor range, so they win over both Bambu's generic
# SUNLU PETG profile and SUNLU's own marketing spread. Anything 3DFP does not cover is noted.
#
# 3DFP also gives the manufacturer datasheet, which is worth having next to the design:
#   tensile   43 MPa X-Y / 20 MPa Z      flexural  70 / 35 MPa
#   modulus  500 MPa X-Y / 300 MPa Z     flexural modulus 1900 / 1650 MPa
#   elongation at break 12% X-Y / 8% Z   Izod notched 4 kJ/m^2
#   Tg 83 C, HDT 71 C at 0.45 MPa, softening 70 C
# Z strength is under half of X-Y, so the honeycomb's load paths matter: see DESIGN.md.
FILAMENT_SET = {
    "filament_vendor": "SUNLU",
    # 1.22 is 3DFP's figure for the colour they tested (Blush Pink). Pigment moves this a little,
    # so a different colour will not weigh exactly the same.
    "filament_density": "1.22",
    "filament_cost": "22.99",
    "filament_flow_ratio": "0.96",
    "filament_max_volumetric_speed": "17.8",    # 3DFP measured; Bambu's generic SUNLU says 12
    # 3DFP range is 240-270, and this now sits near the top of it. The earlier note here said
    # "if the cold test cracks along layer lines, 255-260 is the lever" -- it did exactly that, so
    # the lever is pulled. Hotter means markedly better layer bonding, which is the direction the
    # part actually failed in. The price is stringing, over ~170,000 retractions, so dry the
    # filament and expect to look the first print over.
    "nozzle_temperature": "260",
    "nozzle_temperature_initial_layer": "260",
    "nozzle_temperature_range_low": "240",
    "nozzle_temperature_range_high": "270",
    # 3DFP bed range is 70-80, which confirms 70. Low end on purpose: PETG on textured PEI can
    # bond hard enough to damage the sheet.
    "hot_plate_temp": "70",
    "hot_plate_temp_initial_layer": "70",
    "textured_plate_temp": "70",
    "textured_plate_temp_initial_layer": "70",
    # Dropped well under 3DFP's 40-90%. Part cooling is what kills PETG layer bonding, and a
    # test print failed along a layer bond. Layer times here are 30-96 s, so the part has ample
    # time to cool on its own; the bridges keep their own 100% fan below.
    "fan_min_speed": "10",
    "fan_max_speed": "30",
    "overhang_fan_speed": "100",                # 3DFP bridge fan 100%, and every hex roof bridges
    "overhang_fan_threshold": "10%",
    "close_fan_the_first_x_layers": "3",        # 3DFP: fan off for the first 0-3 layers
    "slow_down_layer_time": "12",
    # Normal Lift instead of the Spiral Lift the Bambu PETG skeleton asks for: worth 9 minutes
    # over ~170,000 travels, and a straight lift clears a honeycomb wall just as well.
    "filament_z_hop_types": "Normal Lift",
}

# 3DFP also says: dry at 65 C for 12 h. Worth doing. Wet PETG strings, and this part travels
# 660 m with ~170,000 retractions, so it is the print most able to show it.


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
