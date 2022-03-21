function tmp-clone
    if test $(count $argv) = 1 && set match $(string match -r '^(https?://github.com/[^/]+/([^/]+))' $argv[1])
        set url "$match[1]"
        set repo_name "$match[2]"
        set tmp_dir "/tmp/$repo_name"
        if test -d "$tmp_dir"
            echo "Already cloned"
        else
            git clone --depth 1 "$url" "$tmp_dir" || return 1
        end
        cd "$tmp_dir"
    else
        echo "Usage: tmp-clone GITHUB_REPO"
    end
end
