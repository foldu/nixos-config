{
  writeShellApplication,
  glab,
  gh,
  jq,
  git,
  coreutils,
}:
writeShellApplication {
  name = "gitlab-mirror";
  runtimeInputs = [
    glab
    gh
    jq
    git
    coreutils
  ];
  text = builtins.readFile ./gitlab-mirror.sh;
  meta = {
    description = "Manage GitLab push mirrors through glab and gh";
    mainProgram = "gitlab-mirror";
  };
}
