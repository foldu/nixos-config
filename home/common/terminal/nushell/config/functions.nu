export def edit-link [
    path: path # Link to edit
] {
    let type = ($path | path type)
    if $type == 'symlink' {
        # FIXME: use mktemp instead
        let tmppath = ($path | path parse | upsert stem $".($in.stem).tmp" | path join)
        open --raw $path | save $tmppath
        rm $path
        mv $tmppath $path
    } else {
        let span = (metadata $path).span
        error make {
            msg: "Path is not a symlink"
            label: {
                text: "This path argument"
                start: $span.start
                end: $span.end
            }
        }
    }
}


export def tmp-clone [
    url: string # Link to git thing
] {
    let cleaned = ($url | parse -r '(?<url>^https?://[^/]+/[^/]+/(?<repo>[^/]+))' | first)
    if $cleaned != null {
        cd /tmp
        ^git clone $cleaned.url
        # How do I auto cd there? The (nice) scoping prevents me from 
        # influencing the current shell pwd
        echo $"Cloned to /tmp/($cleaned.repo)"
    } else {
        let span = (metadata $url).span
        error make {
            msg: "Can't parse repo url"
            label: {
                text: "This url argument"
                start: $span.start
                end: $span.end
            }
        }
    }
}

def "nu-complete flake-update" [] {
    ^nix flake metadata --json
    | from json
    | get locks.nodes.root.inputs
    | columns
}

export def flake-update [
    --no-commit (-n) = false               # Don't commit the new lockfile
    ...inputs: string@"nu-complete flake-update" # Flake inputs you want to update
] {
    let args = (
        $inputs 
        | reduce -f [] {|it, acc| $acc ++ ["--update-input" $it] } 
        | (if $no_commit { $in } else { $in | prepend "--commit-lock-file" })
    )

    ^nix flake lock $args
}

export def unix-seconds-to-date [] {
    $in * 10e8 | into datetime
}

export def date-to-unix-seconds [] {
    $in / 10e8 | math floor | into int
}
