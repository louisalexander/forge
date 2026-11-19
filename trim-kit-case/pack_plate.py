#!/usr/bin/env python3
"""Put several objects on one Bambu Studio plate, each made of one or more parts with a filament.

  python3 pack_plate.py OUT.3mf "Name=part.stl@1,inlays.stl@2" "Other=thing.stl@1" ...

Each argument is one object: its parts share one frame (so inlays stay aligned with their part),
and @N is the filament for that part. Objects are laid out left to right, 10 mm apart, centred on
a 256 mm plate and sitting on the bed.

Options (before OUT.3mf):
  --stack              lay the objects out front to back instead (for long parts)
  --settings FILE      embed FILE as Metadata/project_settings.config (Bambu project settings)
"""
import sys
import zipfile
from pathlib import Path

from pack_2color import bounds, mesh_xml, read_stl

GAP = 10.0
PLATE = 256.0


def main():
    args = sys.argv[1:]
    stack = "--stack" in args
    if stack:
        args.remove("--stack")
    settings_file = None
    if "--settings" in args:
        i = args.index("--settings")
        settings_file = args[i + 1]
        del args[i:i + 2]
    out = Path(args[0])
    objs = []
    for spec in args[1:]:
        name, parts = spec.split("=", 1)
        plist = []
        for p in parts.split(","):
            path, ext = p.rsplit("@", 1)
            plist.append((Path(path).stem, read_stl(path), int(ext)))
        objs.append((name, plist))

    # layout: each object's own bounds come from all its parts
    boxes = [bounds([t for _, tris, _ in plist for t in tris]) for _, plist in objs]
    ax = 2 if stack else 0                        # layout axis: y when stacking, else x
    total = sum(b[ax + 1] - b[ax] for b in boxes) + GAP * (len(objs) - 1)
    pos = (PLATE - total) / 2

    mesh_parts, components, items, settings = [], [], [], []
    mesh_id = 1
    obj_id = 1000
    for (name, plist), (x0, x1, y0, y1, z0, _) in zip(objs, boxes):
        if stack:
            tx, ty = PLATE / 2 - (x0 + x1) / 2, pos - y0
            pos += (y1 - y0) + GAP
        else:
            tx, ty = pos - x0, PLATE / 2 - (y0 + y1) / 2
            pos += (x1 - x0) + GAP
        tz = -z0
        comp_lines, part_cfg = [], []
        for k, (pname, tris, ext) in enumerate(plist, start=1):
            xml, n = mesh_xml(mesh_id, tris)
            mesh_parts.append(xml)
            comp_lines.append(f'    <component p:path="/3D/Objects/object_1.model" objectid="{mesh_id}" '
                              'transform="1 0 0 0 1 0 0 0 1 0 0 0"/>\n')
            part_cfg.append(f'    <part id="{mesh_id}" subtype="normal_part">\n'
                            f'      <metadata key="name" value="{pname}"/>\n'
                            '      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>\n'
                            f'      <metadata key="extruder" value="{ext}"/>\n'
                            f'      <mesh_stat face_count="{n}" edges_fixed="0" degenerate_facets="0" facets_removed="0" '
                            'facets_reversed="0" backwards_edges="0"/>\n    </part>\n')
            mesh_id += 1
        components.append(f'  <object id="{obj_id}" type="model">\n   <components>\n{"".join(comp_lines)}'
                          '   </components>\n  </object>\n')
        items.append(f'  <item objectid="{obj_id}" transform="1 0 0 0 1 0 0 0 1 {tx:.4f} {ty:.4f} {tz:.4f}" printable="1"/>\n')
        settings.append((obj_id, name, plist[0][2], "".join(part_cfg)))
        obj_id += 1

    ns = ('xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" '
          'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
          'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p"')
    objects = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {ns}>\n'
               f' <metadata name="BambuStudio:3mfVersion">1</metadata>\n <resources>\n'
               f'{"".join(mesh_parts)} </resources>\n <build/>\n</model>\n')
    main_model = (f'<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" {ns}>\n'
                  ' <metadata name="Application">BambuStudio-02.00.00.00</metadata>\n'
                  ' <metadata name="BambuStudio:3mfVersion">1</metadata>\n'
                  f' <metadata name="Title">{out.stem}</metadata>\n'
                  f' <resources>\n{"".join(components)} </resources>\n'
                  f' <build>\n{"".join(items)} </build>\n</model>\n')
    cfg = ['<?xml version="1.0" encoding="UTF-8"?>\n<config>\n']
    for oid, name, ext, parts in settings:
        cfg.append(f'  <object id="{oid}">\n    <metadata key="name" value="{name}"/>\n'
                   f'    <metadata key="extruder" value="{ext}"/>\n{parts}  </object>\n')
    cfg.append('  <plate>\n    <metadata key="plater_id" value="1"/>\n    <metadata key="plater_name" value=""/>\n'
               '    <metadata key="locked" value="false"/>\n')
    for i, (oid, *_rest) in enumerate(settings):
        cfg.append(f'    <model_instance>\n      <metadata key="object_id" value="{oid}"/>\n'
                   f'      <metadata key="instance_id" value="0"/>\n      <metadata key="identify_id" value="{i + 1}"/>\n'
                   '    </model_instance>\n')
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
        if settings_file:
            z.writestr("Metadata/project_settings.config", Path(settings_file).read_text())
    print(f"{out}: {len(objs)} objects, {mesh_id - 1} parts, span {total:.1f} mm")


if __name__ == "__main__":
    main()
