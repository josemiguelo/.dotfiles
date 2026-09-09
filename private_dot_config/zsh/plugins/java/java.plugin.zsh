(( $+commands[java] )) || return

[[ -f "$HOME/.asdf/plugins/java/set-java-home.zsh" ]] && . ~/.asdf/plugins/java/set-java-home.zsh

# tomcat's set-catalina-home.sh forks `asdf which catalina.sh` plus an echo|sed
# on every startup; cache the result and refresh it when the installs change
if [[ -f "$HOME/.asdf/plugins/tomcat/set-catalina-home.sh" ]]; then
  _catalina_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init/catalina.zsh"
  if [[ ! -s $_catalina_cache || $HOME/.asdf/installs/tomcat -nt $_catalina_cache ]]; then
    [[ -d ${_catalina_cache:h} ]] || mkdir -p ${_catalina_cache:h}
    ( . "$HOME/.asdf/plugins/tomcat/set-catalina-home.sh"
      [[ -n $CATALINA_HOME ]] && print -r -- "export CATALINA_HOME=${(q)CATALINA_HOME}"
    ) >| $_catalina_cache
  fi
  source $_catalina_cache
  unset _catalina_cache
fi
