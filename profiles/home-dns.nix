{ config, lib, pkgs, ... }:
let
  blocklistPath = "/var/lib/unbound/blocklist.conf";
in
{
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  systemd =
    let
      blocklist = pkgs.writeText "blocklist" (
        builtins.toJSON {
          host_whitelist = [
            "play.googleapis.com"
          ];
          host_blacklist = [ ];
          blocklists = [
            # needs more blocklists
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "https://mirror1.malwaredomains.com/files/justdomains"
            "http://sysctl.org/cameleon/hosts"
            "https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://raw.githubusercontent.com/imkarthikk/pihole-facebook/master/pihole-facebook.txt"
            "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
            "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/extra.txt"
            "https://adaway.org/hosts.txt"
            "https://v.firebog.net/hosts/AdguardDNS.txt"
            "https://v.firebog.net/hosts/Easylist.txt"
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/data/UncheckyAds/hosts"
            "https://v.firebog.net/hosts/Easyprivacy.txt"
            "https://v.firebog.net/hosts/Prigent-Ads.txt"
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/data/add.2o7Net/hosts"
            "https://v.firebog.net/hosts/Airelle-trc.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
            "https://raw.githubusercontent.com/jmdugan/blocklists/master/corporations/pinterest/all"
            "https://raw.githubusercontent.com/jmdugan/blocklists/master/corporations/facebook/all"
            "https://raw.githubusercontent.com/jmdugan/blocklists/master/corporations/microsoft/all"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/shortlinksparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/proxiesparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/productsparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/mailparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/generalparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/fontsparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/firebaseparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/doubleclickparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/domainsparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/dnsparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/androidparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/analyticsparsed"
          ];
        }
      );
      cacheDir = "/var/cache/blocklists";
      user = "unbound";
    in
    {
      timers.blocklistdownloadthing = {
        wantedBy = [ "timers.target" ];
        partOf = [ "blocklistdownloadthing.service" ];
        timerConfig.OnCalendar = "daily";
      };
      services.blocklistdownloadthing = {
        after = [ "network.target" "systemd-tmpfiles-setup.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        wantedBy = [ "multi-user.target" ];
        script = ''
          ${pkgs.doas}/bin/doas -u unbound \
          ${pkgs.blocklistdownloadthing}/bin/blocklistdownloadthing \
              -o ${blocklistPath} \
              --cache "${cacheDir}" \
              --format unbound \
              --config "${blocklist}"
          systemctl restart unbound
        '';
      };
      tmpfiles.rules = [
        "d ${cacheDir} 755 ${user}"
      ];
    };

  services.unbound = {
    enable = true;
    allowedAccess = [ "127.0.0.0/8" "192.168.1.0/24" ];
    interfaces = [ "0.0.0.0" ];
    forwardAddresses = [
      "1.1.1.1@853#cloudflare-dns.com"
      "1.0.0.1@853#cloudflare-dns.com"
    ];
    extraConfig = ''
      so-reuseport: yes
      tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt
      tls-upstream: yes
      include: ${blocklistPath}
    '';
  };
}