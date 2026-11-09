// What sdk.ts and outdated-sdk.ts share: the SDK directory Android Studio
// manages, the pins, and Studio's own sdkmanager run on the JDK Studio
// bundles (sdkmanager needs a recent Java; Studio's is always one it runs on,
// whatever mise has active).
import { existsSync } from "node:fs";
import { join } from "node:path";
import { $, fail, out, read } from "#loadout";

const HOME = process.env.HOME ?? "";

/** The pinned IDs' file, beside the scripts. */
export const PINS = join(import.meta.dir, "..", "packages");

/**
 * The SDK directory, "" when there's none. android-sdk-dir.sh decides it,
 * for zsh's android plugin too, so the two never disagree.
 */
export async function sdkDir(): Promise<string> {
  const repo = process.env.LOADOUT_REPO || fail("LOADOUT_REPO isn't set: run it from loadout");
  const lib = `${repo}/loadouts/private_dot_local/lib/android-sdk-dir.sh`;
  return out($`sh -c ${'. "$1" && printf %s "$ANDROID_SDK_DIR"'} sh ${lib}`);
}

/** The pinned IDs, comments and blank lines dropped. */
export async function pins(): Promise<string[]> {
  return (await read(PINS))
    .split("\n")
    .map((line) => line.replace(/#.*/, "").trim())
    .filter(Boolean);
}

/**
 * sdkmanager installs build-tools;36.0.0 into build-tools/36.0.0 and writes a
 * package.xml there, so a pin is present without starting a JVM to ask.
 */
const isInstalled = (sdk: string, id: string) => existsSync(join(sdk, ...id.split(";"), "package.xml"));

export const missingPins = async (sdk: string) => (await pins()).filter((id) => !isInstalled(sdk, id));

export const sdkmanagerPath = (sdk: string) => join(sdk, "cmdline-tools", "latest", "bin", "sdkmanager");

/**
 * Android Studio's bundled JDK: a per-user macOS app first (where Toolbox
 * puts it), then the system-wide one, Toolbox's on Linux, the AUR package's.
 */
export function studioJdk(): string | undefined {
  return [
    `${HOME}/Applications/Android Studio.app/Contents/jbr/Contents/Home`,
    "/Applications/Android Studio.app/Contents/jbr/Contents/Home",
    `${HOME}/.local/share/JetBrains/Toolbox/apps/android-studio/jbr`,
    "/opt/android-studio/jbr",
  ].find((jdk) => existsSync(`${jdk}/bin/java`));
}

/** What an install would need and isn't there, each with where to get it. */
export function problems(sdk: string): string[] {
  if (!sdk) return ["no Android SDK in ~/Library/Android or ~/Android: install Android Studio and run its setup wizard"];
  const missing = [];
  if (!studioJdk()) missing.push("Android Studio not found (its bundled JDK runs sdkmanager): install it");
  if (!existsSync(sdkmanagerPath(sdk))) {
    missing.push(
      "no sdkmanager: in Android Studio, Settings > Languages & Frameworks > Android SDK > SDK Tools, tick Android SDK Command-line Tools (latest)",
    );
  }
  return missing;
}

/**
 * The trust sdkmanager tries, in order. The JDK's own cacerts first, then on
 * macOS the login keychain (KeychainStore), where a TLS-intercepting proxy's
 * root lives: with that proxy every download fails on cacerts alone ("IO
 * exception while downloading manifest"). Only a fallback: the login keychain
 * lacks the system's public roots, and KeychainStore-ROOT, which has those,
 * lacks the proxy's. sdkmanager caches the lists it downloads, so a failure
 * can show up only at a package's own download: every call retries.
 */
const TRUST = process.platform === "darwin" ? ["", "-Djavax.net.ssl.trustStoreType=KeychainStore"] : [""];

/** sdkmanager's environment: Studio's JDK, with trust added to its options. */
function sdkmanagerEnv(trust: string): Record<string, string | undefined> {
  const jdk = studioJdk() ?? fail("Android Studio not found (its bundled JDK runs sdkmanager)");
  const opts = `${process.env.SDKMANAGER_OPTS ?? ""} ${trust}`.trim();
  return { ...process.env, JAVA_HOME: jdk, SDKMANAGER_OPTS: opts };
}

const DOWNLOAD_FAILED = /Failed to download any source lists|IO exception while downloading/;

/**
 * Installs ids with sdkmanager, on the terminal: its progress shows, and a
 * license it hasn't been told to accept asks there.
 */
export async function sdkmanagerInstall(sdk: string, ids: string[]) {
  for (const [i, trust] of TRUST.entries()) {
    if (i > 0) console.error("sdkmanager couldn't download: retrying with the login keychain's certificates");
    const child = Bun.spawn([sdkmanagerPath(sdk), `--sdk_root=${sdk}`, ...ids], {
      env: sdkmanagerEnv(trust),
      stdio: ["inherit", "inherit", "inherit"],
    });
    if ((await child.exited) === 0) return;
  }
  throw new Error(`sdkmanager couldn't install ${ids.join(" ")}`);
}

/** Every ID sdkmanager knows, installed or not, from its tables' first column. */
export async function knownIds(sdk: string): Promise<Set<string>> {
  let list = "";
  for (const trust of TRUST) {
    list = await out($`${sdkmanagerPath(sdk)} --sdk_root=${sdk} --list 2>&1`.env(sdkmanagerEnv(trust)));
    if (!DOWNLOAD_FAILED.test(list)) break;
  }
  return new Set(
    list
      .split("\n")
      .filter((line) => line.includes("|"))
      .map((line) => line.split("|")[0].trim())
      .filter(Boolean),
  );
}
