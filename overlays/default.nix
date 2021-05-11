final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    blur-my-shell = prev.callPackage ../packages/blur-my-shell {};
  };
  myGnomeExtensions.pop-os-shell = prev.callPackage ../packages/pop-os-shell {};
  pop-gtk-theme = prev.callPackage ../packages/pop-gtk-theme {};
}
