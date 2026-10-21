# AMDolly — SMC Trading Journal

AMDolly is a Flutter starter app for journaling XAUUSD and BTCUSD Smart Money Concepts trades. It includes the supplied crown-and-monogram logo.

## Setup
Requires Flutter SDK and Android SDK / Android Studio on a computer.

```bash
flutter pub get
flutter run
```

Build an Android APK:
```bash
flutter build apk --release
```
APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Strategy workflow configured
1. Identify a meaningful point of interest (OB, FVG, or key level).
2. Wait for consolidation/compression at the POI and mark the range high/low.
3. Observe a false break/liquidity grab outside the range and a close back inside.
4. Wait for displacement and, if part of the plan, BOS/CHoCH or an FVG to confirm direction.
5. Plan entry and invalidation beyond the sweep extreme, then calculate risk before entry.
6. Journal which confluences actually occurred and whether the trading plan was followed.

This checklist records a process; it does not predict price or guarantee reversals. A false break can continue into a breakout, so confirmation and predefined risk matter.

## Current scope
- Local-only storage using `shared_preferences`
- Manually entered trade results in R multiples
- No broker connection, live price feed, screenshot attachment, or cloud backup in this starter version
- ZIP contains Flutter source, not a compiled APK. A Flutter Android build environment is needed to generate an installable APK.
