export TERM='xterm-256color'

export GOPATH=$HOME/.local/share/go

if [[ ":$PATH:" != *":$GOPATH:"* ]]; then export PATH="$PATH:$GOPATH"; fi
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then export PATH="$HOME/.local/bin:$PATH"; fi
if [[ ":$PATH:" != *":$HOME/.local/share/npm/bin:"* ]]; then export PATH="$PATH:$HOME/.local/share/npm/bin"; fi


preexec() { PREEXEC_CALLED=1 }
precmd() {
    local ret=$?
    if [[ -v VIRTUAL_ENV ]] || [[ -v CONDA_DEFAULT_ENV ]]; then
        if [[ -v CONDA_DEFAULT_ENV ]]; then VIRTUAL_ENV_PROMPT=${CONDA_DEFAULT_ENV}
        else VIRTUAL_ENV_PROMPT=${${VIRTUAL_ENV%/*}##*/}; fi
        local pyvenv="%F{25}<${VIRTUAL_ENV_PROMPT}>%f%U%(3~|.../%2~|%~)%u"
    else
        local pyvenv="%F{25}|%f%U%(4~|.../%3~|%~)%u"
    fi
    if [[ "$ret" != 0 ]] && [[ "$PREEXEC_CALLED" = 1 ]]; then
        PROMPT="%B%F{88}[%F{202}%S%m%s%f%b${pyvenv}%B%F{88}]%f%b "
    else
        PROMPT="%B%F{34}[%F{245}%S%m%s%f%b${pyvenv}%B%F{34}]%f%b "
    fi
    PREEXEC_CALLED=0
}


setopt CSH_NULL_GLOB


DIRSTACKSIZE=8
setopt AUTOPUSHD PUSHDMINUS PUSHDSILENT PUSHDTOHOME PUSHDIGNOREDUPS


HISTSIZE=65536
SAVEHIST=65536
HISTFILE="${HOME}/.zsh_history"
HISTORY_IGNORE='man*|cat*|rar*|unrar*|zip*|unzip*|7z*'

setopt EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_FIND_NO_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt BANG_HIST HIST_VERIFY


zstyle ':prezto:load' pmodule \
        'utility' \
        'terminal' \
        'environment' \
        'autosuggestions' \
        'syntax-highlighting' \
        'history-substring-search' \
        'completion'

zstyle ':prezto:*:*' color 'yes'
zstyle ':prezto:module:utility' correct 'no'
zstyle ':prezto:module:syntax-highlighting' highlighters \
        'main' \
        'brackets' \
        'pattern' \
        'regexp'

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'


# source env_parallel.zsh &>/dev/null
source $HOME/.config/zsh/modules/prezto/init.zsh
for rc in $HOME/.config/zsh/rc.d/*.zsh; do source $rc; done


if ! ssh-add -L &> /dev/null; then
    if ! pgrep -u "$USER" ssh-agent &> /dev/null; then
        (umask 0077; ssh-agent > "${XDG_RUNTIME_DIR:-$HOME}/.ssh-agent.env")
    fi
    source "${XDG_RUNTIME_DIR:-$HOME}/.ssh-agent.env" &> /dev/null
    ssh-add ~/.ssh/id_ed25519 &>/dev/null
fi


if [[ -z "$TMUX" ]] && [[ -n "$SSH_TTY" ]]; then
    tmux attach-session -t ssh 2>/dev/null || tmux new-session -s ssh 'archey; zsh'
fi
