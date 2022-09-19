#!/usr/bin/env bash
set -euo pipefail

die() {
    echo "$@"
    exit 1
}

progname=$(basename "$0")

usage() {
    msg=$(
        cat <<EOF
Usage: ${progname} -c|--cmd CMD -w|--windowclass WINDOWCLASS -n|--name NAME

CMD: Command to execute
WINDOWCLASS: X Window class of program executed by CMD
NAME: Unique per program name
EOF
    )
    die "$msg"
}

long='windowclass:,name:,cmd:'
short='w:n:c:'
parsed_opt=$(getopt --options "$short" --longoptions "$long" --name "$progname" -- "$@")

eval set -- "$parsed_opt"

window_class=
name=
cmd=
while true; do
    case "$1" in
    -w | --windowclass)
        window_class="$2"
        shift 2
        ;;
    -n | --name)
        name="$2"
        shift 2
        ;;
    -c | --cmd)
        cmd="$2"
        shift 2
        ;;
    --)
        shift
        break
        ;;
    *)
        die "Unhandled argument $1"
        ;;
    esac
done

if test -z "$window_class" || test -z "$name" || test -z "$cmd"; then
    usage
fi

pid_dir="/run/user/$UID/xfloat"
mkdir -p -- "$pid_dir"
pid_file="$pid_dir/$name.pid"

pid=$(xdotool search --class "$window_class" || true)
if test -z "$pid"; then
    $cmd
    exit 0
fi

if test -f "$pid_file"; then
    old_pid=$(cat "$pid_file")
    # if it crashed or something "$pid" != "$old_pid"
    # so it makes sense just to fall through and overwrite
    # the pid file
    if [[ "$old_pid" -eq "$pid" ]]; then
        xdotool windowmap "$pid"
        rm -- "$pid_file"
        exit 0
    fi
fi

echo "$pid" >"$pid_file"
xdotool windowunmap "$pid"
