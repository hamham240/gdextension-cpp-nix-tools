{
  description = "Nix tooling for gdextension in C++";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        godotCppSrc = pkgs.fetchFromGitHub {
          owner = "godotengine";
          repo = "godot-cpp";
          tag = "godot-4.4.1-stable";
          sha256 = "sha256-DW8OWbiA409qAyOkzxEYiPPRa5cH2TutIR7OuC3ZRgc=";
        };
      in
      rec {
        # A patched godot-cpp that is compatible with nix builds
        packages.godot-cpp-src-patched = pkgs.stdenv.mkDerivation {
          pname = "godot-cpp-src-patched";
          version = "4.4.1";
          src = godotCppSrc;
          patches = [ ./godot-cpp.patch ];
          phases = [ "unpackPhase" "patchPhase" "installPhase" ];
          installPhase = ''
            mkdir -p $out
            cp -r . $out
          '';
        };

        packages.godot-cpp = pkgs.stdenv.mkDerivation {
          pname = "godot-cpp";
          version = "4.4.1";
          src = godotCppSrc;
          buildInputs = with pkgs; [ scons ];
          buildPhase = ''
            scons
          '';
          installPhase = ''
            mkdir -p $out/lib
            cp -r ./bin/* $out/lib
            cp -r ./include $out
            cp -r ./gen $out
            cp -r ./gdextension $out
          '';
        };

        # A devshell that offers a build ecosystem for gdextension plugins with nix
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ scons ];
          shellHook = ''
            export GODOT_CPP_SRC=${packages.godot-cpp-src-patched}
            export PYTHONPATH=${packages.godot-cpp-src-patched}:$PYTHONPATH
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
