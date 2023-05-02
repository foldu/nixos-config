final: prev: {
  gnomeExtensions = prev.gnomeExtensions // {
    gnome-ui-tune = prev.callPackage ../packages/gnome-ui-tune { };
  };
  domitian = prev.callPackage ../packages/domitian { };
  catclock = prev.callPackage ../packages/catclock { };
}
