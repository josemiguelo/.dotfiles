# Locate the Android SDK directory, tolerating case differences (Sdk vs sdk)
# across machines/installations.
for _android_sdk_dir in "$HOME/Library/Android"/[Ss]dk(N); do
  if [[ -d "$_android_sdk_dir" ]]; then
    export ANDROID_HOME="$_android_sdk_dir"
    export ANDROID_SDK_ROOT="$_android_sdk_dir"
    break
  fi
done
unset _android_sdk_dir

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
