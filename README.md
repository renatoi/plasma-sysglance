# System Glance

A compact KDE Plasma 6 panel widget that replaces a whole row of system-monitor
plasmoids with one labeled strip:

```
RAM 19% | DISK 48% | CPU 1% 39° | GPU 2% 43°
```

Clicking it opens a detail popup; hovering shows a summary tooltip.

## Features

- **Panel strip** — RAM used %, disk used % (all filesystems), CPU usage % +
  hottest-core temperature, GPU usage % + temperature. Tabular, fixed-width
  digits so the row never shifts as values tick.
- **Configurable strip layout** (Appearance settings page) — a reorderable
  metric list: drag to set left-to-right order, checkbox to show/hide, and
  a per-metric dropdown picking which values it shows and in what order
  (usage %, temperature for CPU/GPU, used amount for RAM/disk). Stored as
  `metricOrder` plus per-metric `Shown`/`Parts` (ordered comma-separated
  part keys) in the config.
- **Appearance options** — text or icon labels (icons picked via KDE's icon
  dialog, including custom PNG/SVG files); font size (0 = theme default);
  value width fit-content (default) or fixed slots (row never shifts);
  gaps inside groups and between groups; custom colors for values, labels,
  warning and critical states (defaults follow the Plasma theme).
- **Threshold color coding** — values turn amber at the configured threshold
  and red at threshold + 10. Disk only ever turns amber (a nearly-full disk is
  a capacity fact, not an emergency). Thresholds and update interval are
  configurable per metric.
- **Click popup** — Memory (used / free / total + swap), per-partition disk
  breakdown (used / free / total), per-core CPU grid (usage, temperature,
  frequency), and GPU details (VRAM, power draw, core/memory clocks, rolling
  10-minute temperature peak).
- **Hover tooltip** — one-line summary per device.
- Reads everything from KSystemStats via `org.kde.ksysguard.sensors` — the
  same daemon Plasma's own System Monitor widgets use. NVIDIA GPUs work
  through the daemon's NVML backend; no lm_sensors hwmon entry needed.

## Releasing

1. Bump `KPlugin.Version` in `metadata.json` and add a section to
   `CHANGELOG.md` (`## [x.y] - date`).
2. Commit, then tag and push: `git tag vx.y && git push origin main vx.y`.
3. GitHub Actions builds the `.plasmoid` and publishes a GitHub release with
   the changelog section as notes (`.github/workflows/release.yml`).
4. For the KDE Store (store.kde.org), upload the `.plasmoid` from the GitHub
   release (or `make dist`) to the product page under
   *Plasma 6 Applets*.

## Requirements

- Plasma 6 (`libksysguard` QML bindings, present on any stock install)
- For NVIDIA GPU stats: a working `nvidia-smi`

## Install

```sh
make install    # first time
make upgrade    # after changes (restarts plasmashell)
```

Then add **System Glance** to a panel via *Add Widgets…*.

## Note

The per-partition list in the popup currently hardcodes the two partition
UUIDs of the machine it was written on (KSystemStats has no wildcard sensor
subscription). Edit the `model` arrays in `contents/ui/main.qml` — find your
partition IDs with:

```sh
busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 \
  org.kde.ksystemstats1 allSensors | tr '"' '\n' | grep '^disk/'
```

## License

MIT
