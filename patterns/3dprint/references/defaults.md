# Baseline process profile — `0.20mm Standard @Elegoo CC 0.4 nozzle`

ElegooSlicer (OrcaSlicer fork) → Process panel → **Global**. These are the values the
user starts from. Recommend only **changes** from this table.

## Quality
| Setting | Default | Notes |
|---|---|---|
| Layer height | 0.2 mm | Usable range with a 0.4 nozzle: 0.08–0.28 mm |
| First layer height | 0.2 mm | 0.2–0.28; thicker helps adhesion on big or uneven plates |
| Seam position | Aligned | Options: Nearest, Aligned, Back, Random |
| Precise wall | off | Turn on for better outer dimension accuracy |
| Only one wall on first layer | off | |
| Only one wall on top surfaces | **on** | Better top finish; turn off for thin, strong tops |

## Strength
| Setting | Default | Notes |
|---|---|---|
| Wall loops | 2 | 0.4 nozzle → each wall ≈ 0.45 mm |
| Top shell layers | 5 | Effective top = max(layers × layer height, top thickness) |
| Top shell thickness | 1 mm | |
| Top surface density | 100 % | |
| Top surface pattern | Monotonic line | |
| Bottom shell layers | 3 | |
| Bottom shell thickness | 0.6 mm | |
| Bottom surface density | 100 % | |
| Bottom surface pattern | Monotonic | |
| Sparse infill density | 15 % | |
| Fill Multiline | 1 | Lines per infill path; leave 1 unless chasing stiffness at low density |
| Sparse infill pattern | Rectilinear | Common choices: Grid, Gyroid, Cubic, Adaptive Cubic, Lightning, Honeycomb, Crosshatch |
| Internal solid infill pattern | Monotonic | |

## Support
| Setting | Default | Notes |
|---|---|---|
| Enable support | off | |
| Type | Normal (auto) | Options: Normal (auto), Tree (auto), Normal (manual), Tree (manual) |
| Threshold angle | 30° | Faces flatter than this (measured from horizontal) get support |
| Threshold overlap | 50 % | |
| On build plate only | off | |
| Support/raft base filament | Default | |
| Support/raft interface filament | Default | |

## Multimaterial
| Setting | Default | Notes |
|---|---|---|
| Prime tower → Enable | **on** | Only built when 2+ filaments are used on the plate |
| Width | 35 mm | |
| Prime volume | 45 mm³ | |
| Flush into objects' infill | off | |
| Flush into objects' support | on | |

## Others
| Setting | Default | Notes |
|---|---|---|
| Skirt loops | 0 | |
| Skirt height | 1 layer | |
| Brim type | Auto | Options: Auto, Mouse ear, Outer only, Inner only, Outer and inner, No brim |
| Brim width | 5 mm | |
| Print sequence | By layer | By object = print each object fully, one after the other |
| Spiral vase | off | |
| Fuzzy skin | Disabled | Options: Disabled, Outside walls, All walls, … |
