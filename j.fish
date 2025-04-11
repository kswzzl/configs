function j --description 'cd into a recently used dir (z‑like)'
    set dir (zoxide query -l \
              | _fzf_popup --prompt="dir> " --tac --preview='ls -Ah {} | head')
    test -n "$dir"; and cd $dir
end
