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
    [switch test build copy-configs gc]
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

def "nu-complete nixos copy-configs" [] {
    try {
        open "./home-network.toml"
        | get devices
        | transpose device
        | get device
    } catch {
        []
    }
}

export def "nixos copy-configs" [
    device?: string@"nu-complete nixos copy-configs"
] {
    copy-configs "./home-network.toml" $device
}

def copy-configs [network: path, device?: string] {
    let meta = (open $network | get devices)
    if $device == null {
        $meta
        | transpose name ips 
        | each {|dev|
            copy-config $dev.name $dev.ips.vip
        }
    } else {
        let device_meta = (try { $meta | get $device } catch { error make { msg: $"Unknown device ($device)" }})
        copy-config $device_meta.name $device_meta.ips.vip
    }
}

def copy-config [name: string, ip: string] {
    echo $"Updating ($name)"
    ^rsync -azvP ./ $"($ip):nixos-config/"
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
