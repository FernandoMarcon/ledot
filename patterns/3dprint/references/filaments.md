# Filament presets: Filament / Cooling / Setting Overrides tabs

ElegooSlicer → Filament panel → preset (e.g. `Elegoo PETG @ECC`) → ✎ edit. Three tabs:
**Filament**, **Cooling**, **Setting Overrides**. Recommend only **changes** from the preset,
using the exact UI names below. The plate is always **Textured PEI Plate (Side A)** unless the
user says otherwise, so the bed temperature that matters is the *Textured PEI Plate (Side A)* row.

## Reference preset (verified from the user's UI): `Elegoo PETG @ECC`

### Filament tab
| Section | Setting | Value |
|---|---|---|
| Basic information | Type | PETG |
| | Diameter | 1.75 mm |
| | Softening temperature | 70 °C |
| | Idle temperature | 0 °C |
| | Recommended nozzle temperature | Min 230 · Max 270 °C |
| Flow ratio and Pressure Advance | Enable pressure advance | off (printer firmware handles it) |
| Print chamber temperature | Chamber temperature | Target 0 · Minimal 0 °C (no chamber heater on the CC) |
| Print temperature | Nozzle | First layer 250 · Other layers 250 °C |
| Bed temperature | Cool Plate (SuperTack) | 35 / 35 °C |
| | Cool Plate | 0 / 0 °C (not supported) |
| | Textured Cool Plate | 40 / 40 °C |
| | Engineering Plate | 70 / 70 °C |
| | Smooth PEI Plate (Side B) | 70 / 70 °C |
| | **Textured PEI Plate (Side A)** | **70 / 70 °C** |

### Cooling tab
| Section | Setting | Value |
|---|---|---|
| Cooling for specific layer | No cooling for the first | 3 layers |
| Part cooling fan | Min fan speed threshold | Fan 10 % · Layer time 30 s |
| | Max fan speed threshold | Fan 40 % · Layer time 12 s |
| | Keep fan always on | on |
| | Slow printing down for better layer cooling | on |
| | Don't slow down outer walls | off |
| | Force cooling for overhangs and bridges | on |
| Auxiliary part cooling fan | Fan speed | 0 % |
| Exhaust fan | Activate air filtration | off (During print 70 % · Complete print 70 % when on) |

### Setting Overrides tab
| Setting | Value |
|---|---|
| Retraction → Length | 0.8 mm (override **unchecked** = printer profile value used) |
| Retraction → Z-hop height | 0.4 mm (override **unchecked**) |

## Suggested values for other materials (starting points; the user's Elegoo preset wins)
Only the PETG block above is verified. For other materials, open the matching Elegoo preset and
compare against this table; flag differences rather than assume. Bed = *Textured PEI Plate (Side A)*.

| Material | Nozzle 1st / other | Bed (Side A) | Softening | No cooling first | Fan min → max | Aux fan | Air filtration | Retraction override | Z-hop override |
|---|---|---|---|---|---|---|---|---|---|
| PLA | 215 / 210 | 55 / 55 | 45 | 1 layer | 100 → 100 % | 0–50 % (overhang-heavy) | off | — | — |
| PETG | 250 / 250 (240 if stringing) | 70 / 70 | 70 | 3 | 10 → 40 % | 0 % | off | 0.8–1.2 mm if stringing | 0.4 |
| ABS | 260 / 255 | 100 / 100 | 100 | 3–4 | 0 → 20 % | 0 % | **on** (VOCs) | — | — |
| ASA | 260 / 260 | 100 / 100 | 100 | 3–4 | 0 → 30 % | 0 % | **on** | — | — |
| TPU 95A | 230 / 225 | 40 / 40 | — | 1–2 | 50 → 100 % | 0 % | off | **0.4–0.6 mm** | 0 (avoid z-hop) |
| PLA-CF | 220 / 220 | 55 / 55 | 45 | 1 | 100 → 100 % | 0–30 % | off | — | — |
| PETG-CF / PET-CF | 260 / 260 | 75 / 75 | 75 | 3 | 10 → 40 % | 0 % | off | — | — |
| PA / PA-CF | 285 / 280 | 90 / 90 | 150+ | 4+ | 0 → 20 % | 0 % | on | — | — |
| PC | 280 / 280 | 110 / 110 | 140 | 4+ | 0 → 20 % | 0 % | on | — | — |

## When to change filament settings
- **Stringing (PETG/TPU):** first lower nozzle −5/−10 °C within the recommended min; then check *Retraction → Length* override (+0.2 mm steps, PETG max ~1.5 mm). TPU: keep retraction short.
- **Overhangs/bridges sagging:** raise *Max fan speed threshold* fan % (PETG up to 60 %) or turn on the Auxiliary fan for PLA. Keep it low for ABS/ASA/PA (warping).
- **Small/short layers (layer time < Max threshold):** "Slow printing down…" stays on; for tiny parts print 2+ copies or add a second object rather than raising fan for heat reasons.
- **Layer adhesion weak (functional PETG/ABS):** nozzle +5–10 °C, part fan max −10–20 %.
- **First-layer adhesion on Side A:** textured PEI grips PLA/PETG well at the preset temps. If corners lift, +5 °C bed *first layer* only, keep *other layers* at preset.
- **Idle temperature** 0 is fine (single nozzle). Leave **Chamber temperature** at 0 (no heater); for ABS/ASA/PA just preheat with the door closed.
- **Air filtration:** turn on for ABS/ASA/PA/PC (fumes). Off for PLA/PETG/TPU.

## Resource/energy angle (see rules.md §7)
- Use the **lowest bed and nozzle temperature that still adheres and bonds**; the bed is the biggest energy draw. Don't raise "other layers" bed temp just because the first layer needed it.
- Keep the enclosure **closed** for PETG/ABS/ASA/PA/PC (holds heat, less bed power). Open only for PLA/TPU (heat creep).
- Don't enable the auxiliary or exhaust fan unless a rule above calls for it.
