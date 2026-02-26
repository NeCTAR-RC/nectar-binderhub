# Nectar BinderHub

This repository builds the ARDC/Nectar themed Docker image for BinderHub. It layers ARDC branding (navbar, footer, styles, bee loader) on top of the upstream `k8s-binderhub` image using a custom `page.html` template and extra static files — no React or webpack modifications.

## File Structure

```
nectar-binderhub/
├── Dockerfile
├── Makefile
└── theme/
    ├── templates/
    │   ├── page.html                          # Replaces upstream's page.html
    │   └── partials/
    │       ├── navbar.html                    # Two-level ARDC navbar (Bootstrap 5)
    │       ├── footer.html                    # ARDC footer with logos, newsletter, acknowledgement
    │       └── scripts.html                   # Loader timeout JS + Google Analytics
    └── static/
        ├── ardc.css                           # All CSS overrides
        └── images/
            ├── ardc_nectar_research_cloud.svg # Navbar logo
            ├── ardc-logo.svg                  # Footer ARDC logo
            ├── ncris-provider.svg             # Footer NCRIS logo
            ├── bee-loader.svg                 # Loading spinner
            └── favicon.ico                    # ARDC favicon
```

## How It Works

BinderHub's frontend is a React SPA. Upstream's `page.html` is a minimal shell that loads the React bundle into `<div id="root">`. We replace it with our own that:

- Keeps everything upstream has (`pageConfig`, `dist/styles.css`, `dist/bundle.js`, OpenGraph tags, `extra_header_html`, `extra_footer_scripts`)
- Hides the upstream Binder logo via `pageConfig` override
- Loads FontAwesome 6 from CDN (navbar icons, footer icons, button arrows)
- Loads `ardc.css` after upstream styles (so our overrides win)
- Includes ARDC two-level navbar before `<div id="root">` and footer after it
- Includes loader timeout JS (toggleable) and Google Analytics (conditional)

React renders inside `<div id="root">` as normal and is unaware of our navbar/footer.

## Dockerfile

```dockerfile
FROM docker.io/jupyterhub/k8s-binderhub:<tag>

COPY ./theme/templates/ /etc/binderhub/templates/
COPY ./theme/static/ /etc/binderhub/static/
```

The Helm chart's `binderhub_config.py` hardcodes `c.BinderHub.template_path = "/etc/binderhub/templates"`, so our templates override upstream's.

## Build

```bash
make build            # builds image tagged with git SHA
make build TAG=v1.0   # builds with custom tag
make push             # pushes to registry.rc.nectar.org.au/nectar/binderhub
```

## Required Helm Values

```yaml
config:
  BinderHub:
    extra_static_path: /etc/binderhub/static
    extra_static_url_prefix: /extra_static/
    template_variables:
      JUPYTERHUB_URL: "https://jupyterhub.rc.nectar.org.au"
      EXTRA_STATIC_URL_PREFIX: "/extra_static/"
      enable_loader_timeout: true
      google_analytics_code: "UA-XXXXXXXX-X"
      google_analytics_domain: "auto"
```

| Variable | Purpose |
|---|---|
| `JUPYTERHUB_URL` | Navbar Control Panel/Logout links and timeout help message |
| `EXTRA_STATIC_URL_PREFIX` | URL prefix for CSS, images, favicon |
| `enable_loader_timeout` | Toggle 30s timeout help on the loading page (default: disabled) |
| `google_analytics_code` | GA tracking ID — GA only loads when this is set |
| `google_analytics_domain` | GA domain config |

## Customisations

### Styling (ardc.css)

- **Figtree font** — Google Fonts, applied to body/form/headings/buttons
- **Sticky footer layout** — flexbox body with `min-height: 100vh`
- **Purple links** — `#8E489B`, hover dark `#16161d` with cyan `#00A2C4` underline
- **ARDC buttons** — yellow `#f8b20e` → purple `#8e489b` on hover, with FontAwesome chevron arrow animation
- **Logo container collapse** — hides empty wrapper left by pageConfig override
- **Launch button** — capitalize, 2px border, mobile wrap below 992px
- **Circle-point styling** — fixed 2em square shape, ARDC brand colours (yellow/pink/blue)
- **Two-level navbar** — white top bar + gray `#f3f3f3` bottom bar, social icon circles, collapse animation, purple Log Out CTA
- **White footer** — 3-row layout with NCRIS/ARDC logos, newsletter, quick links (yellow bullet markers), acknowledgement, copyright
- **Display utilities** — `.d-none`, `.d-sm-inline-block` etc. for responsive navbar text
- **Bee loader** — replaces upstream's circles with bee-loader.svg animation

### Template (page.html + partials)

- **Page title** — "ARDC Nectar BinderHub Service"
- **Favicon** — ARDC icon
- **ARDC navbar** — two-level sticky-top: white top bar (logo, newsletter, contact, social icons) + gray bottom bar (About, Support, Control Panel, Log Out)
- **Need help section** — Jupyter community links + Nectar Support Centre
- **ARDC footer** — white 3-row: NCRIS/ARDC logos + newsletter subscribe + quick links, First Australians acknowledgement, copyright with Terms/Privacy/Accessibility
- **Loader timeout** — after 30s (or on error), shows help message with JupyterHub link
- **Google Analytics** — classic analytics.js, respects DNT, no cookies, anonymised IPs

## Upgrade Process

Our navbar and footer sit outside React's `<div id="root">` and are unaffected by upstream JS changes. However, `ardc.css` targets DOM elements rendered by React (see Upstream Dependencies below), so CSS can break if upstream renames IDs/classes or changes the DOM structure.

```
1. Check upstream release notes for breaking changes
2. Diff upstream's page.html against ours for new blocks we need to adopt
3. Update base image tag in Dockerfile
4. make build
5. Visual check: launch button, circle points, bee loader, heading sizes, link colours
6. Timeout test: navigate to /v2/fake/anything and wait 30s for help message
7. Responsive check: resize browser to verify navbar collapse and footer stacking
8. make push
9. Deploy
```

## Upstream Dependencies

Our customisations depend on these upstream elements remaining stable:

| Element | What We Depend On |
|---|---|
| `page.html` | We override the entire file |
| `pageConfig` | `logoUrl`, `logoWidth` keys |
| `#btn-launch` | Launch button ID for mobile wrap CSS |
| `.circle-point` | Class name + inline styles for colour override |
| `#loader` | Element ID + `.error` class for bee loader and timeout JS |
| `@keyframes spin` | Animation used by bee loader |
| Bootstrap 5.3.x | Grid system, breakpoints, navbar collapse |
| FontAwesome 6.5.2 | CDN — navbar icons, footer icons, button hover arrows |

## Alternative Approaches

If this approach becomes unviable (e.g. upstream removes `template_path` or restructures DOM beyond CSS repair):

- **Fork**: maintain full BinderHub repo with ARDC changes in React/SCSS. Full control but merge conflicts on every upgrade.
- **npm packages**: build own React app importing `@jupyterhub/binderhub-react-components`. Clean upgrade path but packages are immature (v0.1.0, raw JSX, no docs) as of Feb 2026.

---

This project was developed with the assistance of AI.
