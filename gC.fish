function gC --description 'Fuzzy‑checkout remote branch (creates local tracking branch)'
    # Always pull the latest refs in the background so fzf shows fresh data
    #command git fetch --all --prune &

    # Build a clean list of origin/* branches, drop the origin/ prefix,
    # pipe into fzf, and capture the chosen branch name.
    set branch (command git for-each-ref --format='%(refname:short)' refs/remotes/origin \
                | command grep -v '^origin/HEAD$' \
                | command sed 's|^origin/||' \
                | command sort -u \
                | fzf --prompt="remote> " --height=40%)

    # Bail out if the user hit <Esc> or the list was empty
    if test -z "$branch"
        return
    end

    # Try to create a new local branch that tracks the remote
    command git switch -c $branch origin/$branch 2>/dev/null

    # If it already exists, just switch to it
    if test $status -eq 128
        command git switch $branch
    end
end
