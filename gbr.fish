function gbr --description 'Fuzzy‑checkout remote branch (creates local tracking branch)'
    echo "Fetching remote branches..."
    command git fetch --all --prune &

    set branch (command git for-each-ref --format='%(refname:short)' refs/remotes/origin \
                | command grep -v '^origin/HEAD$' \
                | command sed 's|^origin/||' \
                | command sort -u \
                | _fzf_popup --prompt="remote> ")

    test -z "$branch"; and return

    command git switch -c $branch origin/$branch 2>/dev/null
    if test $status -eq 128
        command git switch $branch
    end
end
