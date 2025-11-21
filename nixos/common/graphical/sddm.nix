{ pkgs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
  };

  environment.systemPackages = with pkgs; [
    (pkgs.sddm-astronaut.override {
      embeddedTheme = "jake_the_dog";
      themeConfig = {
        FormPosition = "left"; # left, center, right
        Background = "${./ayy_lmao.jpg}";
        HaveFormBackground = "false";
        PartialBlur = "";
        Blur = "";
        BlurMax = "";
        Font = "Inter";
      };
    })
    kdePackages.qtsvg
    kdePackages.qtvirtualkeyboard
    kdePackages.qtmultimedia
  ];
}
