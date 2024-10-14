export TERM='xterm-256color'
export PATH=$HOME/.local/bin:$PATH:$HOME/go/bin

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


DIRSTACKSIZE=8
setopt AUTOPUSHD PUSHDMINUS PUSHDSILENT PUSHDTOHOME PUSHDIGNOREDUPS


HISTSIZE=65536
SAVEHIST=65536
HISTFILE="${HOME}/.zsh_history"
HISTORY_IGNORE='ls*|echo*|unrar*|unzip*|7z*'

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


source $HOME/.config/zsh/modules/prezto/init.zsh
for rc in $HOME/.config/zsh/rc.d/*.zsh; do source $rc; done

fpath=($HOME/.config/zsh/functions $fpath)


__conda_setup="$('~/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then eval "$__conda_setup"; fi
unset __conda_setup
