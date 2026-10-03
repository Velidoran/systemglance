#!/usr/bin/env bash
# Install or upgrade the "System Glance" plasmoid into the current user's Plasma.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$HERE/package"
ID="com.github.systemglance"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "kpackagetool6 not found (need Plasma 6)." >&2
    exit 1
fi

if kpackagetool6 --type Plasma/Applet --show "$ID" >/dev/null 2>&1; then
    echo "Upgrading $ID ..."
    kpackagetool6 --type Plasma/Applet --upgrade "$PKG"
else
    echo "Installing $ID ..."
    kpackagetool6 --type Plasma/Applet --install "$PKG"
fi

echo
echo "Done. Installed under: ~/.local/share/plasma/plasmoids/$ID"
echo "Preview without touching the panel:   plasmawindowed $ID"
echo "Add to a panel:  right-click the panel -> Add Widgets -> \"System Glance\""
echo "If an already-added instance looks stale:  systemctl --user restart plasma-plasmashell"
