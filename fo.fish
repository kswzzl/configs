function fo --description 'fzf‑open file in $EDITOR'
    set file (rg --files --hidden --follow --glob '!.git/*' \
              | _fzf_popup --prompt="file> " \
                           --preview='bat --style=numbers --color=always {} | head -100')
    test -n "$file"; and $EDITOR $file
end
