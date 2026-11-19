#!/usr/bin/env python3
"""Package a case half and its colour inlays so they stay aligned in Bambu Studio.

  NAME_2color.3mf    one object with two parts: the half (filament 1) and its inlays (filament 2)
  NAME_combined.stl  half + inlays in one STL; the inlays are inset 0.02 mm so they share no
                     vertices with the half, and "Split to parts" separates them

Usage: python3 pack_2color.py NAME HALF.stl INLAYS.stl INLAYS_INSET.stl OUTDIR
"""
import struct
import sys
import zipfile
from pathlib import Path


def read_stl(path):
    data = Path(path).read_bytes()
    n = struct.unpack_from("<I", data, 80)[0]
    if 84 + n * 50 != len(data):
        raise SystemExit(f"{path}: not a binary STL")
    tris = []
    for i in range(n):
        o = 84 + i * 50 + 12
        tris.append(struct.unpack_from("<9f", data, o))
    return tris


def write_stl(path, tris):
    with open(path, "wb") as f:
        f.write(b"trim-kit case lid + inlays".ljust(80, b"\0"))
        f.write(struct.pack("<I", len(tris)))
        for t in tris:
            f.write(struct.pack("<3f", 0, 0, 0))
            f.write(struct.pack("<9f", *t))
            f.write(b"\0\0")


def mesh_xml(obj_id, tris):
    index, verts, faces = {}, [], []
    for t in tris:
        ids = []
        for k in range(3):
            v = (round(t[3 * k], 5), round(t[3 * k + 1], 5), round(t[3 * k + 2], 5))
            if v not in index:
                index[v] = len(verts)
                verts.append(v)
            ids.append(index[v])
        if len(set(ids)) == 3:
            faces.append(ids)
    out = [f'  <object id="{obj_id}" type="model">\n   <mesh>\n    <vertices>\n']
    out += [f'     <vertex x="{x:g}" y="{y:g}" z="{z:g}"/>\n' for x, y, z in verts]
    out.append('    </vertices>\n    <triangles>\n')
    out += [f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>\n' for a, b, c in faces]
    out.append('    </triangles>\n   </mesh>\n  </object>\n')
    return "".join(out), len(faces)


def bounds(tris):
    xs = [t[i] for t in tris for i in (0, 3, 6)]
    ys = [t[i] for t in tris for i in (1, 4, 7)]
    zs = [t[i] for t in tris for i in (2, 5, 8)]
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)


def main():
    name, lid_p, inl_p, inl_inset_p, outdir = sys.argv[1:6]
    outdir = Path(outdir)
    lid, inl, inl_inset = read_stl(lid_p), read_stl(inl_p), read_stl(inl_inset_p)

    # Combined STL (inset inlays, so the pieces separate cleanly)
    write_stl(outdir / f"{name}_combined.stl", lid + inl_inset)

    # 3MF: object 3 = component object holding part 1 (lid) and part 2 (inlays)
    x0, x1, y0, y1, z0, _ = bounds(lid)
    tx, ty, tz = 128 - (x0 + x1) / 2, 128 - (y0 + y1) / 2, -z0     # centre on a 256 mm plate, sit on the bed
    lid_xml, lid_n = mesh_xml(1, lid)
    inl_xml, inl_n = mesh_xml(2, inl)
    ns = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
          'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
          'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p"')
    objects = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {ns}>\n'
               f' <metadata name="BambuStudio:3mfVersion">1</metadata>\n <resources>\n'
               f'{lid_xml}{inl_xml} </resources>\n <build/>\n</model>\n')
    main_model = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {ns}>\n'
                  ' <metadata name="Application">BambuStudio-02.00.00.00</metadata>\n'
                  ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
                  f' <metadata name="Title">{name}</metadata>\n'
                  ' <resources>\n  <object id="3" type="model">\n   <components>\n'
                  '    <component p:path="/3D/Objects/object_1.model" objectid="1" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n'
                  '    <component p:path="/3D/Objects/object_1.model" objectid="2" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n'
                  '   </components>\n  </object>\n </resources>\n'
                  f' <build>\n  <item objectid="3" transform="1 0 0 0 1 0 0 0 1 {tx:.4f} {ty:.4f} {tz:.4f}" printable="1"/>\n </build>\n</model>\n')
    settings = ('<?xml version="1.0" encoding="UTF-8"?>\n<config>\n  <object id="3">\n'
                f'    <metadata key="name" value="{name}"/>\n'
                '    <metadata key="extruder" value="1"/>\n'
                '    <part id="1" subtype="normal_part">\n'
                f'      <metadata key="name" value="{name}"/>\n'
                '      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n'
                '      <metadata key="extruder" value="1"/>\n'
                f'      <mesh_stat face_count="{lid_n}" edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>\n'
                '    </part>\n'
                '    <part id="2" subtype="normal_part">\n'
                f'      <metadata key="name" value="{name} inlays"/>\n'
                '      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n'
                '      <metadata key="extruder" value="2"/>\n'
                f'      <mesh_stat face_count="{inl_n}" edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>\n'
                '    </part>\n  </object>\n'
                '  <plate>\n    <metadata key="plater_id" value="1"/>\n    <metadata key="plater_name" value=""/>\n'
                '    <metadata key="locked" value="false"/>\n'
                '    <model_instance>\n      <metadata key="object_id" value="3"/>\n'
                '      <metadata key="instance_id" value="0"/>\n      <metadata key="identify_id" value="1"/>\n'
                '    </model_instance>\n  </plate>\n</config>\n')
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
    with zipfile.ZipFile(outdir / f"{name}_2color.3mf", "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", content_types)
        z.writestr("_rels/.rels", rels)
        z.writestr("3D/3dmodel.model", main_model)
        z.writestr("3D/_rels/3dmodel.model.rels", model_rels)
        z.writestr("3D/Objects/object_1.model", objects)
        z.writestr("Metadata/model_settings.config", settings)
    print(f"{name}: {lid_n} faces, inlays {inl_n} faces")


if __name__ == "__main__":
    main()
