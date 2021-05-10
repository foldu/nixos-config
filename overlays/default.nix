final: prev: {
  myGnomeExtensions.pop-os-shell = prev.callPackage ../packages/pop-os-shell {};
  pop-gtk-theme = prev.callPackage ../packages/pop-gtk-theme {};
}
