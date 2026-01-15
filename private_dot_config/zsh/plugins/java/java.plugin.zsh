if (( $+commands[java] )); then
    [[ -f "$HOME/.asdf/plugins/java/set-java-home.zsh" ]] && . ~/.asdf/plugins/java/set-java-home.zsh
    [[ -f "$HOME/.asdf/plugins/tomcat/set-catalina-home.sh" ]] && . ~/.asdf/plugins/tomcat/set-catalina-home.sh
fi
