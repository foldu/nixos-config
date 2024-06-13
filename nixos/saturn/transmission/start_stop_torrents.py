#!/usr/bin/env python3

import transmission_rpc
import os
import sys


def main():
    url = os.getenv("TRANSMISSION_URL")
    action = os.getenv("ACTION")
    assert url is not None
    assert action is not None
    client = transmission_rpc.from_url(url)
    match action:
        case "start-all":
            client.start_all()
        case "stop-all":
            client.stop_torrent(ids=[torrent.id for torrent in client.get_torrents()])
        case _:
            print(f"Unknown command {action}")
            sys.exit(1)


if __name__ == "__main__":
    main()
