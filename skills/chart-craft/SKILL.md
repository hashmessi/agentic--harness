---
name: chart-craft
description: Build charts, graphs, dashboards, KPI/stat tiles, sparklines, and heatmaps that are correct by construction - in any library (Recharts, Chart.js, D3, Plotly, matplotlib, plain SVG). Use before writing any chart code or choosing chart colors.
---

# Data Visualization

Distilled from the Claude Opus 5.5 dataviz procedure. A chart is read by people and executed by you: follow the procedure so it's right by construction, not by taste. Pair with `frontend-craft` for the surrounding UI.

## Procedure - in order (color comes LAST)
1. **Pick the form from the data's job.** Magnitude → bar; change over time → line/area; part-to-whole (few parts) → stacked bar; distribution → histogram/box; correlation → scatter; one headline number → a stat tile, not a chart. Sometimes the answer is a table.
2. **Assign color by job.** Categorical (identity): a fixed hue order, never cycled. Sequential (magnitude): one hue, light → dark. Diverging (polarity): two hues with a neutral grey midpoint. Status (state): reserved good/warning/serious/critical colors.
3. **Validate the palette - compute, don't eyeball.** Check WCAG contrast of every mark and text color against both light and dark surfaces, and check colorblind separation of adjacent categorical hues (simulate deuteranopia/protanopia, e.g. with a small script or a validator tool if available). Fix failures before continuing. Dark mode gets its own selected steps, validated against the dark surface - not an automatic inversion.
4. **Mark specs.** Thin marks; 2px lines; ≥8px point markers; small rounded data-ends anchored to the baseline; a 2px surface-colored gap between adjacent/stacked fills; recessive gridlines and axes; selective direct labels (never a number on every point).
5. **Interaction by default (web).** Line/area: crosshair + tooltip. Bar/dot/cell: per-mark hover tooltip. Hit targets larger than the marks; filters in one row above the charts.
6. **Accessibility pass.** ≥2 series → a legend, and ≤4 series are also direct-labeled, so identity is never color-alone. Provide a table view. Status always ships with icon + label. Texture/pattern available for forced-colors/print.
7. **Render and look once.** Check label collisions, overflow, geometry, both themes, ~400px width.

## Non-negotiables
- **Never a dual-axis chart.** Different scales → two charts, small multiples, or index to a common base.
- **One scale** places marks, ticks, and labels; every label names a value the chart actually reaches.
- **Color follows the entity, never its rank** - filtering must not repaint the remaining series.
- **No rainbow scales;** no hue at a diverging midpoint. A 9th category is never a generated hue - fold into "Other", facet, or use small multiples.
- **Text wears text tokens,** never the series color. Status colors are never reused as series colors.
- Chart text takes theme tokens so it reads in both themes; marks and labels stay inside the drawing bounds (leave room in an SVG viewBox for outer labels; give every shape an explicit fill).
- Numbers shown must come from the data by computation, never typed in by hand (R3.8).

## Anti-patterns (if your chart matches one, it's wrong)
Dual axes · pie with >5 slices or comparing pies · 3D anything · truncated bar baselines (bars start at zero) · rainbow/cycled palettes · legend far from data when direct labels fit · values on every point · heavy gridlines · color as the only encoding · smoothing that invents values between points · stacked areas for series meant to be compared individually.
