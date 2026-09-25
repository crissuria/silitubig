# Security Policy

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.** Publicly disclosing a vulnerability before it's fixed gives attackers a head start against anyone hosting a match.

Instead, report it privately using one of these:

1. **GitHub Private Vulnerability Reporting (preferred)** — go to this repository's **Security** tab → **Report a vulnerability**. This opens a private conversation visible only to the maintainer, and lets you track the fix without exposing details publicly. ([GitHub's guide to reporting a vulnerability](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability))
2. **Email** — `janelle92414@gmail.com`, if you'd rather not use GitHub.

When reporting, please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce it (a minimal example is ideal)
- The affected version/commit, if known
- Any suggested fix, if you have one — optional, but appreciated

## What to Expect

This is a small, single-maintainer project (a student project, not a funded security team), so please have reasonable patience — but every report will get a response acknowledging receipt, and a fix or mitigation plan once the issue is understood. Credit is happily given in the fix's release notes unless you'd prefer to stay anonymous.

## Scope

This covers the Sili-Tubig Clash game client and server logic in this repo — multiplayer RPC handling and server-side validation (e.g. `game/arena/actors/tubig/heat_status.gd`), the LAN discovery/join flow (`autoloads/network_manager.gd`), and match/series state.

Of particular interest: anything that lets a modified client act on another player's behalf, forge who an RPC came from, or bypass the server-authoritative checks on tagging, rescuing, or life totals.

Out of scope: issues that require the attacker to already be hosting the match (a malicious host has full control over their own server by design — this is a LAN party game, not a trust-isolated service), and vulnerabilities in Godot Engine itself (please report those [upstream](https://github.com/godotengine/godot/security)).

## Supported Versions

As a single-track project without parallel maintained release branches, only the **latest release** (see the [Releases page](https://github.com/nncast/godot-sili-tubig-clash/releases)) receives security fixes. If you're running an older version, please update before reporting an issue that's already fixed in a later release.
