# shellcheck shell=sh
# Sourced by demo.tape from the repository root: stages the demo
# world and starts the shell at home, outside any session.
sh demo/setup.sh
export ZP_ROOT=/tmp/zp-demo/src
export PATH="$PWD:$PWD/demo/bin:$PATH"
export HOME=/tmp/zp-demo
# The render may itself run inside a real zmx session; the demo
# starts outside any, so drop the inherited session environment.
unset ZMX_SESSION ZMX_SESSION_PREFIX
export PS1='\n\w \[\e[38;2;250;179;135m\]❯\[\e[0m\] '
cd "$HOME" || return
