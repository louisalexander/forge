"""STL helpers for the OpenSCAD checks: render a part, read its vertices, volume and bounds."""
import struct
import subprocess

def render(part, tmp_path, scad, **params):
    """Export one part to STL. None when the part is empty (the interference checks)."""
    out = tmp_path / f"{part}.stl"
    cmd = ["openscad", "--backend=manifold", "--export-format=asciistl", "-o", str(out),
           "-D", f'part="{part}"']
    for k, v in params.items():
        cmd += ["-D", f"{k}={v}"]
    res = subprocess.run(cmd + [str(scad)], capture_output=True, text=True, timeout=600)
    log = res.stdout + res.stderr
    assert "ERROR" not in log and "assert" not in log.lower(), log   # e.g. an unknown part name
    assert "Ignoring unknown" not in log, log                        # a missing module/variable
    if "top level object is empty" in log or not out.exists() or out.stat().st_size == 0:
        return None
    assert res.returncode == 0, log
    return out if _vertices(out) else None


def _vertices(stl):
    data = stl.read_bytes()
    if data[:5] == b"solid" and b"facet" in data[:1000]:
        return [tuple(float(t) for t in line.split()[1:4])
                for line in data.decode().splitlines() if line.strip().startswith("vertex")]
    n = struct.unpack("<I", data[80:84])[0]
    pts = []
    for i in range(n):
        off = 84 + i * 50 + 12
        for j in range(3):
            pts.append(struct.unpack("<3f", data[off + 12 * j: off + 12 * j + 12]))
    return pts


def _volume(stl):
    pts = _vertices(stl)
    v = 0.0
    for i in range(0, len(pts) - 2, 3):
        (ax, ay, az), (bx, by, bz), (cx, cy, cz) = pts[i], pts[i + 1], pts[i + 2]
        v += (ax * (by * cz - bz * cy) - ay * (bx * cz - bz * cx) + az * (bx * cy - by * cx)) / 6
    return abs(v)


def no_interference(part, tmp_path, scad, **params):
    """Empty, or only faces that touch (zero volume) — never material inside material."""
    out = render(part, tmp_path, scad=scad, **params)
    return out is None or _volume(out) < 0.01


def bbox(stl):
    pts = _vertices(stl)
    lo = tuple(min(p[i] for p in pts) for i in range(3))
    hi = tuple(max(p[i] for p in pts) for i in range(3))
    return lo, hi
