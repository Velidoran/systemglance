#!/usr/bin/env bash
# Run the same checks as CI: shell scripts, metadata, config keys and QML syntax.
# Needs shellcheck, jq, xmllint (libxml2) and qmlformat (Qt 6 declarative tools).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# qmlformat usually lives outside PATH, under Qt's own bin directory.
find_qmlformat() {
    local name dir
    for name in qmlformat6 qmlformat-qt6 qmlformat; do
        if command -v "$name" >/dev/null 2>&1; then
            command -v "$name"
            return
        fi
        for dir in /usr/lib/qt6/bin /usr/lib64/qt6/bin /usr/lib/x86_64-linux-gnu/qt6/bin; do
            if [ -x "$dir/$name" ]; then
                echo "$dir/$name"
                return
            fi
        done
    done
    return 1
}

QMLFORMAT="${QMLFORMAT:-$(find_qmlformat || true)}"
missing=()
for tool in shellcheck jq xmllint; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
[ -n "$QMLFORMAT" ] || missing+=("qmlformat")
if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing tools: ${missing[*]}" >&2
    exit 1
fi

echo "== Shell scripts"
shellcheck install.sh scripts/*.sh

echo "== metadata.json"
jq -e '.KPlugin.Id and .KPlugin.Name and (.KPlugin.Version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))' \
    package/metadata.json >/dev/null \
    || { echo "metadata.json needs KPlugin.Id, Name and an x.y.z Version" >&2; exit 1; }

echo "== Config keys"
xmllint --noout package/contents/config/main.xml
declared="$(grep -o '<entry name="[^"]*"' package/contents/config/main.xml | cut -d'"' -f2 | sort -u)"
# Every Plasmoid.configuration.<key> and cfg_<key> must be declared in main.xml,
# or it silently reads as undefined / never gets saved.
referenced="$( {
    grep -rhoE 'Plasmoid\.configuration\.[A-Za-z0-9_]+' package/contents/ui | sed 's/.*\.//'
    grep -hoE '\bcfg_[A-Za-z0-9_]+' package/contents/ui/ConfigGeneral.qml | sed 's/^cfg_//'
} | sort -u)"
undeclared="$(comm -13 <(echo "$declared") <(echo "$referenced"))"
if [ -n "$undeclared" ]; then
    echo "Used in QML but missing from main.xml: $undeclared" >&2
    exit 1
fi

echo "== QML syntax"
status=0
while IFS= read -r file; do
    if ! "$QMLFORMAT" "$file" >/dev/null; then
        echo "Syntax error in $file" >&2
        status=1
    fi
done < <(find package -name '*.qml' | LC_ALL=C sort)
[ "$status" -eq 0 ] || exit 1

echo "All checks passed."
