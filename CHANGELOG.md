# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow the `Version` field in `metadata.json` (tag `v<version>`).

## [2.1] - 2026-07-15

### Added
- "Restore Defaults" action in each settings page's title bar.

### Changed
- Color pickers now always show the effective color (the theme's until you
  pick one), with an undo button to return a picked color to the theme —
  replacing the per-color "Custom" checkboxes.

## [2.0] - 2026-07-15

### Added
- Appearance settings page with a live preview of the panel strip driven by
  the actual configuration (sample sensor values).
- Reorderable metric list: drag to set strip order, checkbox to show/hide,
  per-metric dropdown for which values are shown and in what order.
- Custom format templates per metric (`Custom…`) with `{variable}`
  placeholders and click-to-insert chips documenting each variable.
- Text or icon labels; both label text and icons are configurable per metric
  (icons via KDE's icon dialog, including custom PNG/SVG files).
- Font family (lazy-loaded list) and font size (editable preset combo).
- Value width: fit content (default) or a fixed pixel width for all slots.
- Configurable gaps inside groups and between groups.
- Separators can be hidden; separator color is independent.
- Per-color theme overrides (values, labels, separators, warning, critical) —
  each independently follows the Plasma theme unless set to custom.

### Changed
- Values in the strip are right-aligned within fixed slots.
- Config dialog forms hug the left edge instead of KDE's centered layout.
- `qmllint` now actually runs in `make lint` (the `--bare` flag was invalid
  and silently masked by `|| true`).

### Removed
- Bitmask display-mode config keys (`<metric>Display`), replaced by
  `metricOrder` + `<metric>Shown`/`<metric>Parts`/`<metric>Format`.

## [1.1] - 2026-07-13

### Added
- Threshold color coding and click popup with per-core/per-partition detail.

## [1.0] - 2026-07-12

### Added
- Initial release: RAM/disk/CPU/GPU panel strip via KSystemStats.
