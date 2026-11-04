# Materials on the Elegoo Centauri Carbon

Starting points for a 0.4 mm hardened-steel nozzle on PEI. Pick the matching
**Elegoo/Generic filament preset** in the slicer first. Its temperatures and cooling
take priority. Change these only when the spool label or a failed print says otherwise.
The printer has an enclosure but **no active chamber heater**. The chamber warms
passively from the bed, so let it preheat for hot materials.

| Material | Nozzle °C | Bed °C | Part fan | Enclosure | Dry before use | Notes |
|---|---|---|---|---|---|---|
| PLA | 205–220 | 55–60 | 100 % | **Lid/door open** or chamber fan on | Rarely | Heat creep and soft corners if the chamber gets warm |
| PLA+ / Silk PLA | 210–230 | 55–60 | 100 % | Open | Rarely | Silk: slower outer wall, more temperature, weaker layer bonding |
| PETG | 235–250 | 70–80 | 30–60 % | Closed OK | Yes, 65 °C 4–6 h | Bonds too hard to smooth PEI, so use glue stick as a release layer. Strings: raise retraction and lower temperature |
| ABS | 250–260 | 95–105 | 0–20 % | **Closed, preheat 10 min** | Yes, 80 °C 4 h | Warps. Use a brim on large parts. Ventilate the room (VOC/styrene) |
| ASA | 255–265 | 95–105 | 0–30 % | **Closed, preheat** | Yes | Like ABS, UV stable. Ventilate the room |
| TPU (95A) | 220–235 | 35–50 | 50–100 % | Open | Yes, 50 °C | Slow: 25–40 mm/s max volumetric about 3–4 mm³/s. Low retraction. Gyroid infill |
| PLA-CF | 210–230 | 55–60 | 100 % | Open | Yes | Matte finish, abrasive (fine with the hardened nozzle) |
| PETG-CF / PET-CF | 250–280 | 70–90 | 20–40 % | Closed | **Yes** | Abrasive. Stiff, lower layer bonding than plain PETG |
| PA / PA-CF / PA-GF | 270–300 | 80–100 | 0–30 % | **Closed, preheat** | **Mandatory**, 80 °C 8 h+, print from a dry box | Very hygroscopic. Wet nylon pops, strings, and comes out weak. Glue stick on PEI |
| PC | 270–300 | 100–110 | 0–20 % | Closed, preheat | Yes | At the printer's bed limit (110 °C). Brim needed. Warps a lot |

## Material → process-setting implications
- **ABS / ASA / PA / PC (warping materials):** Brim = Outer only, 5–8 mm on parts with footprint > 100 mm or sharp corners. Avoid large flat solid areas. Keep part fan low. Prefer **Tree** support (less contact area to tear off).
- **PETG:** Support interface sticks hard. Raise the support top Z distance (0.2 → 0.25–0.3 mm) or use Tree supports.
- **TPU:** Supports are hard to remove, so orient to avoid them. Use 0 % or 10–15 % gyroid infill for soft parts and 3+ walls. Skirt loops 1–2 to prime flow. Print one object at a time if multiple.
- **CF / GF composites:** Prefer 0.2–0.28 layer height. Fibers hide layer lines. More walls (3–4) beat more infill for stiffness.
- **PLA:** Most forgiving. Default profile works for most models.
