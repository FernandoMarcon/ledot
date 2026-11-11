---
name: mlivre-search
description: Search Mercado Livre (Brazil) for a specific part/component, keep only the listings that exactly match it (judged from "Características do produto", "Descrição" and title), and rank them by cost-benefit (precision > total cost with shipping to the user's CEP > price > delivery time) into a CSV. Use when the user asks to find, price, compare or buy a part on Mercado Livre / Mercado Libre / ML, gives a component name or a parts list (BOM/CSV) to source there, or types /mlivre-search.
argument-hint: <peça> [--qtd N] [--contexto "..."] | <lista.csv>
---

# Mercado Livre part search

Runs the local pipeline in `/data/drive/Projects/mlivre` (docs: `/data/drive/Projects/mlivre/docs/`):
search (Playwright, logged-in profile) → details (page + Mercado Livre MCP: description, shipping to the
user's CEP) → exact-match judgment (`claude -p`) → cost-benefit ranking → `resultado.csv`.

Talk to the user in Portuguese (pt-BR) unless they write in another language.

## 1. Parse the request

From `$ARGUMENTS` / the user's message get, for each part:

- **query**: the part name as specific as possible (e.g. `Servo Horn metálico 25T`). Keep the specs
  (material, teeth, voltage, capacitance, size, model); drop words like "comprar".
- **qtd**: how many pieces are needed (default 1). Matters when listings are kits.
- **contexto**: extra constraints that aren't in the name (what it attaches to, an "Obs" column, a
  substitute/equivalent). Optional but improves the match.

If the input is a parts list (CSV/markdown, e.g. a BOM with columns like Item, Equivalente, Quantidade,
Obs, Status), build one query per row that still needs buying (e.g. `Status` = `Falta`; skip
`Comprado`/`Opcional` unless asked). Prefer the "Equivalente"/local name when it is more specific than
the original, put Obs in `contexto`, Quantidade in `qtd`. Show the planned queries and ask before
running more than 5 (each takes ~2 min and ~US$ 0.25).

## 2. Run

```bash
cd /data/drive/Projects/mlivre && .venv/bin/python -m pipeline.run "<query>" --qtd <N> --contexto "<contexto>" 2>&1 | grep -v '^\[[0-9]*/[0-9]*\]'
```

- Use a Bash timeout of 600000 ms. For several parts, run them one after another (not in parallel:
  they share the browser profile) or in background and report as each finishes.
- Optional flags: `--n 20` (results to analyse), `--todos` (also list rejected ones), `--cep 01234567`
  (otherwise uses `$MLIVRE_CEP` / `~/.config/mlivre/pipeline.json`), `--model sonnet|haiku|opus`.
- The CSV is written to `/data/drive/Projects/mlivre/out/<slug>/resultado.csv`; the intermediate JSONs
  (`s1_search.json`, `s2_items.json`, `s3_matched.json`) sit next to it.

## 3. Report

Read the CSV (or `s3_matched.json` for the rejection reasons) and answer with:

1. A table of the top 5: título (linked to `url`), score, unidades, preço, frete, custo total, prazo
   (`prazo_dias`, 0 = hoje), and the one-line `motivo`.
2. How many listings were analysed vs. kept, and the main reasons for rejections (e.g. "servo completo,
   não o horn", "24T").
3. Caveats worth flagging: international listings, kits whose unit count is a guess, a top pick with
   precision < 0.8 (specs only in the title), shipping quoted for 1 unit when `qtd_anuncios` > 1.
4. The absolute path of the CSV.

Don't present a listing as an exact match if `match_exato` is false.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Bloqueado pela verificação anti-bot` | session expired: ask the user to run `! cd /data/drive/Projects/mlivre && .venv/bin/python -m pipeline.browser`, log in, close the window |
| `informe --cep ...` | ask for the CEP, pass `--cep`, or suggest saving it in `~/.config/mlivre/pipeline.json` as `{"cep": "..."}` |
| MCP errors in `erros` (403 `PolicyAgent`) | Mercado Livre app permissions/scopes: see `docs/setup.md` §3, re-authorize the connector in AnythingMCP |
| MCP 401 / connection refused | `claude mcp list` should show `mercadolivre ✔ Connected`; check the AnythingMCP container and the Cloudflare tunnel |
| Empty fields (specs, price) for every item | Mercado Livre changed its HTML: rerun the step with `--headed`, update the selectors (`docs/api-findings.md`) |
| `.venv` missing | setup in `docs/setup.md` §6 |
