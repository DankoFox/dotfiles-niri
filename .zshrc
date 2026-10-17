# --- History Configuration ---
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-/:toggle-preview'"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY          # Add to history, don't overwrite
setopt SHARE_HISTORY           # Share history between all open tabs
setopt HIST_IGNORE_ALL_DUPS    # Don't record the same command twice
setopt HIST_REDUCE_BLANKS      # Remove extra blanks from commands

# Tools initialization
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# Zsh plugins
[[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Local bin in PATH
export PATH="$HOME/.local/bin:$PATH"
