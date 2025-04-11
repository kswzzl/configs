if test -d ~/.pyenv
    pyenv init - | source
end

if test -d ~/bin
    set -x PATH $PATH ~/bin
end

if command -v zoxide >/dev/null
    zoxide init fish --cmd cd | source
end

if command -v nvim >/dev/null
    alias vi nvim
    alias vim nvim
    set -gx EDITOR nvim
end

if command -v fzf >/dev/null
    set -gx FZF_DEFAULT_OPTS "--height=80% --border --layout=reverse --info=inline"
end

if command -v bat>/dev/null
    alias cat bat
end

if test -e ~/.config/fish/config.fish.local
    source ~/.config/fish/config.fish.local
end
