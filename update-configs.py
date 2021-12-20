#!/usr/bin/env python3
import toml
from subprocess import run
import os


def main():
    with open("home-network.toml") as fh:
        home_network = toml.load(fh)
    hostname = os.uname().nodename
    abs_cwd = os.path.abspath(".") + "/"
    updated_fqdns = []
    for device in home_network["devices"].keys():
        if hostname != device:
            fqdn = f"{device}.nebula.5kw.li"
            run(["rsync", "-avP", abs_cwd, f"{fqdn}:nixos-config/"])
            updated_fqdns.append(fqdn)

    # cmd = ["tmux", "new-session"]
    # for fqdn in updated_fqdns:
    #    cmd.append(
    #        f"ssh {fqdn} doas nixos-rebuild switch --flake /home/barnabas/nixos-config ; read"
    #    )
    #    cmd += [";", "split-window"]
    # cmd.pop()
    # cmd += ["select-layout", "even-vertical"]
    # run(cmd)


if __name__ == "__main__":
    main()
