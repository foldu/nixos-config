{ pkgs, ... }:
let
  hosts = ''
    100.64.0.3 git.home.5kw.li
    100.64.0.3 ca.home.5kw.li
    100.64.0.3 prometheus.home.5kw.li
  '';
  bootstrapHosts = pkgs.writeTextFile {
    name = "bootstraphosts.txt";
    text = ''
      100.64.0.3 git.home.5kw.li
      100.64.0.3 ca.home.5kw.li
      100.64.0.3 prometheus.home.5kw.li
    '';
  };
in
{

  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  services.resolved.enable = false;

  networking.extraHosts = hosts;

  services.blocky = {
    enable = true;
    settings = {
      upstreams.groups.default = [
        "tcp-tls:1.1.1.1:853"
        "tcp-tls:1.0.0.1:853"
      ];
      bootstrapDns = [ { upstream = "tcp-tls:1.1.1.1:853"; } ];

      hostsFile = {
        sources = [
          "${bootstrapHosts}"
          "https://git.home.5kw.li/foldu/hosts/raw/branch/master/tailscale.txt"
        ];
        loading = {
          refreshPeriod = "5m";
          downloads = {
            timeout = "10s";
            attempts = 2;
            cooldown = "10s";
          };
        };
      };
      queryLog.type = "none";
      blocking = {
        loading.downloads = {
          timeout = "30s";
        };
        blackLists = {
          telemetry_and_tracking = [
            "https://git.home.5kw.li/foldu/hosts/raw/branch/master/telemetry.txt"
            "https://v.firebog.net/hosts/Easyprivacy.txt"
            "https://v.firebog.net/hosts/Prigent-Ads.txt"
            "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
            "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
            "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
            "https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
            "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt"
            "https://raw.githubusercontent.com/nextdns/native-tracking-domains/master/domains/alexa"
            "https://raw.githubusercontent.com/nextdns/native-tracking-domains/master/domains/apple"
            "https://raw.githubusercontent.com/nextdns/native-tracking-domains/master/domains/huawei"
            "https://raw.githubusercontent.com/nextdns/native-tracking-domains/master/domains/roku"
            "https://raw.githubusercontent.com/nextdns/native-tracking-domains/master/domains/samsung"
            "https://raw.githubusercontent.com/nextdns/native-tracking-domains/master/domains/sonos"
            "https://raw.githubusercontent.com/nextdns/native-tracking-domains/master/domains/windows"
            "https://raw.githubusercontent.com/nextdns/native-tracking-domains/master/domains/xiaomi"
            "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/analyticsparsed"
            "https://raw.githubusercontent.com/nickspaargaren/pihole-google/master/categories/doubleclickparsed"
          ];
          ads = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://adaway.org/hosts.txt"
            "https://v.firebog.net/hosts/AdguardDNS.txt"
            "https://v.firebog.net/hosts/Easylist.txt"
            "https://v.firebog.net/hosts/Easyprivacy.txt"
            "https://v.firebog.net/hosts/Prigent-Ads.txt"
          ];
          shit_companies = [
            "https://raw.githubusercontent.com/jmdugan/blocklists/master/corporations/pinterest/all"
            "https://raw.githubusercontent.com/jmdugan/blocklists/master/corporations/facebook/all"
            "https://raw.githubusercontent.com/imkarthikk/pihole-facebook/master/pihole-facebook.txt"
          ];
        };
        clientGroupsBlock.default = [
          "ads"
          "telemetry_and_tracking"
          "shit_companies"
        ];
      };
      ports = {
        dns = 53;
      };
    };
  };
}
