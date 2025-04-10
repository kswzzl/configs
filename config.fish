if test -d ~/.pyenv
    #status is-interactive; and pyenv init --path | source
    pyenv init - | source
end

if test -d ~/bin
    set -x PATH $PATH ~/bin
end

alias vi nvim

if test -e ~/.config/fish/config.fish.local
    source ~/.config/fish/config.fish.local
end
