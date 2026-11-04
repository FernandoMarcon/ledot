# Decision rules: model facts → setting changes

Inputs: `mesh_report.py` JSON, the material, the part's purpose (inferred from the name
or file, or asked), and the user's priority (speed / looks / strength).
Change a setting only when a rule fires. Otherwise keep the default (see defaults.md).

## 0. Fit and orientation (check first)
- `fits_bed_256` false → stop. Suggest scaling, splitting, or rotating. Usable plate is about 256 × 256 mm. Leave about 5 mm margin for brim and purge.
- `bed_contact_pct_of_bbox_footprint` < 20 % with a large overhang area → the model is probably in a bad orientation. Suggest laying the largest flat face on the bed (slicer: *Lay on face*, `F`) before adding supports.
- Model looks like a slicer project (`.3mf` with many `objects_on_plate`) → the designer probably already plated it, so respect their orientation. Mention any print-profile name in the file name ("no supports", "0.12mm") as designer intent.

## 1. Quality tab
| Condition | Change |
|---|---|
| Miniatures, figurines, fine text, Z < 40 mm and detailed | Layer 0.12 (or 0.16). First layer stays 0.2 |
| Visual part, curved tops or shallow slopes | Layer 0.16 |
| Functional/large/draft, Z > 150 mm, mass > 200 g, or the user wants speed | Layer 0.24–0.28 |
| Plate area > 150 × 150 or warping material | First layer 0.25 |
| Cylindrical/organic visual part | Seam **Back** (hide it), or **Random** if there's no hidden side |
| Box or mechanical part with corners | Keep **Aligned** (the seam hides in corners) |
| Dimensional fit needed (press fit, mating parts, tolerances) | **Precise wall on** |
| Thin top that needs strength or watertightness | Only one wall on top surfaces **off** |

## 2. Strength tab
| Purpose | Walls | Top / bottom layers | Infill |
|---|---|---|---|
| Decorative, figurine, vase-like | 2 | default | 10–15 % Gyroid (Lightning only if speed matters and there are no large flat tops) |
| General use, organizer, enclosure | 2–3 | default | 15 %, Grid/Gyroid |
| Functional / load bearing, brackets, hooks, clips | **4** | 6 / 4 | 30–40 %, **Gyroid** or **Cubic** |
| Maximum strength (tools, mounts under stress) | 5–6 | 7 / 5 | 50 %+, Cubic. More walls beat more infill |
| Flexible (TPU) | 3 | 4 / 3 | 0–15 % Gyroid |
| Watertight (cups, planters) | 3+ | 6 / 5 | — (consider spiral vase) |
| Small parts (any XY < 15 mm) | 3 (the part is mostly walls anyway) | default | default |
| Screw holes or threads present | 3–4 walls (gives material to bite) | | |
Keep the patterns (Monotonic line / Monotonic) unless there's a reason to change them.

## 3. Support tab
Use `overhang_area_mm2_by_angle["<30deg"]` and `highest_overhang_z_mm`. Ignore overhangs whose
z is < 1 mm (chamfers and elephant-foot reliefs near the bed).
| Condition | Change |
|---|---|
| Overhang <30° area < ~50 mm², or only small bridges (`flat_ceiling_area` with short spans) | **No support.** The CC bridges about 10–15 mm cleanly with PLA |
| Overhang area is significant, flat geometric undersides (mechanical) | Enable, **Normal (auto)** |
| Organic/figurine/curved overhangs, or the model is hard to clean | Enable, **Tree (auto)** |
| All overhangs reachable from the plate (nothing hangs over the model itself) | **On build plate only** on |
| File/designer says "no supports" / "supportless" | Keep disabled; say why |
| PETG/ABS supports | Prefer Tree. Raise the top Z distance slightly |
| Support filament | Default (single filament). With CANVAS multi-material: use PLA support interface for PETG parts and vice versa |
Threshold: keep 30°. Lower it to 20–25° for PLA with good cooling to save support. Raise it to 40–45° for TPU, PETG, or high-quality undersides.

## 4. Multimaterial tab
- Single filament → no effect (the prime tower is only generated with 2+ filaments). Say "no change".
- Multi-color → keep the tower. Turn on **Flush into objects' infill** to cut waste on parts with infill ≥ 15 %. Turn on **Flush into objects' support** (already on).

## 5. Others tab
| Condition | Change |
|---|---|
| `height_to_base_ratio` > 3, or tall thin parts | Brim **Outer only** 5–8 mm |
| Warping material (ABS/ASA/PA/PC) and footprint > 80 mm or sharp corners | Brim **Outer only** 5–8 mm (or Mouse ear at corners) |
| Small bed contact (< 200 mm²) | Brim Outer only 3–5 mm |
| Plenty of contact, PLA/PETG | Keep **Auto** (usually ends up with no brim) |
| TPU or a new spool | Skirt loops 1–2 (primes flow) |
| Several objects, each short, and the user wants each finished independently | Print sequence **By object**. Warn about gantry/hotend clearance height (check the slicer's printable height for sequential; keep objects short and spaced) |
| Vase/cup/lampshade, single closed outer wall wanted | **Spiral vase on**. Forces 1 wall, 0 infill, no top. Bottom layers 3–5. Model must be one shell with no internal features |
| Grip surfaces, handles, "rough texture" look | Fuzzy skin **Outside walls** |

## 6. Speed and time estimate (optional)
Rough guess: `printed mass ≈ 0.3–0.5 × solid_mass_g` at 2 walls / 15 %. On the CC
standard profile, figure about 15–25 g/h for PLA. Treat it as a ballpark only; the slicer's
estimate is the real number.
