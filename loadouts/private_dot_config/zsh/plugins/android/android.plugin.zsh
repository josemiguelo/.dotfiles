# The SDK directory Android Studio manages, as the android-sdk loadout script
# finds it: ~/.local/lib/android-sdk-dir.sh decides it for both.
[[ -r "$HOME/.local/lib/android-sdk-dir.sh" ]] && source "$HOME/.local/lib/android-sdk-dir.sh"
if [[ -n "$ANDROID_SDK_DIR" ]]; then
  export ANDROID_HOME="$ANDROID_SDK_DIR"
  export ANDROID_SDK_ROOT="$ANDROID_SDK_DIR"
fi
unset ANDROID_SDK_DIR

if [[ -n "$ANDROID_HOME" ]]; then
  export PATH=${PATH}:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/emulator:${ANDROID_HOME}/cmdline-tools/latest/bin

  # Pick the highest installed build-tools version rather than hardcoding it.
  if [[ -d "$ANDROID_HOME/build-tools" ]]; then
    _android_build_tools=("$ANDROID_HOME"/build-tools/*(/Nn))
    if ((${#_android_build_tools})); then
      export PATH=${PATH}:${_android_build_tools[-1]}
    fi
    unset _android_build_tools
  fi
fi
