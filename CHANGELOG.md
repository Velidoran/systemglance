# Changelog

Notable changes to System Glance are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-10-03

The first public release.

### Added

- A panel icon that opens a popup with CPU, RAM, optional swap and per-mount disk usage as meter bars.
- A rolling network throughput sparkline (about 90 seconds) with live download and upload rates, plus disk read and write rates.
- Per-interface details: Wi-Fi network name or link state, IPv4 and global IPv6 addresses with copy buttons, and the default gateway.
- An optional public IP row that asks api.ipify.org only when you click it.
- SSH buttons that open your terminal already running `ssh user@host`.
- Settings for the refresh interval, mount points, swap, terminal command, SSH hosts and the public IP row.
- Website and bug report links in the widget's metadata.

### Fixed

- Mount points with spaces in their names, common for USB drives, were left out of the disk list.
- After the popup had been opened once, `ip`, `nmcli` and `df` kept running on the refresh timer until Plasma restarted. They now run only while the popup is open.
- Reading the Wi-Fi network name could make NetworkManager scan for networks every 30 seconds. The widget now reads the cached scan results.
- Wi-Fi network names and disk labels could be interpreted as rich text. They're now shown as plain text, and a reply from api.ipify.org that isn't an IP address is ignored.

[Unreleased]: https://github.com/Velidoran/systemglance/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Velidoran/systemglance/releases/tag/v1.0.0
