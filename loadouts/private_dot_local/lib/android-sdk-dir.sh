# The Android SDK directory Android Studio manages, the one place that decides
# it. Sourced, not run (sh, bash and zsh all read it): loadout's scripts from
# the repo, as "$LOADOUT_REPO/loadouts/private_dot_local/lib/android-sdk-dir.sh"
# (on a fresh machine they run before the dotfiles are applied), zsh's android
# plugin from ~/.local/lib/android-sdk-dir.sh. Sets ANDROID_SDK_DIR to the first
# that exists, empty when none does: where Studio puts it on macOS
# (~/Library/Android), then on Linux (~/Android), Sdk before sdk in each, since
# the case differs across installs (a glob would sort by the locale, which puts
# sdk first on Linux).
ANDROID_SDK_DIR=
for _android_sdk_dir in "$HOME/Library/Android/Sdk" "$HOME/Library/Android/sdk" "$HOME/Android/Sdk" "$HOME/Android/sdk"; do
  if [ -d "$_android_sdk_dir" ]; then
    ANDROID_SDK_DIR=$_android_sdk_dir
    break
  fi
done
unset _android_sdk_dir
