# Security policy

System Glance runs shell commands on your machine and launches SSH sessions, so security reports are taken seriously.

## Reporting a vulnerability

Please **don't open a public issue** for security problems. Instead, report them privately through GitHub:

1. Go to the repository's **Security** tab.
2. Click **Report a vulnerability** ([direct link](https://github.com/Velidoran/systemglance/security/advisories/new)).
3. Describe the problem, how to reproduce it, and its impact.

The maintainer will acknowledge your report, keep you updated while a fix is prepared, and credit you in the release notes if you'd like.

## Scope

In scope:

- Command injection: text the widget reads from the system or the network, such as Wi-Fi network names, mount points or the reply from api.ipify.org, ending up in a shell command.
- Markup injection: that same text being rendered as rich text instead of plain text, for example a network name that makes the popup load a remote image.
- Network requests, or commands run, beyond what the README describes.

Out of scope:

- Commands you enter in the widget's own settings. The terminal command and SSH hosts run exactly what you type.
- Vulnerabilities in Plasma, NetworkManager, OpenSSH, your terminal or api.ipify.org. Please report those to their projects.

## Supported versions

Security fixes go into the latest release.
