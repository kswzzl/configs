function gb --description 'Fuzzy‑switch local branch'
    set branch (command git for-each-ref --format='%(refname:short)' refs/heads \
                | command sort -u \
                | fzf --prompt="local> " --height=40%)

    if test -z "$branch"
        return
    end

    command git switch $branch
end
