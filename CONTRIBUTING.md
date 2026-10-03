# Contributing to System Glance

Thanks for helping improve System Glance! Bug reports, ideas and pull requests are all welcome.

- **Found a bug?** [Open a bug report](https://github.com/Velidoran/systemglance/issues/new?template=bug_report.yml). Screenshots of the popup show your hostname, IP addresses, Wi-Fi network name and SSH hosts, so crop or blur anything you'd rather keep private.
- **Have an idea?** [Suggest a feature](https://github.com/Velidoran/systemglance/issues/new?template=feature_request.yml).
- **Found a security problem?** Please report it privately as described in [SECURITY.md](SECURITY.md), not in a public issue.

## Development setup

You need KDE Plasma 6. The widget is plain QML and JavaScript, so there's nothing to compile.

```sh
git clone https://github.com/Velidoran/systemglance.git
cd systemglance
./install.sh                              # install, or upgrade in place
plasmawindowed com.github.systemglance    # run it in a window; QML errors print to the terminal
```

After editing files under `package/`, run `./install.sh` again and restart `plasmawindowed`. A copy on your panel picks up the change after `systemctl --user restart plasma-plasmashell`, and its errors and `console.warn` output go to `journalctl --user -u plasma-plasmashell`.

## Checks

```sh
scripts/check.sh     # shellcheck, metadata.json, config keys and QML syntax
scripts/package.sh   # builds dist/systemglance-<version>.plasmoid
```

`check.sh` needs shellcheck, jq, xmllint and Qt 6's qmlformat. On Debian and Ubuntu that's `shellcheck jq libxml2-utils qt6-declarative-dev-tools`; on Arch, `shellcheck jq libxml2 qt6-declarative`; on Fedora, `ShellCheck jq libxml2 qt6-qtdeclarative-devel`. `package.sh` needs jq, zip and unzip. CI runs both on every pull request.

There are no automated UI tests, so please also try your change in `plasmawindowed` or on a panel.

## Code style

- Follow the existing QML: 4-space indents (`.editorconfig` has the details), `i18n()` around every user-visible string, and small components such as `StatBar` for repeated rows.
- Text the widget reads from the system or the network, such as Wi-Fi network names, mount points and replies from api.ipify.org, must be shown with `textFormat: Text.PlainText` or validated first. Never let it be parsed as rich text.
- The `executable` engine runs commands through a shell, so never build a command from that kind of text either.
- No network access without an explicit click: today that's only the public IP lookup. No telemetry, update checks or background requests.
- Stick to commands a Plasma desktop already has. A new required dependency needs a clear reason in the pull request.

## Pull requests

- Keep each pull request focused on one change, and describe how you tested it. The pull request template has a short checklist.
- Make sure `scripts/check.sh` passes.
- Update the README if you change what the widget shows or how it's configured. If the popup looks different, update `docs/popup.png` too, with a screenshot that doesn't show your real hostname, Wi-Fi network name, public IP or SSH hosts.

## Releasing (maintainers)

1. Update `Version` in `package/metadata.json`, and move the changelog's Unreleased entries under the new version.
2. Merge to `main`, then publish a release from the repository's **Releases** page: **Draft a new release**, create a tag such as `v1.2.3` on `main`, paste the changelog entry as the notes and click **Publish release**. `gh release create v1.2.3 --target main` works too.
3. The release workflow checks that the tag matches `metadata.json` and has a changelog entry, runs the checks, builds the `.plasmoid` and attaches it to the release.
