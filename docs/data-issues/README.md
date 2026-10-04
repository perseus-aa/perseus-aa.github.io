# Facet value issues

The browse cards and the home page facets list the values of short metadata fields (period, material, region,
painter and so on). Where the same thing is written in two ways, or a value carries markup, the facets show it
as separate terms. The problems come from the data in Airtable, so they need fixing there.

`facet-value-issues.csv` lists them, one row per problem, from `_data/metadata-full.csv`:

| column | meaning |
|---|---|
| issue | the kind of problem (see below) |
| field | the metadata field |
| value | the value with the problem |
| objects | how many objects have this value |
| related value, related objects | the value it should probably match, and how many objects have that |
| example ids | up to four object ids (the `id` column, such as `aa_1950`) to find records in Airtable |
| suggestion | what to check or change |

## Kinds of problem

- **markup in value**: `periods` holds `<P>Archaic</P><P>Classical</P>` instead of `Archaic;Classical`, so each
  combination counts as one term. Two `context` values are prose with markup.
- **same term, different spelling**: case, spacing or a stray bracket (`kylix` and `Kylix`, `High Classical]`).
  These are almost certainly errors.
- **stray character**: a bracket, quotation mark or garbled character inside a value.
- **possible typo**: a rare value that is nearly the same as a common one (`London, Britsh Museum`,
  `Tysczkiewicz Painter`). These are candidates to review: some are different things that happen to look alike
  (`Museum of Fine Arts, Houston` and `Boston`).
- **abbreviation**: `Late Clas./Hell.` in `period`, where `Late Classical/Hellenistic` is also used.
- **several values in one term**: `Late Classical/Hellenistic` is one term. Decide whether such values stay as
  they are or become two terms separated by `;`.
- **uncertainty written into the value**: `Ephesus?`, `Ephesus (?)` and `Uncertain, (Ephesus?)` all occur, so
  uncertain and certain records show up under different terms. Choose one convention, or record uncertainty in a
  separate field.
- **no such column**: the site configuration lists a `site` field that the data does not have. This one is on
  our side.

Terms are separated by semicolons. To produce the list again after the data changes, run
`python3 docs/data-issues/check_facet_values.py` from the root of the repository.
