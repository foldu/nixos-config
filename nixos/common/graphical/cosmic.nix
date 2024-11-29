{ pkgs, ... }:
{
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  environment.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";

  environment.systemPackages = [ pkgs.gcr_4 ];

  systemd.user = {
    sockets.gcr-ssh-agent = {
      description = "GCR SSH Agent Socket";
      socketConfig = {
        ListenStream = "%t/gcr/ssh";
        DirectoryMode = "0700";
      };
      wantedBy = [ "sockets.target" ];
    };
    services.gcr-ssh-agent = {
      description = "GCR SSH Agent";
      requires = [ "gcr-ssh-agent.socket" ];
      after = [ "gcr-ssh-agent.socket" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gcr_4}/libexec/gcr-ssh-agent --base-dir %t/gcr";
        StandardError = "journal";
      };
    };
  };
}
