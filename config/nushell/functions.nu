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

def "nu-complete nixos" [] {
    [switch test build]
}

export def nixos [
    --flake (-f): path = "."        # Path to used flake
    cmd: string@"nu-complete nixos" # Command to run
    ...extra_args: string           # Extra args passed to nixos-rebuild
] {
    let valid_cmds = (nu-complete nixos)
    if $cmd in $valid_cmds {
        ^sudo nixos-rebuild --flake $flake $cmd
    } else {
        let span = (metadata $cmd).span
        error make {
            msg: ("Invalid cmd, must be one of " + ($valid_cmds | str join ', '))
            label: {
                text: "This command argument"
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
