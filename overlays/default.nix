final: prev: {
  gnomeExtensions = prev.gnomeExtensions;
  domitian = prev.callPackage ../packages/domitian { };
  catclock = prev.callPackage ../packages/catclock { };
  netmaker-netclient = prev.callPackage ../packages/netmaker-netclient { };
}
