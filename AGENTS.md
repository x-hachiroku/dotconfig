This is the live Linux `$XDG_CONFIG_HOME` directory (`~/.config`), primarily for Arch Linux.

## Editing conventions

`.gitignore` ignores top-level entries by default and explicitly allows selected configuration directories.

Keep local overrides and generated state local. Keep the index focused on paths and responsibilities.

Do not modify submodules. Keep changes in this repository.

## Shell

Assume zsh for any shell operation. POSIX compatibility is not required.

`zsh/zshrc.zsh` sets the user PATH, loads Prezto, then sources `zsh/rc.d/*.zsh` in filename order. Place platform-
specific configuration in `zsh/systems/` and enable it through the corresponding `rc.d/` symlink. Keep machine-local
additions in local fragments.

Interactive shell always create/attach tmux, unless `NO_TMUX=1` is set.

## Terminals and tmux

Use kitty and Alacritty. Sync kitty configuration to Alacritty when changing shared appearance, key mappings, or
terminal behavior.

Prefer tmux for terminal operations, including windows/tabs, selection, and copy/paste. Keep terminal emulator functions
simple.

Prefer regular tmux bindings without a prefix. Use the prefix to escape and pass shortcuts through to nested tmux.

Terminal emulators swap Ctrl and Alt. After this translation, terminal/tmux shortcuts should only use Alt (`M-` in tmux),
and application shortcuts should only use Ctrl.

## Neovim and keyboard layout

The user uses Colemak. Prefer arrow keys for cursor movement in all applications with vim mode. `hjkl` may be mapped to other functions.

## utils

Standalone automation and helper scripts. Desigend for developmental use only.

Keep scripts in this dir simple. Choose simplist possible solution that solves the problem.

## Fresh installation

When asked to initialize a freshly installed system, ensure these tools are installed:

- 7z
- aria2
- GNU Parallel
- kitty
- Neovim, with Python and Node.js providers
- Podman
- ptpython
- rar, the official WinRAR CLI
- tmux

## Installing packages

Prefer package sources in this order:

1. System package manager. Use the maintainer's repository if it provides a significantly newer version.
2. `pipx`
3. AUR
4. User-level language specific package manager. Configure PATH in `zsh/zshrc.zsh`.
   If possible, set it's home dir under `$HOME/.local`.
5. Binary or AppImage from the maintainer, installed in `$HOME/.local/bin`.
