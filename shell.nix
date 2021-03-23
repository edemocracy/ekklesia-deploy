{ sources ? null }:
with builtins;

let
  sources_ = if (sources == null) then import ./nix/sources.nix else sources;
  inherit (sources_) nixpkgs;
  niv = (import sources_.niv { }).niv;
  vvvoteShellInputs = (import "${sources_.nix-ekklesia-vvvote}/nix/deps.nix" { inherit sources; }).shellTools;
  portalShellInputs = (import "${sources_.ekklesia-portal}/nix/deps.nix" { inherit sources; }).shellTools;
  pkgs = import nixpkgs { config = {}; };
  python = pkgs.python39.withPackages (ps: with ps; [ ]);

in

pkgs.mkShell {

  buildInputs = [ pkgs.nixops niv python ] ++ vvvoteShellInputs;

  shellHook = ''
    export NIX_PATH="nixpkgs=${nixpkgs}:."
  '';

}
