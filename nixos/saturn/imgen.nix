{ ... }:
{

  services.caddy.extraConfig = ''
    noodles.home.5kw.li {
      reverse_proxy 127.0.0.1:8188
    }

    imgen.home.5kw.li {
      reverse_proxy 127.0.0.1:7801
    }
  '';
}
