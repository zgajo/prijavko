# Release Checklist

## Before Public Play Store Submission

- [ ] **Replace AdMob App ID** — `android/app/src/main/AndroidManifest.xml` currently uses
  Google's sample test App ID (`ca-app-pub-3940256099942544~3347511713`). Replace with the
  real AdMob App ID once the AdMob account is provisioned (Story 10.x).
  Shipping the sample ID to production will break ad revenue and may violate Play Store policy.
