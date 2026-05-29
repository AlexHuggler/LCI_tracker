# PoolFlow marketing site

Jekyll static site for [poolflowapp.com](https://poolflowapp.com), deployed via GitHub Pages.

## Styling (Tailwind CSS)

Tailwind is **compiled at build time** into a minified `assets/css/tailwind.css`
(committed to the repo) rather than loaded from the runtime CDN. The custom theme
(brand `pool-*` colors, font stack, typography plugin) lives in `tailwind.config.js`.

After changing any template, blog post, or the classes toggled in `assets/js/main.js`,
rebuild and commit the CSS:

```bash
npm install        # first time only
npm run build:css  # regenerates assets/css/tailwind.css
# or, while developing:
npm run watch:css
```

The `Tailwind CSS` GitHub Action fails CI if the committed `tailwind.css` is stale.

## Local preview

```bash
bundle install
bundle exec jekyll serve
```
