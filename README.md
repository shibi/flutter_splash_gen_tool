# Splash GenX

Windows desktop tool that generates Flutter splash icons (1152×1152 / 768 circle, or 960×960 / 640 circle) from a selected image. See `/mnt/project-files/plan/splash-genx-plan.md` for the full plan.

## Install

Download `SplashGenX-Setup-x.y.z.exe` from the repo's Releases page (tagged builds) or from the **Windows installer** workflow run's artifacts in the Actions tab, then run it.

## Use

1. **Open image** and pick a PNG/JPEG/WebP/BMP.
2. Choose **1152 × 1152** (768 px circle) or **960 × 960** (640 px circle).
3. Use the **Scale** slider (or **Fit in circle** / **Fill background**) and drag the image or use the arrow keys (Shift = 10 px) to align it with the red circle. The circle is a guide only and is never exported.
4. Pick a **Background** colour. Output has no alpha channel.
5. **Export PNG** or **Export JPEG**.

## Release a new installer

Bump `version:` in `pubspec.yaml`, then push a tag such as `v1.0.0`. The workflow builds the installer and attaches it to a GitHub release.

## Run on Windows

Requires Flutter (stable) with Windows desktop support and Visual Studio 2022 with the "Desktop development with C++" workload.

```
flutter pub get
flutter run -d windows
```

## Test

```
flutter test
```
