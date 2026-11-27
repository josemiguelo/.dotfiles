# This repo, unless .zshenv named a child repo of it (~/.config/loadout/repo).
export LOADOUT_REPO=${LOADOUT_REPO:-~/.local/share/chezmoi}
alias sdc='start-dotfiles-change'

# loadout's commands: ldt is loadout; machine's verbs are one letter
# (ldts machine status, ldtsy machine sync), the rest the noun's initial and
# the verb's (ldtsr script run, ldtca config apply). Arguments pass through.
alias ldt='loadout'
alias ldtn='loadout machine new'
alias ldts='loadout machine status'
alias ldtsy='loadout machine sync'
alias ldto='loadout machine outdated'
alias ldtd='loadout machine diff'
alias ldte='loadout machine explain'
alias ldtc='loadout repo compile'
alias ldtpi='loadout program install'
alias ldtpe='loadout program explain'
alias ldtsr='loadout script run'
alias ldtsc='loadout script check'
alias ldtse='loadout script explain'
alias ldtca='loadout config apply'
alias ldtce='loadout config explain'
alias ldtil='loadout installer list'
alias ldtiu='loadout installer upgrade'
alias ldtcz='loadout chezmoi'
alias ldtu='loadout self upgrade'
