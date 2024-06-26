def "nu-complete nixos" [] {
    [switch test build copy-configs gc deploy]
}

export def main [
    --flake (-f): path = "."        # Path to used flake
    cmd: string@"nu-complete nixos" # Command to run
] {
    let valid_cmds = (nu-complete nixos)
    if $cmd in $valid_cmds {
        ^sudo nixos-rebuild --flake $flake $cmd --print-build-logs
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

export def deploy [
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

export def copy-configs [
    device?: string@"nu-complete nixos copy-configs"
] {
    copy-configs-impl "./home-network.toml" $device
}

def copy-configs-impl [network: path, device?: string] {
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
    ^rsync -azvP --exclude .direnv ./ $"($ip):src/github.com/foldu/nixos-config/"
}

export def gc [
    timeframe: string = "30d" # Garbage collect everything older than this (see man nix-collect-garbage for format)
] {
    ^home-manager expire-generations $"-($timeframe)ays"
    ^sudo nix-collect-garbage --delete-older-than $timeframe
}
