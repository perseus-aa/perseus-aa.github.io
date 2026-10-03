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
- Every text value on an item page goes through the `markup` filter (`_plugins/perseus_markup.rb`),
  which converts the markup that survives in the data: `<P>`, `<hi rend="ital">` (italic) and
  `rend="head"` or `"bold"` (bold), `<I>`, `<bibl>` and the `PBibRef` family, `<rs>`, `<title>`,
  `<foreign lang=...>` (given a language code), `<quote>`, and the line tags `<lb>`, `<LB>`, `<BR>`
  and `<L>`, which become line breaks. The source is loose (unquoted attributes, varying case, line
  tags that are never closed), so only known tags are converted and any other `<...>` is shown as
  text. That matters because Greek transliteration contains brackets such as `<H( K>`.
  Greek is still shown as transliterated ASCII (Betacode), not converted to Greek letters.
- A section can also name a `filter` that turns markup embedded in the data into HTML
  (`_plugins/perseus_markup.rb`):
  - `essay_markup` converts the catalogue-entry markup in `essay_text` (`<P>`, `<I>`, `<Head>`,
    `<foreign>`, `<PBibRef>`, `<VaseRef>`, `<Note>`, ...). Footnotes (`<Note>`) are numbered and
    listed after the text. Page breaks of the printed source (`<Milestone>`) are kept as a
    `data-page` attribute and not shown.
    Other parts of the entry (collection history, dimensions, condition, decoration) are kept, with
    small headings, because their text differs from the matching metadata columns.
  - `see_also_links` turns `<rs type="building">Name</rs>` into a list of links to the matching
    item pages (matched on `title` or `name`); names with no matching item stay as plain text.
- A field or section with no value is left out, so a type's list can be generous.
- Citations and bibliography (`primary_citation`, `essay_number`, `sources_used`,
  `other_bibliography`) are the same for every type and live in `metadata.html`.

Before this file, the per-type arrangements were `{% if page.objtype == ... %}` blocks in
`metadata.html`, merged into one flat list in commit `1610090`.
