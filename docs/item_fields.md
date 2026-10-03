# Item page fields by object type

Which metadata fields an item page shows, and in what order, is set in
`_data/item-fields.yml`, one entry per `objtype` (Vase, Sculpture, Coin, Building, Gem, Site)
plus a `default` for any other type. `_includes/item/metadata.html` reads the entry for the page's
type; `_layouts/item/item-page-base.html` includes it twice:

- `part="facts"`: the short labeled fields, in a card beside the images.
- `part="descriptions"`: the prose sections and the citations, full width below the images.

## Editing a type

- `facts` entries are `{key, label, mod}`. `key` is the metadata column, `label` the text shown,
  and `mod` an optional column whose value is shown before the value (e.g. `painter_mod`).
  `{special: date}` builds the date range from the `start_`, `end_` and `unitary_` columns, and
  `{special: collection}` shows the collection, accession number and collection history.
- `sections` entries are `{label, keys}`. Each key's value is shown under one heading, in order.
  Values that already contain `<p>` are not wrapped again.
- A field or section with no value is left out, so a type's list can be generous.
- Citations and bibliography (`primary_citation`, `essay_number`, `sources_used`,
  `other_bibliography`) are the same for every type and live in `metadata.html`.

Before this file, the per-type arrangements were `{% if page.objtype == ... %}` blocks in
`metadata.html`, merged into one flat list in commit `1610090`.
