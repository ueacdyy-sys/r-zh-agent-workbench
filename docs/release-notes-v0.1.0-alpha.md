# v0.1.0-alpha Release Notes

This is the first public alpha of R Zh Agent Workbench.

## What is included

- `packages/rstudiozhai`
  - RStudio Addin workbench prototype.
  - Chinese environment diagnostics.
  - AI provider registry and OpenAI-compatible gateway support.
  - Quarto report drafting and rendering helpers.
  - RStudio Connections snippets.
  - Snippets, CLI, MCP prototype, project scan, and audit helpers.

- `localizer`
  - RStudio 2026.05.0+218 Chinese dictionary.
  - Safe runtime overlay installer.
  - Inspect, install, remove, and restore modes.
  - Patch records from the local localization work.

- `docs`
  - First-principles product map.
  - Open source and commercialization boundaries.
  - Posit Assistant and AI gap analysis.
  - RStudio feature exploration and Chinese tutorial materials.

## Verification

- R package base tests passed.
- `R CMD build` and `R CMD check --no-manual --no-build-vignettes` completed with `Status: OK`.
- Localizer inspect mode detected RStudio `2026.05.0+218` and 1188 dictionary entries.

## Important boundaries

- This is not an official Posit or RStudio project.
- This release does not include RStudio binaries, modified RStudio resources, Posit Assistant files, or user state.
- The localizer is experimental and version-specific.
- Posit Assistant is treated as a compatibility and product-gap reference, not as a redistributed component.

## Suggested tag

```text
v0.1.0-alpha
```
