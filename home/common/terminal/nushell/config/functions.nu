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
    [switch test build copy-configs gc deploy]
}

export def nixos [
    --flake (-f): path = "."        # Path to used flake
    cmd: string@"nu-complete nixos" # Command to run
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

def get-home-network [] {
    try {
        let root = (git rev-parse --show-toplevel)
        open $"$(root)/home-network.nix"
    } catch {
        open "./home-network.toml"
    }
}

def "nu-complete nixos copy-configs" [] {
    try {
        get-home-network
        | get devices
        | transpose device
        | get device
    } catch {
        []
    }
}

export def "nixos deploy" [
    device: string@"nu-complete nixos copy-configs"
] {
    let host = (try { 
        get-home-network
        | get devices
        | get $device
        | get dns
    } catch {
        let span = (metadata $device).spawn
        error make {
            msg: "Device not found in ./home-network"
            label: {
                text: "This device argument"
                start: $span.start
                end: $span.end
            }
        }
    })
    nixos-rebuild switch --target-host $host --flake $".#($device)" --use-remote-sudo
}

export def "nixos copy-configs" [
    device?: string@"nu-complete nixos copy-configs"
] {
    copy-configs "./home-network.toml" $device
}

def copy-configs [network: path, device?: string] {
    let me = (hostname)

    if $me == $device {
        error make { msg: "Refusing to copy config to myself" }
    }

    let meta = (open $network | get "devices" | transpose "name" "meta" | where "name" != $me)
    let to_update = (if $device == null {
        $meta
    } else {
        let device_meta = (try {
            $meta
            | where "name" == $device
            | first
        } catch {
            error make { msg: $"Unknown device ($device)" }
        })

        [$device_meta]
    })

    for dev in $to_update {
        copy-config $dev.name $dev.meta.dns
    }
}

def copy-config [name: string, ip: string] {
    echo $"Updating ($name)"
    ^rsync -azvP --exclude .direnv ./ $"($ip):nixos-config/"
}

export def "nixos gc" [
    timeframe: string = "7d" # Garbage collect everything older than this (see man nix-collect-garbage for format)
] {
    ^sudo nix-collect-garbage --older-than $timeframe
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
    --no-commit (-n): bool = false               # Don't commit the new lockfile
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