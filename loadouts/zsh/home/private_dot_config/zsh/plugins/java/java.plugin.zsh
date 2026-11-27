(( $+commands[java] )) || return

# mise exports JAVA_HOME itself for the java in use.

# tomcat has no CATALINA_HOME of its own under mise; asking `mise which` forks
# mise on every startup, so cache the result and refresh it when the installs
# change. CATALINA_HOME is the directory above catalina.sh's bin/.
_tomcat_installs="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/installs/tomcat"
if [[ -d $_tomcat_installs ]]; then
  _catalina_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init/catalina.zsh"
  if [[ ! -s $_catalina_cache || $_tomcat_installs -nt $_catalina_cache ]]; then
    [[ -d ${_catalina_cache:h} ]] || mkdir -p ${_catalina_cache:h}
    _catalina_sh=$(mise which catalina.sh 2>/dev/null)
    if [[ -n $_catalina_sh ]]; then
      {
        print -r -- "export CATALINA_HOME=${(q)${_catalina_sh:h:h}}"
        # CATALINA_BASE is the instance dir (conf/, bin/setenv.sh, logs/,
        # webapps/, temp/, work/) kept outside the mise-managed CATALINA_HOME
        # so a `mise install tomcat --force`/version bump never wipes it;
        # setenv.sh -- and any secrets in it -- stays out of chezmoi too.
        print -r -- "export CATALINA_BASE=${(q)${XDG_STATE_HOME:-$HOME/.local/state}}/tomcat/${(q)${${_catalina_sh:h:h:h}:t}}"
      } >| $_catalina_cache
    fi
    unset _catalina_sh
  fi
  [[ -s $_catalina_cache ]] && source $_catalina_cache
  unset _catalina_cache
fi
unset _tomcat_installs

# Gradle doesn't look in mise's installs for toolchains; ~/.gradle/gradle.properties
# reads them from JDK<major>_HOME (org.gradle.java.installations.fromEnv): one per
# Java version mise installed, the newest of each, whatever the vendor. A glob, not
# `mise ls`, so startup doesn't fork mise; (/) leaves out mise's alias links
# (temurin-17, zulu-latest). The version follows the vendor (temurin-17.0.7+7,
# zulu-8.78.0.19); an old-style 1.8.0 is Java 8.
_jdks=()
for _jdk in "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"/installs/java/*(/N); do
  _jdk_version=${${_jdk:t}##*-}
  [[ $_jdk_version == [0-9]* ]] && _jdks+=("$_jdk_version $_jdk")
done
# Oldest first, numbers compared as numbers (17.0.20 after 17.0.7), so the newest is exported last.
for _jdk in ${(on)_jdks}; do
  _jdk_version=${${_jdk%% *}#1.}
  export "JDK${_jdk_version%%[^0-9]*}_HOME=${_jdk#* }"
done
unset _jdk _jdks _jdk_version
