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
