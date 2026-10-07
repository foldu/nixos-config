{
  writeShellApplication,
  curl,
  jq,
  git,
  gawk,
  coreutils,
}:
writeShellApplication {
  name = "gitlab-mirror";
  runtimeInputs = [
    curl
    jq
    git
    gawk
    coreutils
  ];
  text = builtins.readFile ./gitlab-mirror.sh;
  meta = {
    description = "Manage GitLab push mirrors over the remote-mirrors API";
    mainProgram = "gitlab-mirror";
  };
}
