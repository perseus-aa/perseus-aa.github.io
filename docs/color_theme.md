# Color Theme

For simplicity, CollectionBuilder uses pre-compiled Bootstrap CSS.
However, to make basic theming possible, we have added some code in `_sass/_theme-colors.scss` based on Bootstrap Sass to generate custom color CCS for btn-, btn-outline-, text-, and bg- classes. 
The custom classes can override existing Bootstrap theme colors or create new color classes. 

By default, these options are not used.

To add custom colors, edit the two columns in `_data/config-theme-colors`:

- Add a "color_class", e.g. `primary` (i.e. the part after the `-` in `btn-primary`).
- Add a "color" in hex code, e.g. `#4232a8`.

Any "color_class" with a "color" value will generate a btn-, btn-outline-, text-, and bg- class for the color, e.g. `btn-primary`, `btn-outline-primary`, `text-primary`, and `bg-primary`. 
Any "color_class" with a blank "color" will be ignored.
For convenience, the standard Bootstrap theme colors are provided to fill in if desired, which will override the existing Bootstrap colors.
Adding a non-Bootstrap "color_class" will generate new custom btn colors.
E.g. "color_class" `special` will generate CSS for `.btn-special` and `.btn-outline-special`.

CollectionBuilder uses `btn-primary`, `btn-outline-primary`, `btn-success`, `btn-info`, `btn-outline-secondary`, `btn-light`, and `btn-outline-light` in page layouts, so overriding those styles will have immediate effects on the colors.
The nav elements use `bg-dark` and `text-dark` by default.

## Perseus theme (this site)

This site follows the theme of [beta.perseus.tufts.edu](https://beta.perseus.tufts.edu/) (MVP), whose tokens are defined in the daisyUI "perseus" theme in
[`input.css`](https://github.com/PerseusDLCode/MinimumViablePerseus/blob/dev/src/mvp/site/static/css/input.css).
Because Bootstrap here is pre-compiled, the tokens are ported by hand, as hex equivalents of the original `oklch()` values:

- `_data/config-theme-colors.csv`: Bootstrap theme colors (buttons, `bg-`, `text-` classes).
- `_data/theme.yml`: Inter font (loaded from rsms.me), text and link colors, light navbar.
- `assets/css/custom.css`: `--perseus-*` CSS variables and component overrides (navbar, cards, forms, footer). `cb.scss` pulls this file in via `@use "custom"`, which resolves to this plain CSS file rather than `_sass/_custom.scss`, so keep it flat CSS.
- `_config.yml` (`organization-logo-nav`, `organization-link`): the running-man icon in the navbar, home banner and footer, linking to beta.perseus.tufts.edu.

Links use a slightly darker terracotta (`#9d4a35`) than MVP's primary (`#ba5a42`) so link text meets WCAG AA contrast on the cream background.
