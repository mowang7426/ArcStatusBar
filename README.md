# ArcStatusBar v2.1

iOS 17 / arm64e / rootless Theos project.

## v2.1 changes

- Fixed the previous `centerLabel` compile error by removing the obsolete center-label design entirely.
- No 5G/LTE text is drawn.
- Wi-Fi stays in the center.
- Four cellular bars morph into four dots underneath Wi-Fi.
- Battery capsule morphs into a vertical line.
- A thick arc grows from the right side into the upper ring.
- Reverse animation is included.
- Touch interaction is disabled so the overlay does not steal taps.
- Includes a minimal Settings preference bundle.

## Build

GitHub Actions is configured for macOS + Theos.

Locally:

```sh
export THEOS=$HOME/theos
make clean
make package FINALPACKAGE=1
```

The rootless package architecture is `iphoneos-arm64`; the tweak itself is compiled as arm64e.

## Important

This version is a visual status-bar overlay. It intentionally avoids copying the reference plugin's binary and does not depend on private status-bar classes.

For the next stage, the visual overlay can be replaced with runtime discovery of iOS 17's native status-bar views if exact native positioning is required.
