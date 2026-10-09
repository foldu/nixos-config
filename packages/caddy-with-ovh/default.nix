{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  stdenv,
  writableTmpDirAsHomeHook,
  versionCheckHook,
}:
buildGoModule (finalAttrs: {
  pname = "caddy-with-ovh";
  version = "2.11.4";

  # main.go is caddy's own cmd/caddy/main.go with the ovh DNS plugin imported;
  # caddy and the plugin are pinned by go.mod/go.sum. That pinning is the whole
  # point - see the comment at the top of main.go.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./go.sum
      ./main.go
    ];
  };

  vendorHash = "sha256-HNLZkHYav5ucJbmGVDP5JEKYckmKPCwmDdhw/TTECZ0=";

  # matches upstream since v2.8.0
  tags = [
    "nobadger"
    "nomysql"
    "nopgx"
  ];

  # The systemd units are load-bearing: the nixos caddy module does
  # `systemd.packages = [ cfg.package ]`, and AmbientCapabilities from the unit
  # is what lets caddy bind :80/:443 as the unprivileged caddy user. A build
  # that doesn't install them loses CAP_NET_BIND_SERVICE and every vhost.
  passthru.dist = fetchFromGitHub {
    owner = "caddyserver";
    repo = "dist";
    tag = "v${finalAttrs.version}";
    hash = "sha256-oRQfQH1GKjAjVMj+dZo1f1+HOaOdJIyEfod0iGLYcc8=";
  };

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  nativeCheckInputs = [ writableTmpDirAsHomeHook ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];

  postInstall = ''
    install -Dm644 ${finalAttrs.passthru.dist}/init/caddy.service ${finalAttrs.passthru.dist}/init/caddy-api.service -t $out/lib/systemd/system

    substituteInPlace $out/lib/systemd/system/caddy.service \
      --replace-fail "/usr/bin/caddy" "$out/bin/caddy"
    substituteInPlace $out/lib/systemd/system/caddy-api.service \
      --replace-fail "/usr/bin/caddy" "$out/bin/caddy"
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    $out/bin/caddy manpage --directory manpages
    installManPage manpages/*

    installShellCompletion --cmd caddy \
      --bash <($out/bin/caddy completion bash) \
      --fish <($out/bin/caddy completion fish) \
      --zsh <($out/bin/caddy completion zsh)
  '';

  meta = {
    homepage = "https://caddyserver.com";
    description = "Caddy built with the caddy-dns/ovh plugin, pinned by go.mod/go.sum so the hash only moves on a deliberate bump";
    changelog = "https://github.com/caddyserver/caddy/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "caddy";
  };
})
