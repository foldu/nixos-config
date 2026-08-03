# Home network topology

For a description of all relevant hosts see home-network.toml

## Layout

- **LAN**: `192.168.8.0/24`, gateway + DNS `192.168.8.1` — a GL.iNet **Flint 2** (GL-MT6000) consumer router; and an 2.5G switch, setting the baseline at 2.5G (saturn/jupiter have 10G links beyond it)
- **Mesh VPN**: Netbird, interface `wt0`, subnet `172.25.74.0/24`
- **DNS**: `*.home.5kw.li` records resolve to netbird IPs (`172.25.74.x`). Host descriptions and addresses live in `home-network.toml`.
