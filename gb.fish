function gb --description 'Fuzzy‑switch local branch (popup)'
    set branch (command git for-each-ref --format='%(refname:short)' refs/heads \
                | command sort -u \
                | _fzf_popup --prompt="local> ")

    test -z "$branch"; and return
    command git switch $branch
end
