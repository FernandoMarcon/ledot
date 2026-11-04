#!/usr/bin/env python3
"""mesh_report.py — geometry facts for slicer decisions (stdlib only).

Usage: mesh_report.py MODEL [--material PLA] [--threshold 30]
Supports .stl (ascii/binary), .obj, .3mf (incl. slicer projects with
components and transforms). Prints JSON to stdout.

Assumes the model is printed in the orientation stored in the file
(Z up, lowest point on the bed). Units: mm.
"""
import argparse
import json
import math
import re
import struct
import sys
import zipfile
import xml.etree.ElementTree as ET

BED = (256.0, 256.0, 256.0)  # Elegoo Centauri Carbon build volume, mm
DENSITY = {  # g/cm3
    "PLA": 1.24, "PETG": 1.27, "ABS": 1.04, "ASA": 1.07, "TPU": 1.21,
    "PA": 1.14, "PA-CF": 1.20, "PET-CF": 1.30, "PLA-CF": 1.29, "PETG-CF": 1.30,
    "PA-GF": 1.35, "PC": 1.20,
}


# ---------------------------------------------------------------- loaders
def load_stl(path):
    with open(path, "rb") as f:
        data = f.read()
    if len(data) >= 84:
        n = struct.unpack_from("<I", data, 80)[0]
        if 84 + n * 50 == len(data):
            tris = []
            for i in range(n):
                v = struct.unpack_from("<12f", data, 84 + i * 50)
                tris.append((v[3:6], v[6:9], v[9:12]))
            return [tris]
    text = data.decode("latin-1")
    verts = [tuple(map(float, m)) for m in
             re.findall(r"vertex\s+(\S+)\s+(\S+)\s+(\S+)", text)]
    return [[tuple(verts[i:i + 3]) for i in range(0, len(verts) - 2, 3)]]


def load_obj(path):
    verts, tris = [], []
    with open(path, encoding="latin-1") as f:
        for line in f:
            p = line.split()
            if not p:
                continue
            if p[0] == "v":
                verts.append(tuple(map(float, p[1:4])))
            elif p[0] == "f":
                idx = [int(x.split("/")[0]) for x in p[1:]]
                idx = [i - 1 if i > 0 else len(verts) + i for i in idx]
                for k in range(1, len(idx) - 1):
                    tris.append((verts[idx[0]], verts[idx[k]], verts[idx[k + 1]]))
    return [tris]


IDENT = (1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)


def parse_tf(s):
    if not s:
        return IDENT
    v = tuple(map(float, s.split()))
    return v if len(v) == 12 else IDENT


def tf_mul(a, b):
    """Compose 3MF transforms: apply a, then b (row-vector convention)."""
    A = [a[0:3], a[3:6], a[6:9]]
    B = [b[0:3], b[3:6], b[6:9]]
    m = [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    t = [sum(a[9 + k] * B[k][j] for k in range(3)) + b[9 + j] for j in range(3)]
    return tuple(m[0] + m[1] + m[2] + t)


def tf_apply(t, p):
    x, y, z = p
    return (x * t[0] + y * t[3] + z * t[6] + t[9],
            x * t[1] + y * t[4] + z * t[7] + t[10],
            x * t[2] + y * t[5] + z * t[8] + t[11])


def load_3mf(path):
    UNIT = {"micron": 0.001, "millimeter": 1, "centimeter": 10,
            "inch": 25.4, "foot": 304.8, "meter": 1000}
    z = zipfile.ZipFile(path)
    objects = {}  # (file, id) -> {"tris": [...], "comps": [(file, id, tf)]}
    root_file, scale = None, 1.0
    for name in z.namelist():
        if not name.lower().endswith(".model"):
            continue
        root = ET.fromstring(z.read(name))
        ns = root.tag.split("}")[0] + "}" if root.tag.startswith("{") else ""
        fname = "/" + name.lstrip("/")
        if name.lower().startswith("3d/3dmodel") or root_file is None and root.find(f"{ns}build") is not None:
            root_file = fname
            scale = UNIT.get(root.get("unit", "millimeter"), 1)
        for obj in root.iter(f"{ns}object"):
            entry = {"tris": [], "comps": []}
            mesh = obj.find(f"{ns}mesh")
            if mesh is not None:
                vs = [(float(v.get("x")), float(v.get("y")), float(v.get("z")))
                      for v in mesh.iter(f"{ns}vertex")]
                for t in mesh.iter(f"{ns}triangle"):
                    entry["tris"].append((vs[int(t.get("v1"))], vs[int(t.get("v2"))], vs[int(t.get("v3"))]))
            for c in obj.iter(f"{ns}component"):
                cpath = next((v for k, v in c.attrib.items() if k.endswith("path")), fname)
                entry["comps"].append((cpath, c.get("objectid"), parse_tf(c.get("transform"))))
            objects[(fname, obj.get("id"))] = entry
        if fname == root_file:
            build = [(fname, it.get("objectid"), parse_tf(it.get("transform")))
                     for it in root.iter(f"{ns}item")]
    if root_file is None:
        raise ValueError("no 3D model part found in 3mf")

    def flatten(key, tf, depth=0):
        e = objects.get(key)
        if e is None or depth > 16:
            return []
        out = [tuple(tuple(c * scale for c in tf_apply(tf, p)) for p in tri) for tri in e["tris"]]
        for cfile, cid, ctf in e["comps"]:
            out += flatten((cfile, cid), tf_mul(ctf, tf), depth + 1)
        return out

    return [flatten((f, i), t) for f, i, t in build]


def load(path):
    ext = path.lower().rsplit(".", 1)[-1]
    if ext == "stl":
        return load_stl(path)
    if ext == "obj":
        return load_obj(path)
    if ext == "3mf":
        return load_3mf(path)
    raise ValueError(f"unsupported format: .{ext} (use stl, obj or 3mf)")


# ---------------------------------------------------------------- analysis
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def components(tris):
    """Count disconnected shells (union-find on rounded vertex positions)."""
    parent = {}

    def find(x):
        while parent.setdefault(x, x) != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for tri in tris:
        keys = [tuple(round(c, 4) for c in p) for p in tri]
        r0 = find(keys[0])
        for k in keys[1:]:
            rk = find(k)
            if rk != r0:
                parent[rk] = r0
    return len({find(k) for k in list(parent)})


def analyze(bodies, threshold):
    tris = [t for b in bodies for t in b]
    if not tris:
        raise ValueError("model has no triangles")
    xs = [p[0] for t in tris for p in t]
    ys = [p[1] for t in tris for p in t]
    zs = [p[2] for t in tris for p in t]
    lo = (min(xs), min(ys), min(zs))
    hi = (max(xs), max(ys), max(zs))
    size = tuple(round(h - l, 2) for h, l in zip(hi, lo))
    zmin = lo[2]
    tol = max(0.05, size[2] * 1e-4)

    vol = area = bed_area = 0.0
    over = {a: 0.0 for a in sorted({15, 30, 45, threshold})}
    over_zmax = {a: zmin for a in over}
    bridge_like = 0.0
    for a, b, c in tris:
        n = cross(sub(b, a), sub(c, a))
        nl = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)
        if nl == 0:
            continue
        fa = nl / 2
        area += fa
        vol += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
                + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
        nz = n[2] / nl
        if nz >= 0:
            continue
        on_bed = max(a[2], b[2], c[2]) - zmin < tol
        if on_bed:
            bed_area += fa
            continue
        tilt = math.degrees(math.acos(min(1.0, -nz)))  # 0 = flat ceiling, 90 = vertical wall
        for ang in over:
            if tilt < ang:
                over[ang] += fa
                over_zmax[ang] = max(over_zmax[ang], max(a[2], b[2], c[2]))
        if tilt < 5:
            bridge_like += fa

    vol = abs(vol)
    fp = size[0] * size[1]
    fits = sorted(size[:2]) <= sorted(BED[:2]) and size[2] <= BED[2]
    return {
        "size_mm": {"x": size[0], "y": size[1], "z": size[2]},
        "fits_bed_256": fits,
        "triangles": len(tris),
        "objects_on_plate": len(bodies),
        "shells": sum(components(b) for b in bodies) if len(tris) <= 300_000 else None,
        "volume_cm3": round(vol / 1000, 2),
        "surface_area_cm2": round(area / 100, 1),
        "bed_contact_area_mm2": round(bed_area, 1),
        "bed_contact_pct_of_bbox_footprint": round(100 * bed_area / fp, 1) if fp else 0,
        "height_to_base_ratio": round(size[2] / max(1e-6, min(size[0], size[1])), 2),
        "overhang_area_mm2_by_angle": {f"<{a}deg": round(v, 1) for a, v in over.items()},
        "overhang_pct_of_surface": {f"<{a}deg": round(100 * v / area, 2) for a, v in over.items()},
        "highest_overhang_z_mm": {f"<{a}deg": round(over_zmax[a] - zmin, 1) for a in over},
        "flat_ceiling_area_mm2": round(bridge_like, 1),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("model")
    ap.add_argument("--material", default=None)
    ap.add_argument("--threshold", type=float, default=30, help="support threshold angle (deg)")
    args = ap.parse_args()
    try:
        r = analyze(load(args.model), args.threshold)
    except Exception as e:  # noqa: BLE001
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
    r["file"] = args.model
    vol = r["volume_cm3"]
    r["solid_mass_g"] = {m: round(vol * d, 1) for m, d in DENSITY.items()} if not args.material else \
        {args.material.upper(): round(vol * DENSITY.get(args.material.upper(), 1.25), 1)}
    r["note"] = ("solid_mass is 100% infill upper bound; real mass with 2 walls/15% infill "
                 "is typically 30-50% of it. Overhang area excludes faces touching the bed. "
                 "Angles are measured from horizontal, same as the slicer threshold.")
    print(json.dumps(r, indent=2))


if __name__ == "__main__":
    main()
