final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    blur-my-shell = prev.callPackage ../packages/blur-my-shell {};
    just-perfection = prev.callPackage ../packages/just-perfection {};
    pop-os-shell = prev.callPackage ../packages/pop-os-shell {};
  };
  pop-gtk-theme = prev.callPackage ../packages/pop-gtk-theme {};
}
