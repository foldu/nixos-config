{ pkgs, ... }: {
  services.printing = {
    enable = true;
    drivers = [
      pkgs.foo2zjs
    ];
    defaultShared = true;
    allowFrom = [
      "localhost"
      "print.home.5kw.li"
    ];
    listenAddresses = [
      "localhost:631"
      "print.home.5kw.li:631"
    ];
    startWhenNeeded = false;
  };

  networking.firewall.allowedTCPPorts = [ 631 ];
}
