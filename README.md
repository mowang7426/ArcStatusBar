# ArcStatusBar 2.0

iOS 17 / arm64e / Theos rootless GitHub project.

## What this version does

This version is intentionally a visual/motion prototype for the supplied
reference video:

- custom time
- cellular visual
- battery percentage
- 5G/WiFi label
- four top dots
- four lower dots
- animated green arc
- smooth morph into/out of the arc HUD
- SpringBoard-only injection

## Build

```bash
make clean
make package FINALPACKAGE=1
```

The `.deb` is generated under:

```text
packages/
```

## GitHub Actions

A workflow is included in:

```text
.github/workflows/build.yml
```

Upload the repository to GitHub, then use:

Actions -> Build ArcStatusBar

## Important

This is NOT a binary copy of CAiPhoneDuoStatus.

The reference tweak was used only as an implementation-direction reference.
This project independently implements its own UI and animation.

The current public implementation intentionally avoids private signal-strength
APIs. Signal bars are therefore visual placeholders. The next iteration can
replace them with build-specific SpringBoard hooks after testing on the exact
iOS 17 build.

The morph demo automatically enters/exits the arc state so the animation can
be tested immediately after installation.

For a daily-driver jailbreak, disable other status-bar/Island tweaks during
testing to avoid SpringBoard view conflicts.
