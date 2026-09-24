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
      print -r -- "export CATALINA_HOME=${(q)${_catalina_sh:h:h}}" >| $_catalina_cache
    fi
    unset _catalina_sh
  fi
  [[ -s $_catalina_cache ]] && source $_catalina_cache
  unset _catalina_cache
fi
unset _tomcat_installs
