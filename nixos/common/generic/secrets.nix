{ ... }:
{
  users.groups.secrets.name = "secrets";
  systemd.tmpfiles.rules = [
    "d /var/secrets 750 root secrets"
    "z /var/secrets 750 root secrets"
  ];
}
