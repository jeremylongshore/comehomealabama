# comehomealabama.com

Public site for **Mandy Longshore** — RE/MAX of Gulf Shores, Coastal Alabama & West Florida.

- **Live:** https://comehomealabama.com
- **Stack:** Astro 5 + Tailwind v4 + React (islands) + shadcn/ui (Phase B)
- **Hosting:** GitHub Pages today; Cloudflare Pages cutover planned in Phase A commit #2
- **CMS:** Sanity Studio (Phase A commit #2)
- **Engineering parent:** [mandy-real-estate-skills](https://github.com/jeremylongshore/mandy-real-estate-skills) (private)

Built by [Intent Solutions](https://intentsolutions.io).

---

## Local development

```bash
pnpm install
pnpm dev          # http://localhost:4321
pnpm build        # static output → ./dist
pnpm preview      # serve ./dist
pnpm typecheck    # astro check (strict TS)
```

Requires Node ≥ 20.

## Layout

```
src/
  layouts/Layout.astro        # base HTML, SEO meta, header + footer
  components/Header.astro     # primary nav
  components/Footer.astro     # contact, licenses, brokerage
  pages/
    index.astro               # homepage (Phase A: ports holding-page content)
    about.astro               # bio shell — copy lands in Phase B from Sanity
    communities/
      index.astro             # 7-community grid
      [slug].astro            # dynamic page per community
    listings.astro            # IDX iframe → mandy-longshore.sellingcoastalal.com
    reviews.astro             # Birdeye link out (widget inline in Phase B)
    contact.astro             # form posts to /api/lead (CF Function in Phase B)
    journal/index.astro       # MDX field journal (Phase C, currently noindex)
    404.astro
  lib/communities.ts          # static community list (replaced by Sanity in Phase B)
  styles/global.css           # Tailwind v4 import + brand tokens via @theme
public/
  favicon.svg
```

## Brand tokens

Single source of truth lives in `src/styles/global.css` under `@theme`. Phase B
may evolve the typography pair via the `frontend-design` skill. The current floor:

| Token | Value |
|---|---|
| `--color-sand` / `sand-deep` | `#f5efe6` / `#ebe3d3` |
| `--color-ink` / `ink-soft` | `#1c2530` / `#4b5763` |
| `--color-gulf` / `gulf-deep` | `#2d6a7a` / `#1f4d59` |
| `--color-sun` | `#c8a96a` |
| `--color-line` | `#d8cdb8` |
| `--font-display` | Cormorant Garamond Variable |
| `--font-sans` | Inter Variable |

Same tokens are mirrored in the engineering parent at
`mandy-real-estate-skills/web/shared/tokens.css` so the dashboard at
`mandy.intentsolutions.io` shares the design language. Public site **vendors**
(copies) those tokens to stay brokerage-portable — no monorepo coupling.

## Phasing (Sprint 1)

- **Phase A (this commit + 2 follow-ups)** — scaffold + Sanity Studio + Cloudflare Pages cutover
- **Phase B** — `frontend-design` skill drives the luxury aesthetic pass; lead form Function; community copy
- **Phase C** — OG images, sitemap, Lighthouse 100, optional `/journal/` MDX

Tracking: bead `MCHA-k81` (epic) and children.
