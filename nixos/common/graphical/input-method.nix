{ pkgs, ... }:
{
  # fcitx5 covers both sessions: it starts from its XDG autostart file, which
  # niri.service pulls in through xdg-desktop-autostart.target and the GNOME
  # session runs itself. waylandFrontend stays off on purpose so the module
  # keeps setting GTK_IM_MODULE/QT_IM_MODULE=fcitx: GTK3 has no text-input-v3
  # support at all, so leaving them unset would kill the IME in GTK3 apps. The
  # Wayland frontend still picks up text-input-v3 clients (Chromium, Electron,
  # ghostty) under niri on its own.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      addons = [
        # Simplified Chinese: Pinyin, plus shuangpin/wubi/etc. from the same addon.
        pkgs.qt6Packages.fcitx5-chinese-addons
        # Japanese. Mozc is the better engine, but the mozc 2.30.5544.102 in
        # this nixpkgs pin fails to build against Qt 6.12 (uic rejects the class
        # names in gui/dictionary_tool); nixpkgs master has mozc 3.x. Swap this
        # line for pkgs.fcitx5-mozc once flake.lock catches up.
        pkgs.fcitx5-anthy
      ];

      # Seeds /etc/xdg/fcitx5/profile so the engines are there without a detour
      # through fcitx5-configtool first. Ctrl+Space toggles the IME; keeping
      # Ctrl held and tapping Space again cycles pinyin/anthy. A user-level
      # ~/.config/fcitx5/profile still wins once you edit anything.
      settings.inputMethod = {
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "pinyin";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "pinyin";
        "Groups/0/Items/2".Name = "anthy";
        GroupOrder."0" = "Default";
      };
    };
  };
}
