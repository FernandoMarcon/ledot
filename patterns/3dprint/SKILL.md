---
name: 3dprint
description: Recommend ElegooSlicer/OrcaSlicer process and filament settings (Textured PEI Side A plate, minimal filament/energy) for printing a 3D model on the user's Elegoo Centauri Carbon. Use when the user gives a model file (.stl, .3mf, .obj) and/or a filament material (PLA, PETG, ABS, ASA, TPU, CF/nylon…) and asks what settings to use, how to print it, or whether it needs supports, brim, infill changes, etc.
argument-hint: <model file> <material> [purpose / priority]
---

# 3D print settings advisor: Elegoo Centauri Carbon

Turn a **model file + material** into a short list of slicer changes, measured against the
user's baseline profile `0.20mm Standard @Elegoo CC 0.4 nozzle` (ElegooSlicer, an OrcaSlicer fork) and the
matching Elegoo filament preset (e.g. `Elegoo PETG @ECC`).

**Defaults that always apply:**
- **Plate: Textured PEI Plate (Side A).** Use its bed-temperature row. Mention another plate only if the user names one.
- **Minimize filament, energy and time.** Among settings that meet the part's purpose, pick the leanest (rules.md §7).

## Reference files (read as needed)
- `references/printer.md`: printer specs (256³ mm, 0.4 hardened nozzle, bed 110 °C, enclosed, no chamber heater)
- `references/defaults.md`: every baseline value in the Process tabs (Quality, Strength, Support, Multimaterial, Others)
- `references/materials.md`: temperatures, cooling, enclosure, drying, and per-material process implications
- `references/filaments.md`: filament preset tabs (Filament / Cooling / Setting Overrides), verified PETG preset, per-material values
- `references/rules.md`: decision rules mapping geometry, material, and purpose to setting changes

Paths are relative to this skill's directory (`~/.claude/skills/3dprint/`).

## Workflow

1. **Parse the input.** Get the model path and material. If the material is missing, ask (one line). If the path is
   a folder or zip, list the printable files inside and analyze each (or ask which ones).
   The *purpose* (decorative / general / functional / flexible / watertight) and *priority*
   (speed / looks / strength) are optional. Infer them from the file name, folder, and shape. Ask only if
   the answer would change walls/infill/layer height a lot and you can't infer it.

2. **Measure the model.** Run:
   ```bash
   python3 ~/.claude/skills/3dprint/scripts/mesh_report.py "<model>" --material <MAT>
   ```
   Stdlib only. Takes about 30 s on meshes over 1M triangles, so run it with a 5-minute timeout. It reports size and fit,
   volume and mass, bed contact, height/base ratio, overhang area and height by angle, shells,
   and the number of plated objects. A `.3mf` saved by Orca/Bambu/Elegoo slicer may also hold the
   designer's settings as JSON in `Metadata/project_settings.config`:
   ```bash
   unzip -p "<model>.3mf" Metadata/project_settings.config | python3 -c "import json,sys; d=json.load(sys.stdin); [print(k, d.get(k)) for k in ['print_settings_id','filament_settings_id','layer_height','wall_loops','sparse_infill_density','sparse_infill_pattern','enable_support','support_type','brim_type','seam_position']]"
   ```
   If it's present, list where the designer's values differ from the baseline. The designer may have
   used another printer (e.g. `@BBL X1C`), so translate the values; don't copy the printer profile.
   If the script fails (an odd format such as STEP), say so and work from the file name and the user's description.

3. **Apply the rules.** Read `references/rules.md`, `references/materials.md`, and `references/filaments.md`. Go tab by tab
   in rules order: fit/orientation → Quality → Strength → Support → Multimaterial → Others → filament preset
   (Filament / Cooling / Setting Overrides) → resource check (§7).
   Change something only when a rule fires. Every change needs a reason tied to a measured fact, the material,
   or a resource saving.

4. **Answer in this format** (keep it scannable; no long prose):

   ```
   ## <model name> — <MATERIAL> on Centauri Carbon
   **Model:** 74.7×74.7×20 mm · ~19 g (est.) · 1 part · overhangs: none · contact: 96 %
   **Plate:** Textured PEI Plate (Side A)
   **Filament preset:** Elegoo PLA — nozzle 215 °C, bed 55 °C (Side A), fan 100 %, lid open
   **Orientation:** as-is ✓  (or: rotate / lay on face — why)

   | Tab | Setting | Default → New | Why |
   |---|---|---|---|
   | Quality | Layer height | 0.2 → 0.16 | curved top, visual part |
   | Support | Enable support | off → on (Tree auto, build plate only) | 640 mm² overhang <30° up to z=42 mm |
   | ... | | | |

   **Filament settings** (only if changed from the preset):
   | Tab | Setting | Preset → New | Why |
   |---|---|---|---|
   | Cooling | Max fan speed threshold → Fan speed | 40 → 60 % | bridges 12 mm |
   | Setting Overrides | Retraction → Length | ☐ 0.8 → ☑ 1.0 mm | stringing-prone PETG |

   Everything else: keep the default.
   **Savings:** ~14 g est. · Tree supports on plate only, 10 % Lightning, no brim, 0.24 layers
   **Watch out:** <1–3 material/model-specific risks: warping corners, stringing, drying, ventilation>
   ```
   - Only list changed settings. If nothing changes, say "Default profile is fine" plus the plate and filament preset lines.
   - Omit the Filament settings table when the preset is fine as-is; say "Filament preset: as-is".
   - Always include the **Savings** line (what was chosen to cut filament/energy/time, est. grams).
   - For multiple files, give one shared table if the settings match, or one block per file if not.
   - Use the exact setting names from `defaults.md` so the user can find them in the UI.
   - Mention when a setting lives outside the five tabs (filament temps, ironing, wall order) but matters.

## Ground rules
- The baseline profile is already tuned for the CC. Recommend the fewest changes that matter.
- Default plate is **Textured PEI Plate (Side A)**: no glue stick for PLA/PETG; quote the Side A bed temp.
- Resource-lean by default: no supports/brim/skirt unless needed, lowest working temps, low infill, thicker
  layers when looks don't matter, batch parts on one plate. Never undercut a stated strength or looks requirement.
- Trust designer intent stated in the file or folder name ("no supports", "print in place", "0.12 mm").
- Single-filament prints: the Multimaterial tab doesn't matter, so don't list it.
- Never exceed the hardware: nozzle 320 °C, bed 110 °C, 256 mm per axis. Warn when the material is not
  on the printer's official list (PLA, PETG, ABS, ASA, TPU, PA/PET-CF & GF).
- Estimates (mass, time) are marked "est." and the slicer's own preview has the final say.
