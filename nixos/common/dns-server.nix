{ pkgs, inputs, ... }:
let
  blocklistDir = "/var/lib/blocklistdownloadthing";
  blocklistPath = "${blocklistDir}/hosts.blocklist";
  blocklistdownloadthing = "${inputs.nix-stuff.packages."${pkgs.system}".blocklistdownloadthing}/bin/blocklistdownloadthing";
in
{
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  services.resolved.enable = false;

  systemd =
    let
      blocklist = pkgs.writeText "blocklist" (
        builtins.toJSON {
          host_whitelist = [ ];
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
            # NOTE: duplicates don't matter, blocklistdownloadthing dedups automatically

            # needs more blocklists
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://raw.githubusercontent.com/imkarthikk/pihole-facebook/master/pihole-facebook.txt"
            "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
            "https://adaway.org/hosts.txt"
            "https://v.firebog.net/hosts/AdguardDNS.txt"
            "https://v.firebog.net/hosts/Easylist.txt"
            "https://v.firebog.net/hosts/Easyprivacy.txt"
            "https://v.firebog.net/hosts/Prigent-Ads.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
            "https://raw.githubusercontent.com/jmdugan/blocklists/master/corporations/pinterest/all"
            "https://raw.githubusercontent.com/jmdugan/blocklists/master/corporations/facebook/all"

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

            # some google stuff that hopefully doesn't break too much
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/doubleclickparsed"
            # too much usefull things get blocked from this
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/domainsparsed"
            # blocks www.gstatic.com for some reason
            #"https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/dnsparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/analyticsparsed"

            # tracking & telemetry https://firebog.net/
            "https://v.firebog.net/hosts/Easyprivacy.txt"
            "https://v.firebog.net/hosts/Prigent-Ads.txt"
            "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
            "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
            "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
            "https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt"
          ];
        }
      );
      cacheDir = "/var/cache/blocklists";
      user = "blocklist";
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
          ${blocklistdownloadthing} \
              -o ${blocklistPath} \
              --cache "${cacheDir}" \
              --format hosts \
              --config "${blocklist}"
        '';
      };
      tmpfiles.rules = [
        "d ${cacheDir} 755 ${user}"
        "Z ${cacheDir} 755 ${user}"
        "d ${blocklistDir} 755 ${user}"
        "Z ${blocklistDir} 755 ${user}"
      ];
    };

  users.users.blocklist = {
    group = "blocklist";
    isSystemUser = true;
  };

  users.groups.blocklist = { };

  services.coredns = {
    enable = true;
    config = ''
      (global) {
        log
        errors
        cache
      }

      home.5kw.li:53 {
        import global
        forward . 10.20.30.3
      }

      .:53 {
        import global
        hosts ${blocklistPath} {
          fallthrough
        }
        forward . tls://1.1.1.1 tls://1.0.0.1 {
          tls_servername cloudflare-dns.com
        }
      }
    '';
  };
}
