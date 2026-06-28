# nix/tui.nix — Hermes TUI (Ink/React) compiled with tsc and bundled
{ pkgs, hermesNpmLib, ... }:
let
  src = ../ui-tui;
  npmDeps = pkgs.fetchNpmDeps {
    inherit src;
    # Fetcher v2 includes packument metadata needed by workspace/native-bin
    # dependencies such as esbuild; v1 produced a hash-consistent cache that
    # still missed esbuild during offline npm ci.
    hash = "sha256-c/KKcmGC2bnPZHzSHJktXVJxVlgByA4rqnlM1A0eKjI=";
    fetcherVersion = 2;
  };

  npm = hermesNpmLib.mkNpmPassthru { folder = "ui-tui"; attr = "tui"; pname = "hermes-tui"; };

  packageJson = builtins.fromJSON (builtins.readFile (src + "/package.json"));
  version = packageJson.version;
in
pkgs.buildNpmPackage (npm // {
  pname = "hermes-tui";
  inherit src npmDeps version;

  doCheck = false;
  npmDepsFetcherVersion = 2;
  npmFlags = [ "--legacy-peer-deps" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/hermes-tui

    # Single self-contained bundle built by scripts/build.mjs (esbuild).
    cp -r dist $out/lib/hermes-tui/dist

    # package.json kept for "type": "module" resolution on `node dist/entry.js`.
    cp package.json $out/lib/hermes-tui/

    runHook postInstall
  '';
})
