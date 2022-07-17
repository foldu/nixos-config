#!/usr/bin/env python3
import toml
from plumbum.cmd import rsync
import os
from argparse import ArgumentParser
from dataclasses import dataclass
from typing import Any
from sys import exit


def main():
    parser = ArgumentParser()
    parser.add_argument("host", default=None, type=str, nargs="?")
    args = parser.parse_args()

    with open("home-network.toml") as fh:
        home_network = toml.load(fh)

    hostname = os.uname().nodename
    abs_cwd = os.path.abspath(".") + "/"

    context = Context(hostname=hostname, abs_cwd=abs_cwd, home_network=home_network)

    if args.host is None:
        copy_to_all(context)
    else:
        copy_to(context, args.host)


@dataclass
class Context:
    home_network: Any
    hostname: str
    abs_cwd: str


# cmd = ["tmux", "new-session"]
# for fqdn in updated_fqdns:
#    cmd.append(
#        f"ssh {fqdn} doas nixos-rebuild switch --flake /home/barnabas/nixos-config ; read"
#    )
#    cmd += [";", "split-window"]
# cmd.pop()
# cmd += ["select-layout", "even-vertical"]
# run(cmd)


def copy_to_all(ctx: Context):
    updated_fqdns = []
    for device in ctx.home_network["devices"].keys():
        if ctx.hostname != device:
            fqdn = rsync_to_device(ctx, device)
            updated_fqdns.append(fqdn)


def copy_to(ctx: Context, dest: str):
    if dest in ctx.home_network["devices"]:
        rsync_to_device(ctx, dest)
    else:
        exit(f"Unknown host {dest}")


def rsync_to_device(ctx: Context, dest: str) -> str:
    fqdn = f"{dest}.home.5kw.li"
    rsync("-avP", "--exclude", "result", ctx.abs_cwd, f"{fqdn}:nixos-config/")
    return fqdn


if __name__ == "__main__":
    main()
