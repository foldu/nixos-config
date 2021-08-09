final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    pop-os-shell = prev.callPackage ../packages/pop-os-shell { };
    gnome-ui-tune = prev.callPackage ../packages/gnome-ui-tune { };
  };
  domitian = prev.callPackage ../packages/domitian { };
  sumneko-lua-language-server = prev.callPackage ../packages/sumneko-language-server { };
  #pop-gtk-theme = prev.callPackage ../packages/pop-gtk-theme {};
}
