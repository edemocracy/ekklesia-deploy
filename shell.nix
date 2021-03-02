{ sources ? null }:
with builtins;

let
  sources_ = if (sources == null) then import ./nix/sources.nix else sources;
  inherit (sources_) nixpkgs;
  niv = (import sources_.niv { }).niv;
  vvvoteShellInputs = (import "${sources_.nix-ekklesia-vvvote}/nix/deps.nix" { inherit sources; }).shellInputs;
  pkgs = import nixpkgs { config = {}; };

in

pkgs.mkShell {

  buildInputs = [ pkgs.nixops niv ] ++ vvvoteShellInputs;

  shellHook = ''
    export NIX_PATH="nixpkgs=${nixpkgs}:."
  '';

}
