final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    blur-my-shell = prev.callPackage ../packages/blur-my-shell {};
    just-perfection = prev.callPackage ../packages/just-perfection {};
    pop-os-shell = prev.callPackage ../packages/pop-os-shell {};
    gnome-ui-tune = prev.callPackage ../packages/gnome-ui-tune {};
  };
  #pop-gtk-theme = prev.callPackage ../packages/pop-gtk-theme {};
}
