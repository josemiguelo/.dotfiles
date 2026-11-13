// Android SDK: the packages .loadout/packages pins, installed with Android
// Studio's own sdkmanager into the SDK Studio manages. Studio, and its
// Command-line Tools, are installed by hand; the check names what's missing.
import { script } from "loadout";

export const androidSdk = script("android-sdk", {
  description: "Android SDK packages at the IDs .loadout/packages pins",
  later: "large SDK downloads, after Android Studio comes by hand",
  managedBy: ".loadout/sdk.ts",
  updatesManagedBy: ".loadout/outdated-sdk.ts",
});
