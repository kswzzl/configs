function _fzf_popup
    if set -q TMUX
        fzf-tmux -p 80%,80% $argv
    else
        fzf --height=80% --border --layout=reverse --info=inline $argv
    end
end
