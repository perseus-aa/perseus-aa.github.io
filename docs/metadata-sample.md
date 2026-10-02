# Development sample (metadata-sample.csv)

`_data/metadata-sample.csv` is a small, representative slice of `metadata-full.csv` for developing templates and styles:
37 objects plus their child image rows (685 images, 722 rows), so the site builds in about 15 seconds.
Rows are copied unchanged from `metadata-full.csv`. Select it with `metadata: metadata-sample` in `_config.yml`.

Objects in the full data are sparse: most records fill only 16 to 34 of the ~85 object fields, and which fields depend heavily on the object type.
The sample picks, for each of the six object types, a low, median and high richness record (by number of filled fields), plus edge cases:
no images, about 100 images, very long text, markup-heavy text, garbled characters in the source data, a very long title, and multi-part values.

| id | type | fields filled | child images | why it is here |
|---|---|---|---|---|
| aa_4347 | Vase | 27 | 109 | about 100 images (vase) |
| aa_4361 | Vase | 38 | 70 | vase with inscriptions/graffiti |
| aa_4364 | Vase | 34 | 71 | longest decoration_description |
| aa_4462 | Vase | 28 | 13 | markup-heavy text |
| aa_5092 | Vase | 31 | 31 | Vase: high richness (31 fields) |
| aa_5351 | Vase | 33 | 0 | no images (vase) |
| aa_5392 | Vase | 21 | 2 | Vase: low richness (21 fields) |
| aa_5432 | Vase | 22 | 3 | longest essay_text |
| aa_5503 | Vase | 26 | 2 | Vase: median richness (26 fields) |
| aa_2070 | Sculpture | 46 | 10 | most fields filled overall (sculpture) |
| aa_2084 | Sculpture | 35 | 8 | Sculpture: median richness (35 fields) |
| aa_2142 | Sculpture | 42 | 0 | no images (sculpture) |
| aa_2181 | Sculpture | 39 | 4 | Sculpture: high richness (39 fields) |
| aa_2206 | Sculpture | 42 | 23 | sculpture with placement and inscription |
| aa_2247 | Sculpture | 37 | 6 | garbled characters in source data |
| aa_2901 | Sculpture | 32 | 0 | longest title |
| aa_3593 | Sculpture | 40 | 0 | multi-part collection value |
| aa_3686 | Sculpture | 24 | 16 | Sculpture: low richness (24 fields) |
| aa_1431 | Coin | 30 | 2 | Coin: high richness (30 fields) |
| aa_1622 | Coin | 27 | 2 | Coin: median richness (27 fields) |
| aa_611 | Coin | 24 | 2 | Coin: low richness (24 fields) |
| aa_948 | Coin | 8 | 2 | coin, fewest fields |
| aa_224 | Building | 17 | 2 | Building: low richness (17 fields) |
| aa_242 | Building | 29 | 1 | building with see_also |
| aa_260 | Building | 24 | 0 | no images (building) |
| aa_5 | Building | 22 | 123 | about 100 images (building) |
| aa_88 | Building | 22 | 11 | Building: high richness (22 fields) |
| aa_95 | Building | 19 | 9 | Building: median richness (19 fields) |
| aa_1758 | Gem | 16 | 1 | Gem: low richness (16 fields) |
| aa_1764 | Gem | 19 | 2 | Gem: median richness (19 fields) |
| aa_1780 | Gem | 21 | 2 | Gem: high richness (21 fields) |
| aa_1828 | Gem | 18 | 2 | gem with period |
| aa_3879 | Site | 16 | 4 | Site: low richness (16 fields) |
| aa_3882 | Site | 16 | 77 | many images (site) |
| aa_3911 | Site | 16 | 1 | Site: median richness (16 fields) |
| aa_3944 | Site | 16 | 15 | Site: high richness (16 fields) |
| aa_3950 | Site | 13 | 59 | longest site description |

## Data issues the sample exercises

- 197 objects (179 vases, 17 sculptures, 1 site) have an `images` list, but none of the listed images exist in the images table, so they have no child image rows (for example `aa_2142`).
- Image rows can list several parents in `parentid`, comma separated (for example `aa_1,aa_2,aa_4`); the `compound_object` layout splits on commas.
- About a dozen cells contain garbled characters that come from Airtable itself (for example `aa_2247`).
