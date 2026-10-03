# llm-agents' dsh boots its app through the `node-addon-require-builtin`
# native addon, which does not survive the nix build. The wrapper already
# passes `--expose-internals`, so route the builtin requires through node's
# own createRequire instead.
{ dsh }:
dsh.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
          substituteInPlace \
            $out/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js \
            --replace-fail \
          'createRequire(import.meta.url)("node-addon-require-builtin")' \
    '{ requireBuiltin: createRequire(import.meta.url) }'
  '';
})
