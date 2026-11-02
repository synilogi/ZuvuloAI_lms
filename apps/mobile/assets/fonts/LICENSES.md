# Bundled fonts

Both families are licensed under the SIL Open Font License 1.1 (full texts beside this file). They are
bundled so the app never fetches fonts at runtime (modules.md §22.3). Downloaded 22 Sep 2026.

| File | Family / weight | Source | SHA-256 |
| --- | --- | --- | --- |
| `Fraunces72pt-Regular.ttf` | Fraunces 400 | https://github.com/undercasetype/Fraunces — `fonts/ttf/` | `12681469ade31179b299a8cdf23765f16a717a7563e4d3c17d9c21e938cdf2b7` |
| `Fraunces72pt-SemiBold.ttf` | Fraunces 600 | same | `ea45a557b4dd7e9fee6e263211b72986879d6bde518dbe18338d0478b91ab93c` |
| `Fraunces72pt-Bold.ttf` | Fraunces 700 | same | `3490c75c78e860e08243c0dd81184323baf87fef44321a48cd7f8139c29581b5` |
| `PlusJakartaSans-Regular.ttf` | Plus Jakarta Sans 400 | https://github.com/tokotype/PlusJakartaSans — `fonts/ttf/` | `bd6276d4060e3b1ebc45047469e0bb86b08f301ba681cdf1ceb6245ea10478d2` |
| `PlusJakartaSans-Medium.ttf` | Plus Jakarta Sans 500 | same | `c77bab757d7402ec6d9341d5f7ddaafb2474e17026792697ba4624c7dc89caf7` |
| `PlusJakartaSans-SemiBold.ttf` | Plus Jakarta Sans 600 | same | `65dbcedb6596a41c30869729eb31cb57d1f5edfe365684314bba8a1994eaa4cb` |
| `PlusJakartaSans-Bold.ttf` | Plus Jakarta Sans 700 | same | `5f5342ef76862b5b5365d1dff1a667629dfa484e388dd602552f647219c3870f` |

Fraunces uses the static **72pt optical size**: every Fraunces style in the type scale is ≥ 22sp
(display, titles, numerals), and Flutter does not map `FontWeight` onto a variable font's `wght` axis,
so static instances render the intended weights reliably.
