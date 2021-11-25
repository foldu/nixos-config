# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files source by it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Automaticaly wrap TTY with a transparent tmux ('integrated'), or start a
# full-fledged tmux ('system'), or do nothing ('no').
zstyle ':z4h:' start-tmux       'no'
# Move prompt to the bottom when zsh starts and on Ctrl+L. Has no effect if
# not running under tmux.
zstyle ':z4h:' prompt-at-bottom 'no'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'pc'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# ssh when connecting to these hosts.
#zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
#zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

# Send these files over to the remote host when connecting over ssh to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
#z4h install ohmyzsh/ohmyzsh || return
z4h install hlissner/zsh-autopair || return
z4h install momo-lab/zsh-abbrev-alias || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Extend PATH.
path=($path)

# Export environment variables.
export GPG_TTY=$TTY

# Source additional local files if they exist.
z4h source ~/.env.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
#z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
#z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin
z4h load hlissner/zsh-autopair
z4h source momo-lab/zsh-abbrev-alias/abbrev-alias.plugin.zsh

# Define key bindings.
z4h bindkey z4h-backward-kill-word  Ctrl+Backspace Ctrl+H
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace

z4h bindkey undo Ctrl+/  # undo the last command line change
z4h bindkey redo Alt+/   # redo the last undone command line change

z4h bindkey z4h-cd-back    Alt+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Alt+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Alt+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Alt+Down   # cd into a child directory

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

function edit-link() {
    if [[ $# == 1 ]]; then
        if test -L "$1" && test -f "$1"; then
            local tempfile=$(mktemp -- "$(dirname "$1")/XXXXXX")
            cat -- "$1" > "$tempfile"
            mv -f -- "$tempfile" "$1"
            "${EDITOR:-vi}" "$1"
        else
            echo "$1 is not a symlink to a file"
            return 1
        fi
    else
        echo "Usage: edit-link SYMLINK"
        return 1
    fi
}

function tmp-clone() {
    local match=$(echo "$1" | sed -E 's|^(https?://github.com/[^/]+/[^/]+).*|\1|')
    local repo_name=$(echo "$1" | sed -E  's|^https?://github.com/[^/]+/([^/]+).*|\1|')
    local tmp_dir="/tmp/${repo_name}"
    if [[ -d "$tmp_dir" ]]; then
        echo "Already cloned"
        cd "$tmp_dir"
    elif [[ -n "$match" ]]; then
        git clone --depth 1 "$match" "$tmp_dir" || return 1
        cd "$tmp_dir"
    else
        echo "Usage: tmp-clone GITHUB_REPO"
        return 1
    fi
}

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

# Define aliases.
alias tree='tree -a -I .git'
alias mv="mv -iv"
alias cp="cp -iv"
alias rm="rm -v"
alias rsync="rsync -av --info=progress2"
alias del-result="find . -type l -name result -delete"
abbrev-alias cdoc='cargo doc --no-deps --open -p'
abbrev-alias sudo=doas
abbrev-alias usv=systemctl --user
abbrev-alias sv=systemctl

# Add flags to existing aliases.
#alias ls="${aliases[ls]:-ls} -A"

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

eval "$(direnv hook zsh)"
