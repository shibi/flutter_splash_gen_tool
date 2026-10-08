# Publishing to the Microsoft Store

The app is packaged as an MSIX with the [`msix`](https://pub.dev/packages/msix) package. The Store signs the package itself, so no certificate is needed.

## 1. Reserve the app name and copy its identity

1. In [Partner Center](https://partner.microsoft.com/dashboard), open **Apps and games**, choose **New product**, pick **MSIX or PWA app**, and reserve a name (for example *Splash GenX*).
2. Open the app, then go to **Product management > Product identity**.
3. Copy these three values into `msix_config` in `pubspec.yaml`:

| Partner Center field | `pubspec.yaml` key |
|---|---|
| Package/Identity/Name | `identity_name` |
| Package/Identity/Publisher (starts with `CN=`) | `publisher` |
| Package/Properties/PublisherDisplayName | `publisher_display_name` |

These values aren't secret; they appear in every published package.

## 2. Build the package

Every push runs the **Windows installer** workflow, which uploads the Store package as the `SplashGenX-Store-MSIX` artifact. Pushing a `v*` tag also attaches it to the GitHub release.

To build locally on Windows instead:

```
flutter build windows --release
dart run msix:create
```

The package is written to `build\windows\x64\runner\Release\SplashGenX.msix`.

**Versions:** the package version comes from `version:` in `pubspec.yaml` (`1.2.3+4` becomes `1.2.3.0`). Every Store submission needs a higher version than the last, so bump `version:` before each release.

## 3. Submit

In Partner Center, start a submission for the app and fill in:

- **Packages:** upload the `.msix`.
- **Pricing and availability:** free or paid, and the markets.
- **Properties:** category *Developer tools*; no special hardware.
- **Age ratings:** complete the questionnaire (the app has no user content or online features).
- **Store listing:** description, at least one screenshot (1366 × 768 or larger), and the app icon.
- **Privacy policy URL:** optional here, because the app doesn't collect data or use the internet.

Then **Submit to the Store**. Certification usually takes a few business days.

## Notes

- The package only needs the `runFullTrust` capability, which the tool adds automatically. The app reads and writes files through the Windows open and save dialogs, so it doesn't need broad file-system access.
- The identity values in `pubspec.yaml` must match Partner Center exactly, or the upload is rejected.
