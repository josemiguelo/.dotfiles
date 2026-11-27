// Android SDK packages: every ID in packages (beside this script) is installed
// in the SDK Android Studio manages, by Studio's own sdkmanager on Studio's
// bundled JDK, so Studio sees them as its own. Studio and its Command-line
// Tools come by hand: this names them when an install needs them, never
// installs them. What Studio installs on top stays.
import { missingPins, problems, sdkDir, sdkmanagerInstall } from "#android-sdk";

const sdk = await sdkDir();

export async function check() {
  const missing = sdk ? await missingPins(sdk) : [];
  for (const id of missing) console.log(`missing: ${id}`);
  // What the install would need, so the status says it up front.
  if (!sdk || missing.length > 0) for (const problem of problems(sdk)) console.warn(problem);
  return Boolean(sdk) && missing.length === 0;
}

export async function install() {
  const missing = sdk ? await missingPins(sdk) : [];
  if (sdk && missing.length === 0) return;
  const needs = problems(sdk);
  if (needs.length > 0) throw new Error(needs.join("\n"));
  await sdkmanagerInstall(sdk, missing);
  const left = await missingPins(sdk);
  if (left.length > 0) throw new Error(`still missing after sdkmanager: ${left.join(" ")}`);
}
