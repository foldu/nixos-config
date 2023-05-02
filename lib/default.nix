{ lib, ... }: {
  btrfsSubvolOn = device: mountOptions: name: {
    inherit device;
    fsType = "btrfs";
    options = [ "subvol=${name}" ] ++ mountOptions;
  };
}
