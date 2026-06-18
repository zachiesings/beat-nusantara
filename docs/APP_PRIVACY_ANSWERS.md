# App Privacy — exact answers (App Store Connect)

Beat Nusantara itself collects **nothing** (no accounts, local-only storage). The
only data collection comes from the **AdMob SDK** for the optional rewarded ads.
We request **non-personalized ads** (`nonPersonalizedAds: true`), so **nothing is
used to track you** → **no App Tracking Transparency prompt needed**.

App Store Connect → your app → **App Privacy** → **Get Started / Edit**.

## 1) "Do you or your third-party partners collect data from this app?"
→ **Yes**

## 2) Data types — toggle ON exactly these (all from AdMob)
For EACH item below, when asked:
- **Used for tracking?** → **No** (we serve non-personalized ads)
- **Linked to the user's identity?** → **No** (no login/account)

| Category | Data type | Purpose to pick |
|---|---|---|
| Identifiers | **Device ID** | Third-Party Advertising |
| Usage Data | **Product Interaction** | Analytics, Third-Party Advertising |
| Usage Data | **Advertising Data** | Third-Party Advertising |
| Diagnostics | **Crash Data** | App Functionality |
| Diagnostics | **Performance Data** | App Functionality |

> These match Google's published "AdMob & App Privacy" data types. Everything lands
> under **"Data Not Linked to You"**, and the **"Used to Track You"** section stays
> **empty** (because of non-personalized ads).

## 3) Tracking section
"Does this app use data for tracking purposes?" → **No.**

## 4) Privacy Policy URL (required because AdMob collects data)
A ready policy is in `docs/privacy.html`. Host it free via **GitHub Pages**:
- GitHub repo → **Settings → Pages** → Source: `Deploy from a branch` → Branch
  `main` / folder `/docs` → Save.
- URL becomes: **https://zachiesings.github.io/beat-nusantara/privacy.html**
- Paste that into App Store Connect (App Privacy → Privacy Policy URL, and also in
  App Information).

## 5) Other simple fields while you're there
- **Pricing**: Free
- **Age rating**: 4+ (no objectionable content)
- **Content rights**: "No third-party content" (all songs/art are original)

---

### If you'd rather have ZERO ad data at launch
Flip `K.adsEnabled = false` in `lib/core/constants.dart` (one line) → the build ships
ad-free → App Privacy becomes **"Data Not Collected"** (no privacy policy needed). You
can switch ads on in a later update. Say the word and I'll do it.

### If you later want personalized (higher-paying) ads
Remove `nonPersonalizedAds: true`, set the data types' **tracking = Yes**, and add an
ATT prompt (`app_tracking_transparency` + `NSUserTrackingUsageDescription`). I can wire
that whenever you want.
