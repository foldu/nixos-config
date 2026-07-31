# Home network topology

## Layout

- **LAN**: `192.168.8.0/24`, gateway + DNS `192.168.8.1` — a GL.iNet **Flint 2** (GL-MT6000) consumer router; and an 2.5G switch, setting the baseline at 2.5G (saturn/jupiter have 10G links beyond it)
- **Mesh VPN**: Netbird, interface `wt0`, subnet `172.25.74.0/24`
- **DNS**: `*.home.5kw.li` records resolve to netbird IPs, e.g.
  `lab.home.5kw.li` and `saturn.home.5kw.li` both point at `172.25.74.33`.
   Most services are only reachable over netbird, not LAN.

## Hosts
See home-network.toml
