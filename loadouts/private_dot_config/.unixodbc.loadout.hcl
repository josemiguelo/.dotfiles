# unixodbc: a library, not a tool; usql links against it.

# usql (a work repo's bootstrap-env.sh) links against it at a fixed path;
# without it usql dies with a dyld error.
program "unixodbc" {
  install_via = [brew]
}
