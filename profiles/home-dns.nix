{ config, lib, pkgs, home-network, ... }:
let
  blocklistPath = "/var/lib/unbound/blocklist.conf";
in
{
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  networking.resolvconf.useLocalResolver = false;
  services.resolved.enable = false;

  systemd =
    let
      blocklist = pkgs.writeText "blocklist" (
        builtins.toJSON {
          host_whitelist = [];
          host_blacklist = [
            # mostly telemetry
            "incoming.telemetry.mozilla.org"
            "Iphone-id.apple.com"
            "Iphone-ld.apple.com"
            "albert.apple.com"
            "app-measurement.com"
            "bag.itunes.apple.com"
            "cf.iadsdk.apple.com"
            "growth-pa.googleapis.com"
            "iadsdk.apple.com"
            "idiagnostics.apple.com"
            "init.gc.apple.com"
            "iphone-ld.apple.com"
            "mobilenetworkscoring-pa.googleapis.com"
            "pagead2.googlesyndication.com"
            "pdate.googleapis.com"
            "profile.gc.apple.com"
            "sa.apple.com"
            "smp-device-content.apple.com"
            "ssl.google-analytics.com"
            "ssl.google−analytics.com"
            "static.gc.apple.com"
            "www.googleadservices.com"
          ];
          blocklists = [
            # needs more blocklists
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://raw.githubusercontent.com/imkarthikk/pihole-facebook/master/pihole-facebook.txt"
            "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
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
            #"https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/extra.txt"
            #"https://raw.githubusercontent.com/jmdugan/blocklists/master/corporations/microsoft/all"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/shortlinksparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/proxiesparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/productsparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/mailparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/generalparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/fontsparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/firebaseparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/doubleclickparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/domainsparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/dnsparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/androidparsed"
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/analyticsparsed"

            # new

            # "suspicious"
            "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
            "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
            "https://v.firebog.net/hosts/static/w3kbl.txt"

            # nextdns privacy native
            "https://raw.githubusercontent.com/nextdns/metadata/master/privacy/native/alexa"
            "https://raw.githubusercontent.com/nextdns/metadata/master/privacy/native/apple"
            "https://raw.githubusercontent.com/nextdns/metadata/master/privacy/native/huawei"
            "https://raw.githubusercontent.com/nextdns/metadata/master/privacy/native/roku"
            "https://raw.githubusercontent.com/nextdns/metadata/master/privacy/native/samsung"
            "https://raw.githubusercontent.com/nextdns/metadata/master/privacy/native/sonos"
            "https://raw.githubusercontent.com/nextdns/metadata/master/privacy/native/windows"
            "https://raw.githubusercontent.com/nextdns/metadata/master/privacy/native/xiaomi"

            "https://someonewhocares.org/hosts/hosts"

            # some google stuff that hopefully doesn't break too much
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/doubleclickparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/domainsparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/dnsparsed"
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
          after = [ "network.target" ];
          serviceConfig = {
            Type = "oneshot";
          };
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
    settings = {
      server = {
        access-control = [
          "127.0.0.0/8 allow"
          "${home-network.network} allow"
        ];
        interface = [ "0.0.0.0" ];
        so-reuseport = true;
        tls-upstream = true;
        tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
        include = "${blocklistPath}";
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
          ];
        }
      ];
    };
  };
}
