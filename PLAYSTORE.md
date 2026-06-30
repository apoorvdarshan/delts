# Google Play Store Listing — Delts

Everything needed to create and fill the Delts listing in the Google Play Console.
Copy-paste ready. The app is the Android build of Delts (`android/`), package
`com.apoorvdarshan.delts`, versionName `1.0` (versionCode `1`).

---

## Create app

| Field | Value |
|---|---|
| **App name** | `Delts – Exercise Library` *(24/30)* |
| **Package name** | `com.apoorvdarshan.delts` *(cannot change after first upload)* |
| **Default language** | English (United States) – en-US |
| **App or game** | App |
| **Free or paid** | Free *(monetization is an optional in-app tip jar; can't switch Free→Paid later)* |
| **Automatic protection** | On *(default — free anti-redistribution; fine for open-source)* |
| **Declarations** | ✅ Developer Program Policies · ✅ US export laws |

---

## Store listing

### App name (30 max)
```
Delts – Exercise Library
```

### Short description (80 max)
```
Hundreds of exercises with form instructions, muscle filters, and clear steps.
```

### Full description (4000 max)
```
Delts is a focused exercise library — browse hundreds of movements with clear,
step-by-step form instructions and rich filtering. No account, no ads, no
tracking. Everything stays on your device.

WHAT'S INSIDE
• Hundreds of exercises with reference images and numbered, step-by-step
  instructions for proper form.
• Powerful filters — narrow by primary muscle, secondary muscle, equipment,
  level, force, mechanic, and category, each with a clean picker.
• Instant search across names, muscles, equipment, and instructions.
• Sort by name, level, muscle, category, force, mechanic, or equipment.
• A detail view for every exercise: animated visuals plus a tap-to-reveal
  panel with level, category, force, mechanic, and the muscles worked.

BUILT TO BE SIMPLE
Three things, done well: a library you can actually browse, filters that make
sense, and instructions you can follow. No workout logging, no calorie math,
no sign-up walls — just the moves and how to do them.

PRIVATE BY DESIGN
• No account or sign-in.
• No ads. No analytics. No tracking.
• The exercise data and images ship inside the app and run entirely offline.

MAKE IT YOURS
• Five color themes (Lime, Cyan, Pink, Amber, Violet) that re-skin the whole
  app — including the home-screen icon.
• Light, Dark, and Darker appearances.
• Fully localized into 16 languages.

OPTIONAL SUPPORT
Delts stays free. If it's useful to you, an optional in-app "tip" helps keep it
going — it unlocks nothing and is entirely your choice.

OPEN SOURCE
Delts is open source (MIT licensed). Browse the code, report issues, or
contribute on GitHub: github.com/apoorvdarshan/delts

Made by Apoorv Darshan, ACE Certified Personal Trainer.

Exercise data and images are from the open-source free-exercise-db project.
```

### What's New — v1.0 (release notes, 500 max)
```
Welcome to Delts — a clean, free exercise library.
• Browse hundreds of exercises with form instructions and rich filters.
• Search, sort, and filter by muscle, equipment, level, and more.
• Five color themes, light/dark, and 16 languages.
• Completely private: no account, no ads, no tracking.
```

---

## Categorization

| Field | Value |
|---|---|
| **App category** | Health & Fitness |
| **Tags** | Exercise, Workout, Fitness, Strength training, Gym |
| **Store listing contact email** | ad13dtu@gmail.com |
| **Website** | https://delts.fit |
| **Privacy policy** | https://delts.fit/privacy.html |

---

## Data safety (form answers)

- **Does your app collect or share any user data?** No.
- **Data processed on the device only.** Exercise content + images are bundled and
  run offline; the app has no backend and creates no account.
- **In-app purchases:** Yes (consumable "tip" products). Payment is processed by
  Google Play; Delts does not receive or store any payment/personal data.
- **Data encrypted in transit:** N/A for app content (offline); store/billing
  traffic is handled by Google Play over HTTPS.
- **Users can request data deletion:** N/A — no data is collected.

---

## Content rating (IARC questionnaire)

- Category: **Utility / Reference / Other** (or Health & Fitness).
- No violence, sexual content, profanity, gambling, or user-generated content.
- Expected rating: **Everyone / PEGI 3**.

---

## Localization

In-app UI is fully translated into 16 locales (English + Arabic, Azerbaijani,
German, Spanish, French, Hindi, Italian, Japanese, Korean, Dutch, Polish,
Brazilian Portuguese, Romanian, Russian, Simplified Chinese). The Play Store
listing itself is English; other locales fall back to English on the store
while receiving full in-app translations via per-locale resources. Exercise
names and instructions remain English (sourced from free-exercise-db).

---

## Store listing assets (checklist)

- [ ] **App icon** — 512×512 PNG (the lime Delts leaf on black).
- [ ] **Feature graphic** — 1024×500 PNG/JPG.
- [ ] **Phone screenshots** — 2–8, 16:9 or 9:16 (Workouts list, exercise detail,
      filters open, Settings/themes, Support, About).
- [ ] (Optional) 7" / 10" tablet screenshots.

---

## Release (when ready)

- Build a signed **Android App Bundle** (`.aab`): add a release `signingConfig`
  (or use Play App Signing with an upload key), then `./gradlew bundleRelease`.
- Upload to an **Internal testing** track first — Google Play Billing only works
  for builds installed from Play, so the **tip jar** stays "unavailable" until then.
- Create the 3 in-app products in **Monetize → Products → In-app products**:
  - `com.apoorvdarshan.delts.tip.small`
  - `com.apoorvdarshan.delts.tip.medium`
  - `com.apoorvdarshan.delts.tip.large`

---

## Contact

- Email: ad13dtu@gmail.com
- Website: https://delts.fit
- X: https://x.com/apoorvdarshan
- Instagram: https://www.instagram.com/delts.fit
- GitHub: https://github.com/apoorvdarshan/delts
