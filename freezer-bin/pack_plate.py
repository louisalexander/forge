#!/usr/bin/env python3
"""Pack STLs onto one Bambu Studio plate, placed from the machine profile's own bed geometry.

  python3 pack_plate.py OUT.3mf --machine M.json --settings S.config a.stl [b.stl ...]

Objects are laid out left to right, 10 mm apart, centred on the bed. Placement is then checked
against the machine profile rather than against an assumption: `printable_area` has to contain
everything, and if `bed_exclude_area` is non-empty the group is shifted clear of it.

The P2S declares `bed_exclude_area: []` -- it explicitly clears the 28 x 28 front-left corner and
8 mm left strip that it would otherwise inherit from fdm_bbl_3dp_001_common. Older Bambu machines
keep that L; this one has no exclusion zone at all, so centring is correct here and the shift
below never fires. Pointing the same script at an X1 or P1 profile would move the part.
"""
import json
import struct
import sys
import zipfile
from pathlib import Path

GAP = 10.0


def read_stl(path):
    raw = Path(path).read_bytes()
    if raw[:5] == b"solid" and b"facet normal" in raw[:2000]:
        tris, verts = [], []
        for line in raw.decode("ascii", "replace").splitlines():
            line = line.strip()
            if line.startswith("vertex"):
                p = line.split()
                verts.append((float(p[1]), float(p[2]), float(p[3])))
                if len(verts) == 3:
                    tris.append(tuple(verts))
                    verts = []
        return tris
    n = struct.unpack("<I", raw[80:84])[0]
    data = raw[84:]
    return [tuple(zip(*[iter(struct.unpack("<9f", data[i * 50 + 12:i * 50 + 48]))] * 3))
            for i in range(n)]


def bounds(tris):
    xs = [p[0] for t in tris for p in t]
    ys = [p[1] for t in tris for p in t]
    zs = [p[2] for t in tris for p in t]
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)


def poly(points):
    return [tuple(float(v) for v in p.split("x")) for p in points]


def bed(machine):
    m = json.load(open(machine))
    area = poly(m["printable_area"])
    excl = poly(m.get("bed_exclude_area") or [])
    xs = [p[0] for p in area]
    ys = [p[1] for p in area]
    ex = (max(p[0] for p in excl), max(p[1] for p in excl)) if excl else None
    return min(xs), max(xs), min(ys), max(ys), ex


def mesh_xml(mesh_id, tris):
    index, verts, faces = {}, [], []
    for tri in tris:
        f = []
        for p in tri:
            k = (round(p[0], 5), round(p[1], 5), round(p[2], 5))
            if k not in index:
                index[k] = len(verts)
                verts.append(k)
            f.append(index[k])
        if f[0] != f[1] and f[1] != f[2] and f[0] != f[2]:
            faces.append(f)
    v = "".join(f'     <vertex x="{a:.5f}" y="{b:.5f}" z="{c:.5f}"/>\n' for a, b, c in verts)
    t = "".join(f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>\n' for a, b, c in faces)
    return (f'  <object id="{mesh_id}" type="model">\n   <mesh>\n    <vertices>\n{v}'
            f'    </vertices>\n    <triangles>\n{t}    </triangles>\n   </mesh>\n  </object>\n'), len(faces)


def main():
    args = sys.argv[1:]
    out = Path(args[0])
    opts = {}
    for key in ("--machine", "--settings"):
        if key in args:
            i = args.index(key)
            opts[key] = args[i + 1]
            del args[i:i + 2]
    paths = args[1:]

    bx0, bx1, by0, by1, excl = bed(opts["--machine"])
    tri_sets = [read_stl(p) for p in paths]
    boxes = [bounds(t) for t in tri_sets]
    total = sum(b[1] - b[0] for b in boxes) + GAP * (len(boxes) - 1)
    pos = bx0 + ((bx1 - bx0) - total) / 2
    placed = []
    for path, tris, (x0, x1, y0, y1, z0, _) in zip(paths, tri_sets, boxes):
        placed.append((path, tris, x0, x1, y0, y1, z0, pos - x0, (by0 + by1) / 2 - (y0 + y1) / 2))
        pos += (x1 - x0) + GAP

    gx0 = min(p[2] + p[7] for p in placed)
    gx1 = max(p[3] + p[7] for p in placed)
    gy0 = min(p[4] + p[8] for p in placed)
    gy1 = max(p[5] + p[8] for p in placed)
    dx = 0.0
    if excl and gy0 < excl[1]:                     # only the part of the bed the L reaches
        dx = max(0.0, excl[0] - gx0)
    if gx1 + dx > bx1 or gy0 < by0 or gy1 > by1:
        raise SystemExit(f"does not fit: X {gx0 + dx:.1f}..{gx1 + dx:.1f}, Y {gy0:.1f}..{gy1:.1f} "
                         f"on a bed of X {bx0:.0f}..{bx1:.0f}, Y {by0:.0f}..{by1:.0f}")

    mesh_parts, components, items, obj_cfg, members = [], [], [], [], []
    meshes = {}
    mesh_id, obj_id = 1, 1000
    for path, tris, x0, x1, y0, y1, z0, tx, ty in placed:
        if path not in meshes:
            xml, n = mesh_xml(mesh_id, tris)
            mesh_parts.append(xml)
            meshes[path] = (mesh_id, n)
            mesh_id += 1
        mid, nfaces = meshes[path]
        name = Path(path).stem
        components.append(f'  <object id="{obj_id}" type="model">\n   <components>\n'
                          f'    <component p:path="/3D/Objects/object_1.model" objectid="{mid}" '
                          'transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n   </components>\n  </object>\n')
        items.append(f'  <item objectid="{obj_id}" transform="1 0 0 0 1 0 0 0 1 '
                     f'{tx + dx:.4f} {ty:.4f} {-z0:.4f}" printable="1"/>\n')
        obj_cfg.append(
            f'  <object id="{obj_id}">\n    <metadata key="name" value="{name}"/>\n'
            '    <metadata key="extruder" value="1"/>\n'
            f'    <part id="{mid}" subtype="normal_part">\n'
            f'      <metadata key="name" value="{name}"/>\n'
            '      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n'
            '      <metadata key="extruder" value="1"/>\n'
            f'      <mesh_stat face_count="{nfaces}" edges_fixed="0" degenerate_facets="0" '
            'facets_removed="0" facets_reversed="0" backwards_edges="0"/>\n    </part>\n  </object>\n')
        members.append(obj_id)
        obj_id += 1

    ns = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
          'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
          'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p"')
    objects = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {ns}>\n'
               ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n <resources>\n'
               f'{"".join(mesh_parts)} </resources>\n <build/>\n</model>\n')
    main_model = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {ns}>\n'
                  ' <metadata name="Application">BambuStudio-02.00.00.00</metadata>\n'
                  ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
                  f' <metadata name="Title">{out.stem}</metadata>\n'
                  f' <resources>\n{"".join(components)} </resources>\n'
                  f' <build>\n{"".join(items)} </build>\n</model>\n')
    cfg = ['<?xml version="1.0" encoding="UTF-8"?>\n<config>\n', "".join(obj_cfg),
           '  <plate>\n    <metadata key="plater_id" value="1"/>\n'
           '    <metadata key="plater_name" value=""/>\n'
           '    <metadata key="locked" value="false"/>\n']
    for i, oid in enumerate(members, start=1):
        cfg.append(f'    <model_instance>\n      <metadata key="object_id" value="{oid}"/>\n'
                   '      <metadata key="instance_id" value="0"/>\n'
                   f'      <metadata key="identify_id" value="{i}"/>\n    </model_instance>\n')
    cfg.append('  </plate>\n</config>\n')

    content_types = ('<?xml version="1.0" encoding="UTF-8"?>\n'
                     '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
                     ' <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
                     ' <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>\n'
                     '</Types>\n')
    rels = ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
            ' <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n'
            '</Relationships>\n')
    model_rels = ('<?xml version="1.0" encoding="UTF-8"?>\n'
                  '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
                  ' <Relationship Target="/3D/Objects/object_1.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n'
                  '</Relationships>\n')
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types)
        z.writestr("_rels/.rels", rels)
        z.writestr("3D/3dmodel.model", main_model)
        z.writestr("3D/_rels/3dmodel.model.rels", model_rels)
        z.writestr("3D/Objects/object_1.model", objects)
        z.writestr("Metadata/model_settings.config", "".join(cfg))
        if "--settings" in opts:
            z.writestr("Metadata/project_settings.config", Path(opts["--settings"]).read_text())
    print(f"{out}: {', '.join(Path(p).stem for p in paths)}")
    print(f"   X {gx0 + dx:7.2f} .. {gx1 + dx:7.2f}    Y {gy0:7.2f} .. {gy1:7.2f}"
          f"    clearance {gx0 + dx - bx0:.1f} / {bx1 - gx1 - dx:.1f} in X, "
          f"{gy0 - by0:.1f} / {by1 - gy1:.1f} in Y"
          + (f"   (shifted {dx:.2f} clear of bed_exclude_area)" if dx else ""))


if __name__ == "__main__":
    main()
