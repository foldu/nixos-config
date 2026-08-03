{ ... }:
{
  services.udev.extraRules = ''
    # Keychron Keyboard udev rule for VIA / Keychron Launcher
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0e80", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"

    # stm32 keychron firmware update mode
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", GROUP="users", MODE="0660", TAG+="uaccess"
  '';
}
