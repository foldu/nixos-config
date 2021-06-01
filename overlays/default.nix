final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    pop-os-shell = prev.callPackage ../packages/pop-os-shell {};
    gnome-ui-tune = prev.callPackage ../packages/gnome-ui-tune {};
  };
  #pop-gtk-theme = prev.callPackage ../packages/pop-gtk-theme {};
}
