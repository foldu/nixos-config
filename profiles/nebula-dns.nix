{ pkgs, ... }: {
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "1.1.1.1" "1.0.0.1" "9.9.9.9" ];
  };

  systemd.services."nebula-resolve" = {
    enable = true;
    after = [ "nebula@evil.service" ];
    partOf = [ "nebula@evil.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    # FIXME: bad
    script = ''
      sleep 0.25
      resolvectl domain nebula.evil '~nebula.5kw.li'
      resolvectl dns nebula.evil 192.168.100.1
    '';
  };
}
