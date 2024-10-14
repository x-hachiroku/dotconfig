export TERM=${TERM:-xterm-256color}
export COLORTERM=truecolor

export GREP_COLORS='mt=103'


export GOPATH=$HOME/.local/share/go
export CARGO_HOME=$HOME/.local/share/cargo

typeset -U path
path=(
    "$HOME/.local/bin"
    "$GOPATH/bin"
    "$CARGO_HOME/bin"
    "$HOME/.local/share/npm/bin"
    $path
)


preexec() {
    print -Pn "\e]133;C\e\\"
    PREEXEC_CALLED=1
}
precmd() {
    local ret=$?
    print -Pn "\e]133;D;${ret}\e\\"

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
    PROMPT=$'%{\e]133;A\e\\%}'$PROMPT$'%{\e]133;B\e\\%}'
    PREEXEC_CALLED=0
}


setopt CSH_NULL_GLOB

DIRSTACKSIZE=8
setopt AUTOPUSHD PUSHDMINUS PUSHDSILENT PUSHDTOHOME PUSHDIGNOREDUPS

HISTSIZE=65536
SAVEHIST=65536
HISTFILE="${HOME}/.zsh_history"
HISTORY_IGNORE='man*|cat*|rmdir*|rar*|unrar*|zip*|unzip*|7z*'

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
    if ssh-keygen -y -P '' -f ~/.ssh/id_ed25519 >/dev/null 2>&1; then
        ssh-add ~/.ssh/id_ed25519
    fi
fi


if [[ ! -v TMUX ]] && [[ ! -v NO_TMUX ]]; then
    exec tmux new-session -A -s $HOST
fi
unset NO_TMUX 2>/dev/null
