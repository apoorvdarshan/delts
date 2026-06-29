<div align="center">

<img src="web/assets/delts-glyph.png" width="120" alt="Delts logo">

# Delts

**A free exercise library for iPhone.**

Browse hundreds of exercises with clear form instructions, visuals, and powerful filters — completely free, private, and open source.

![iOS](https://img.shields.io/badge/iOS-17%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/swift-5-F05138?logo=swift&logoColor=white)
![UI](https://img.shields.io/badge/UI-SwiftUI-7950F2)
![Price](https://img.shields.io/badge/price-free-22C55E)
![License](https://img.shields.io/badge/license-MIT-green)
[![Website](https://img.shields.io/badge/website-delts.fit-B8F957)](https://delts.fit)
[![App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/app/id6778653288)
[![Instagram](https://img.shields.io/badge/Instagram-%40delts.fit-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/delts.fit)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Delts-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/company/delts)
[![Product Hunt](https://img.shields.io/badge/Product%20Hunt-vote-DA552F?logo=producthunt&logoColor=white)](https://www.producthunt.com/products/delts)

</div>

---

Delts is a clean, fast iPhone exercise library. Search and filter a large catalog of exercises, then open any move for step-by-step instructions and visuals. No account, no ads, no tracking — everything stays on your device.

## Built By

<img src="web/assets/ace-cpt-badge.png" alt="ACE Certified Personal Trainer" width="96">

Delts is built by **Apoorv Darshan, ACE Certified Personal Trainer**.

## Highlights

- **Hundreds of exercises** with names, target muscles, equipment, level, and category.
- **Step-by-step form instructions** and visuals for every move.
- **Powerful filters** — primary muscle, secondary muscle, equipment, level, force, mechanic, and category — plus search and sort.
- **Three simple tabs** — Workouts (the library), Settings, and About.
- **Custom theme picker** with matching app-icon variants, plus light/dark/system appearance.
- **Completely free** — no ads, no accounts, no subscriptions, no tracking. All settings stay on-device.
- **Localized** into 16 languages.
- **Open source**, built with SwiftUI.

## Screenshots

| Library | Exercise detail |
|:---:|:---:|
| <img src="web/assets/screenshots/4.library.png" width="220" alt="Exercise library"> | <img src="web/assets/screenshots/3.exercise.png" width="220" alt="Exercise instructions"> |
| Search and filter the full exercise catalog | Photos and step-by-step form instructions for every move |

## Repository Layout

- `ios/` — SwiftUI iOS app.
- `web/` — Static marketing, privacy, and terms website.
- `ASSET_CREDITS.md` — Asset attribution notes.

## Run the Website

```sh
cd web
python3 -m http.server 3000
```

Then open `http://localhost:3000`.

## Build the iOS App

Open `ios/delts.xcodeproj` in Xcode and run the `delts` scheme on an iPhone target.

Command-line example:

```sh
xcodebuild -project ios/delts.xcodeproj -scheme delts -configuration Debug -destination 'generic/platform=iOS' build
```

## Contact

For support or project questions:

- apoorvdarshan@gmail.com
- ad13dtu@gmail.com

Follow Delts:

- Instagram: [@delts.fit](https://www.instagram.com/delts.fit)
- LinkedIn: [Delts](https://www.linkedin.com/company/delts)
- Product Hunt: [Delts](https://www.producthunt.com/products/delts)

## License

This project is licensed under the terms in `LICENSE`.
